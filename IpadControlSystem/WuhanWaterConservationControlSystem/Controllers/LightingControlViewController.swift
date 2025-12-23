//
//  LightingControlViewController.swift
//  WuhanWaterConservationControlSystem
//
//  Created by SOLO Builder on 2025/12/23.
//  Copyright © 2025 WuhanWaterConservation. All rights reserved.
//

import UIKit
import QuartzCore

class LightingControlViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let tableView = UITableView()
    private let allOnButton = UIButton(type: .system)
    private let hexPanelStackView = UIStackView()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private var switchItems: [(title: String, onHex: String, offHex: String)] = [
        ("筒灯1", "FB 00 A0 00 00 01 0A F4 06 CF FA 01 F1 C1 E1 DF", "FB 00 A0 00 00 01 0A F4 06 CF FA 01 F1 C1 F0 DF"),
        ("筒灯2", "FB 00 A0 00 00 01 0A F4 06 CF FA 01 F1 C2 E1 DF", "FB 00 A0 00 00 01 0A F4 06 CF FA 01 F1 C2 F0 DF"),
        ("轨道灯1", "FB 00 A0 00 00 01 0A F4 06 CF FA 01 F1 C3 E1 DF", "FB 00 A0 00 00 01 0A F4 06 CF FA 01 F1 C3 F0 DF"),
        ("轨道灯2", "FB 00 A0 00 00 01 0A F4 06 CF FA 01 F1 C4 E1 DF", "FB 00 A0 00 00 01 0A F4 06 CF FA 01 F1 C4 F0 DF"),
        ("轨道灯3", "FB 00 A0 00 00 01 0A F4 06 CF FA 01 F1 C5 E1 DF", "FB 00 A0 00 00 01 0A F4 06 CF FA 01 F1 C5 F0 DF"),
        ("轨道灯4", "FB 00 A0 00 00 01 0A F4 06 CF FA 01 F1 C6 E1 DF", "FB 00 A0 00 00 01 0A F4 06 CF FA 01 F1 C6 F0 DF"),
        ("灯槽", "FB 00 A0 00 00 01 0A F4 06 CF FA 01 F1 C7 E1 DF", "FB 00 A0 00 00 01 0A F4 06 CF FA 01 F1 C7 F0 DF"),
        ("生命水", "FB 00 A0 00 00 01 0A F4 06 CF FA 01 F1 C8 E1 DF", "FB 00 A0 00 00 01 0A F4 06 CF FA 01 F1 C8 F0 DF")
    ]
    private var switches: [UISwitch] = []
    private var tiles: [LightTileView] = []
    private var currentColumns: Int = 2
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .landscape }
    override var shouldAutorotate: Bool { false }
    
    private struct CustomLightDevice: Codable {
        let name: String
        let onHex: String
        let offHex: String
        let icon: String
    }
    private var customDevicesByGroup: [String: [CustomLightDevice]] = [:]
    private var collapseStates: [String: Bool] = [:]
    private let customDevicesKey = "lighting_custom_devices"
    private let collapseStatesKey = "lighting_collapsed_states"
    private let tileStatesKey = "lighting_tile_states"
    private var tileStates: [String: Bool] = [:]
    private let deletedPresetTitlesKey = "lighting_deleted_preset_titles"
    private let deletedPresetGroupsKey = "lighting_deleted_preset_groups"
    private var deletedPresetTitles: Set<String> = []
    private var deletedPresetGroups: Set<String> = []
    private var deleteLocks: Set<String> = []
    private let deleteLockInterval: TimeInterval = 0.8
    private var pendingNewGroupName: String?
    private var pendingIconSymbol: String?
    
    // MARK: - Properties
    
    private var lightingDevices: [Device] = []
    private var isLoading = false
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadLightingDevices()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshDeviceStatus()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        title = "灯光一键全开/全关"
        view.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
        
        setupNavigationBar()
        setupScrollContainer()
        setupTableView()
        setupHexPanel()
        setupConstraints()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let cols = computedColumns()
        if cols != currentColumns {
            currentColumns = cols
            clearStackView(hexPanelStackView)
            setupHexPanel()
        }
    }
    
    private func setupNavigationBar() {
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = false
        }
        
        let backButton = UIBarButtonItem(title: "返回", style: .plain, target: self, action: #selector(backButtonTapped))
        navigationItem.leftBarButtonItem = backButton
        
        if let navBar = navigationController?.navigationBar {
            navBar.setBackgroundImage(UIImage(), for: .default)
            navBar.shadowImage = UIImage()
            navBar.isTranslucent = true
            navBar.barTintColor = .white
            navBar.tintColor = UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0)
            navBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        }
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonTapped))
        navigationItem.rightBarButtonItem = addButton
    }
    
    private func setupScrollContainer() {
        scrollView.backgroundColor = .clear
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.backgroundColor = .clear
        contentView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.register(LightingDeviceCell.self, forCellReuseIdentifier: "LightingDeviceCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(tableView)
    }
    
    private func setupAllOnButton() {
        allOnButton.setTitle("全部开启", for: .normal)
        allOnButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        allOnButton.backgroundColor = UIColor(red: 52.0/255.0, green: 199.0/255.0, blue: 89.0/255.0, alpha: 1.0)
        allOnButton.setTitleColor(.white, for: .normal)
        allOnButton.layer.cornerRadius = 12
        allOnButton.layer.shadowColor = UIColor.black.cgColor
        allOnButton.layer.shadowOpacity = 0.2
        allOnButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        allOnButton.layer.shadowRadius = 4
        allOnButton.addTarget(self, action: #selector(allOnButtonTapped), for: .touchUpInside)
        allOnButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(allOnButton)
    }
    
    // 顶部状态文字已删除
    
    private func setupHexPanel() {
        hexPanelStackView.axis = .vertical
        hexPanelStackView.distribution = .fill
        hexPanelStackView.spacing = 16
        hexPanelStackView.alignment = .fill
        hexPanelStackView.isLayoutMarginsRelativeArrangement = true
        hexPanelStackView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        hexPanelStackView.translatesAutoresizingMaskIntoConstraints = false
        tiles.removeAll()
        switches.removeAll()
        customDevicesByGroup = loadCustomDevices()
        collapseStates = loadCollapseStates()
        tileStates = loadTileStates()
        loadDeletedPresets()
        
        let presetOrder = ["筒灯", "轨道灯", "灯槽", "生命水"]
        var presetGroups: [String: [Int]] = [:]
        for (idx, item) in switchItems.enumerated() {
            let name = groupName(for: item.title)
            if !deletedPresetTitles.contains(item.title) {
                presetGroups[name, default: []].append(idx)
            }
        }
        var orderedGroupNames: [String] = []
        for g in presetOrder {
            if (presetGroups[g] != nil || customDevicesByGroup[g] != nil) && !deletedPresetGroups.contains(g) {
                orderedGroupNames.append(g)
            }
        }
        for g in customDevicesByGroup.keys where !deletedPresetGroups.contains(g) {
            if !orderedGroupNames.contains(g) { orderedGroupNames.append(g) }
        }
        
        for name in orderedGroupNames {
            let section = CollapsibleSectionView(title: name, icon: iconForItem(name))
            let initialCollapsed = collapseStates[name] ?? false
            section.setCollapsed(initialCollapsed, animated: false)
            section.onCollapseChanged = { [weak self] collapsed in
                self?.saveCollapseState(for: name, collapsed: collapsed)
                self?.updateContainerSpacing(animated: true)
            }
            section.onDeleteGroupRequested = { [weak self] in
                self?.confirmDeleteGroup(name: name)
            }
            hexPanelStackView.addArrangedSubview(section)
            
            var rowStack: UIStackView?
            var i = 0
            struct TileData { let title: String; let onHex: String; let offHex: String; let iconName: String? }
            var combined: [TileData] = []
            if let indices = presetGroups[name] {
                for index in indices {
                    let item = switchItems[index]
                    combined.append(TileData(title: item.title, onHex: item.onHex, offHex: item.offHex, iconName: nil))
                }
            }
            if let customs = customDevicesByGroup[name] {
                for c in customs {
                    combined.append(TileData(title: c.name, onHex: c.onHex, offHex: c.offHex, iconName: c.icon))
                }
            }
            for tileData in combined {
                if i % currentColumns == 0 {
                    rowStack = UIStackView()
                    rowStack?.axis = .horizontal
                    rowStack?.distribution = .fillEqually
                    rowStack?.alignment = .fill
                    rowStack?.spacing = 16
                    rowStack?.translatesAutoresizingMaskIntoConstraints = false
                    if let r = rowStack { section.contentStack.addArrangedSubview(r) }
                }
                let tile = LightTileView()
                tile.title = tileData.title
                if #available(iOS 13.0, *) {
                    if let s = tileData.iconName {
                        tile.icon = UIImage(systemName: s)
                    } else {
                        tile.icon = iconForItem(tileData.title)
                    }
                } else {
                    tile.icon = createRowFallbackIcon(for: tileData.title)
                }
                let initialOn = tileStates[tileData.title] ?? false
                tile.setOn(initialOn, animated: false)
                tile.onChanged = { [weak self] isOn in
                    guard let self = self else { return }
                    guard TCPConnectionManager.shared.isConnected else {
                        tile.setOn(!isOn, animated: true)
                        self.showAlert(title: "错误", message: "未连接到服务器")
                        return
                    }
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    let cmd = isOn ? tileData.onHex : tileData.offHex
                    TCPConnectionManager.shared.sendHexCommand(cmd) { success, error in
                        DispatchQueue.main.async {
                            if success {
                                self.saveTileState(title: tileData.title, isOn: isOn)
                                DeviceManager.shared.refreshDeviceStatus { _ in
                                    DispatchQueue.main.async {
                                        self.lightingDevices = DeviceManager.shared.getDevices(byType: .lighting)
                                        self.tableView.reloadData()
                                    }
                                }
                            } else {
                                tile.setOn(!isOn, animated: true)
                                let msg = error?.localizedDescription ?? "未知错误"
                                self.showAlert(title: "发送失败", message: msg)
                            }
                        }
                    }
                }
                tile.onDeleteRequested = { [weak self] in
                    self?.confirmDeleteDevice(inGroup: name, title: tileData.title)
                }
                rowStack?.addArrangedSubview(tile)
                tiles.append(tile)
                i += 1
            }
        }
        contentView.addSubview(hexPanelStackView)
    }
    
    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 11.0, *) {
            view.addSubview(scrollView)
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        } else {
            view.addSubview(scrollView)
            scrollView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
            scrollView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor).isActive = true
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        }
        
        scrollView.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            hexPanelStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            hexPanelStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
        
        tableView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20).isActive = true
        hexPanelStackView.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 20).isActive = true
        contentView.bottomAnchor.constraint(equalTo: hexPanelStackView.bottomAnchor, constant: 20).isActive = true
    }
    
    private func loadCustomDevices() -> [String: [CustomLightDevice]] {
        let ud = UserDefaults.standard
        guard let data = ud.data(forKey: customDevicesKey) else { return [:] }
        let decoder = JSONDecoder()
        if let dict = try? decoder.decode([String: [CustomLightDevice]].self, from: data) {
            return dict
        }
        return [:]
    }
    
    private func saveCustomDevices(_ dict: [String: [CustomLightDevice]]) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(dict) {
            UserDefaults.standard.set(data, forKey: customDevicesKey)
        }
    }
    
    private func loadCollapseStates() -> [String: Bool] {
        let ud = UserDefaults.standard
        if let data = ud.data(forKey: collapseStatesKey) {
            if let dict = try? JSONDecoder().decode([String: Bool].self, from: data) {
                return dict
            }
        }
        return [:]
    }
    
    private func saveCollapseState(for group: String, collapsed: Bool) {
        collapseStates[group] = collapsed
        if let data = try? JSONEncoder().encode(collapseStates) {
            UserDefaults.standard.set(data, forKey: collapseStatesKey)
        }
    }
    
    private func loadDeletedPresets() {
        let ud = UserDefaults.standard
        if let data = ud.data(forKey: deletedPresetTitlesKey),
           let arr = try? JSONDecoder().decode([String].self, from: data) {
            deletedPresetTitles = Set(arr)
        }
        if let dataG = ud.data(forKey: deletedPresetGroupsKey),
           let arrG = try? JSONDecoder().decode([String].self, from: dataG) {
            deletedPresetGroups = Set(arrG)
        }
    }
    private func saveDeletedPresets() {
        let ud = UserDefaults.standard
        if let data = try? JSONEncoder().encode(Array(deletedPresetTitles)) {
            ud.set(data, forKey: deletedPresetTitlesKey)
        }
        if let dataG = try? JSONEncoder().encode(Array(deletedPresetGroups)) {
            ud.set(dataG, forKey: deletedPresetGroupsKey)
        }
    }
    
    private func confirmDeleteDevice(inGroup group: String, title: String) {
        guard canProceedDelete(id: "device:\(group):\(title)") else { return }
        let alert = UIAlertController(title: "确认删除", message: "将永久删除该设备", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "删除", style: .destructive, handler: { _ in
            self.performDeleteDevice(inGroup: group, title: title)
        }))
        present(alert, animated: true)
    }
    private func performDeleteDevice(inGroup group: String, title: String) {
        if !TCPConnectionManager.shared.isConnected {
            showAlert(title: "错误", message: "网络中断，删除失败")
            return
        }
        logOperation("DELETE_DEVICE \(group) \(title)")
        TCPConnectionManager.shared.sendCommand("DELETE_DEVICE:\(group):\(title)")
        if var customs = customDevicesByGroup[group] {
            customs.removeAll { $0.name == title }
            customDevicesByGroup[group] = customs
            saveCustomDevices(customsByGroupSanitized(customDevicesByGroup))
        } else {
            deletedPresetTitles.insert(title)
            saveDeletedPresets()
        }
        clearStackView(hexPanelStackView)
        setupHexPanel()
    }
    
    private func confirmDeleteGroup(name: String) {
        guard canProceedDelete(id: "group:\(name)") else { return }
        let alert = UIAlertController(title: "确认删除", message: "将永久删除该分组及所有设备", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "删除", style: .destructive, handler: { _ in
            self.performDeleteGroup(name: name)
        }))
        present(alert, animated: true)
    }
    private func performDeleteGroup(name: String) {
        if !TCPConnectionManager.shared.isConnected {
            showAlert(title: "错误", message: "网络中断，删除失败")
            return
        }
        logOperation("DELETE_GROUP \(name)")
        TCPConnectionManager.shared.sendCommand("DELETE_GROUP:\(name)")
        customDevicesByGroup.removeValue(forKey: name)
        deletedPresetGroups.insert(name)
        if let presetIndices = switchItems.enumerated().filter({ groupName(for: $0.element.title) == name }).map({ $0.offset }) as [Int]? {
            for idx in presetIndices {
                deletedPresetTitles.insert(switchItems[idx].title)
            }
        }
        saveDeletedPresets()
        saveCustomDevices(customsByGroupSanitized(customDevicesByGroup))
        clearStackView(hexPanelStackView)
        setupHexPanel()
    }
    
    private func canProceedDelete(id: String) -> Bool {
        if deleteLocks.contains(id) { return false }
        deleteLocks.insert(id)
        DispatchQueue.main.asyncAfter(deadline: .now() + deleteLockInterval) { [weak self] in
            self?.deleteLocks.remove(id)
        }
        return true
    }
    
    private func logOperation(_ message: String) {
        let key = "operation_logs"
        let ts = Int(Date().timeIntervalSince1970)
        let entry = "[\(ts)] \(message)"
        let ud = UserDefaults.standard
        var logs: [String] = []
        if let data = ud.data(forKey: key), let arr = try? JSONDecoder().decode([String].self, from: data) {
            logs = arr
        }
        logs.append(entry)
        if let data = try? JSONEncoder().encode(logs) {
            ud.set(data, forKey: key)
        }
    }
    
    private func customsByGroupSanitized(_ dict: [String: [CustomLightDevice]]) -> [String: [CustomLightDevice]] {
        var out = dict
        for (k, v) in out {
            if v.isEmpty { out.removeValue(forKey: k) }
        }
        return out
    }
    
    private func loadTileStates() -> [String: Bool] {
        let ud = UserDefaults.standard
        if let data = ud.data(forKey: tileStatesKey) {
            if let dict = try? JSONDecoder().decode([String: Bool].self, from: data) {
                return dict
            }
        }
        return [:]
    }
    
    private func saveTileState(title: String, isOn: Bool) {
        tileStates[title] = isOn
        if let data = try? JSONEncoder().encode(tileStates) {
            UserDefaults.standard.set(data, forKey: tileStatesKey)
        }
    }
    
    @objc private func addButtonTapped() {
        presentGroupSelection()
    }
    
    private func presentGroupSelection() {
        let alert = UIAlertController(title: "选择分组", message: nil, preferredStyle: .alert)
        let groups = allGroupNames()
        for g in groups {
            alert.addAction(UIAlertAction(title: g, style: .default, handler: { _ in
                self.pendingNewGroupName = g
                self.presentIconSelector()
            }))
        }
        alert.addAction(UIAlertAction(title: "新建分组", style: .default, handler: { _ in
            self.presentNewGroupInput()
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
    
    private func presentNewGroupInput() {
        let alert = UIAlertController(title: "新建分组", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "分组名称"
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .default, handler: { _ in
            let name = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !name.isEmpty else { return }
            self.pendingNewGroupName = name
            self.presentIconSelector()
        }))
        present(alert, animated: true)
    }
    
    private func presentIconSelector() {
        let alert = UIAlertController(title: "选择图标", message: nil, preferredStyle: .alert)
        let icons: [(String, String)] = [("灯光", "lightbulb.fill"), ("水", "drop.fill"), ("投影", "video.fill"), ("电脑", "desktopcomputer"), ("电源", "power")]
        for (title, symbol) in icons {
            alert.addAction(UIAlertAction(title: title, style: .default, handler: { _ in
                self.pendingIconSymbol = symbol
                self.presentDeviceForm()
            }))
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
    
    private func presentDeviceForm() {
        let alert = UIAlertController(title: "新建设备", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "设备名称"
        }
        alert.addTextField { tf in
            tf.placeholder = "开启指令 HEX"
        }
        alert.addTextField { tf in
            tf.placeholder = "关闭指令 HEX"
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "创建", style: .default, handler: { _ in
            let name = alert.textFields?[0].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let onHex = alert.textFields?[1].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let offHex = alert.textFields?[2].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard let group = self.pendingNewGroupName, !name.isEmpty, !onHex.isEmpty, !offHex.isEmpty else { return }
            let icon = self.pendingIconSymbol ?? "lightbulb.fill"
            var dict = self.customDevicesByGroup
            var arr = dict[group] ?? []
            arr.append(CustomLightDevice(name: name, onHex: onHex, offHex: offHex, icon: icon))
            dict[group] = arr
            self.customDevicesByGroup = dict
            self.saveCustomDevices(dict)
            self.clearStackView(self.hexPanelStackView)
            self.setupHexPanel()
        }))
        present(alert, animated: true)
    }
    
    private func allGroupNames() -> [String] {
        var set = Set<String>()
        for item in switchItems {
            set.insert(groupName(for: item.title))
        }
        for k in customDevicesByGroup.keys { set.insert(k) }
        return Array(set)
    }
    
    
    
    private func groupName(for title: String) -> String {
        if title.hasPrefix("筒灯") { return "筒灯" }
        if title.hasPrefix("轨道灯") { return "轨道灯" }
        if title.contains("灯槽") { return "灯槽" }
        if title.contains("生命水") { return "生命水" }
        return "其他"
    }
    
    private func computedColumns() -> Int {
        let width = view.bounds.width
        if width > 1200 { return 3 }
        return 2
    }
    
    private func clearStackView(_ stack: UIStackView) {
        for v in stack.arrangedSubviews {
            stack.removeArrangedSubview(v)
            v.removeFromSuperview()
        }
    }
    
    private func updateContainerSpacing(animated: Bool) {
        let target = CGFloat(16)
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
                self.hexPanelStackView.spacing = target
                self.view.layoutIfNeeded()
            }
        } else {
            hexPanelStackView.spacing = target
        }
    }
    
    // MARK: - Data Loading
    
    private func loadLightingDevices() {
        isLoading = true
        
        // 获取所有灯光设备
        lightingDevices = DeviceManager.shared.getDevices(byType: .lighting)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isLoading = false
            self?.tableView.reloadData()
        }
    }
    
    private func refreshDeviceStatus() {
        DeviceManager.shared.refreshDeviceStatus { [weak self] success in
            if success {
                self?.lightingDevices = DeviceManager.shared.getDevices(byType: .lighting)
                self?.tableView.reloadData()
            }
        }
    }
    
    private func updateStatusLabel() {
        return
    }
    
    // MARK: - Button Actions
    
    @objc private func backButtonTapped() {
        if let nav = navigationController {
            if nav.viewControllers.first === self, presentingViewController != nil {
                dismiss(animated: true)
            } else {
                nav.popViewController(animated: true)
            }
        } else {
            dismiss(animated: true)
        }
    }
    
    @objc private func refreshButtonTapped() {
        refreshDeviceStatus()
    }
    
    @objc private func allOnButtonTapped() {
        guard !lightingDevices.isEmpty else {
            showAlert(title: "提示", message: "没有可控制的灯光设备")
            return
        }
        
        let alert = UIAlertController(title: "确认操作", message: "确定要开启所有灯光设备吗？", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            self?.turnOnAllLightingDevices()
        })
        
        present(alert, animated: true)
    }
    
    private func turnOnAllLightingDevices() {
        isLoading = true
        allOnButton.isEnabled = false
        allOnButton.setTitle("正在执行...", for: .normal)
        
        DeviceManager.shared.controlAllDevices(ofType: .lighting, action: .allOn) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.allOnButton.isEnabled = true
                self?.allOnButton.setTitle("全部开启", for: .normal)
                
                if success {
                    self?.showAlert(title: "成功", message: "所有灯光设备已开启")
                    self?.refreshDeviceStatus()
                } else {
                    let errorMessage = error?.localizedDescription ?? "未知错误"
                    self?.showAlert(title: "错误", message: "操作失败: \(errorMessage)")
                }
            }
        }
    }
    
    @objc private func switchToggled(_ sender: UISwitch) {
        let index = sender.tag
        guard index >= 0 && index < switchItems.count else { return }
        guard TCPConnectionManager.shared.isConnected else {
            sender.setOn(!sender.isOn, animated: true)
            showAlert(title: "错误", message: "未连接到服务器")
            return
        }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        if let row = sender.superview {
            animateRowPress(row)
            applyRowStyle(row, isOn: sender.isOn, animated: true)
        }
        let cmd = sender.isOn ? switchItems[index].onHex : switchItems[index].offHex
        TCPConnectionManager.shared.sendHexCommand(cmd) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    DeviceManager.shared.refreshDeviceStatus { _ in
                        DispatchQueue.main.async {
                            self?.lightingDevices = DeviceManager.shared.getDevices(byType: .lighting)
                            self?.tableView.reloadData()
                            self?.updateStatusLabel()
                        }
                    }
                } else {
                    sender.setOn(!sender.isOn, animated: true)
                    let msg = error?.localizedDescription ?? "未知错误"
                    self?.showAlert(title: "发送失败", message: msg)
                    if let row = sender.superview {
                        self?.applyRowStyle(row, isOn: sender.isOn, animated: true)
                    }
                }
            }
        }
    }
    
    @objc private func switchTouchDown(_ sender: UISwitch) {
        if let row = sender.superview {
            animateRowHover(row, hovering: true)
        }
    }
    
    @objc private func switchTouchUp(_ sender: UISwitch) {
        if let row = sender.superview {
            animateRowHover(row, hovering: false)
        }
    }
    
    private func iconForItem(_ title: String) -> UIImage? {
        if #available(iOS 13.0, *) {
            if title.contains("生命水") {
                return UIImage(systemName: "drop.fill")
            } else {
                return UIImage(systemName: "lightbulb.fill")
            }
        } else {
            return nil
        }
    }
    
    private func createRowFallbackIcon(for title: String) -> UIImage? {
        let size = CGSize(width: 22, height: 22)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        let color = title.contains("生命水") ?
            UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0) :
            UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0)
        context.setFillColor(color.cgColor)
        context.fillEllipse(in: CGRect(x: 1, y: 1, width: 20, height: 20))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    private func applyRowStyle(_ row: UIView, isOn: Bool, animated: Bool) {
        let onColor = UIColor(red: 52.0/255.0, green: 199.0/255.0, blue: 89.0/255.0, alpha: 0.08)
        let offColor = UIColor.white
        let shadowOn: Float = 0.16
        let shadowOff: Float = 0.12
        let animations = {
            row.backgroundColor = isOn ? onColor : offColor
            row.layer.shadowOpacity = isOn ? shadowOn : shadowOff
        }
        if animated {
            UIView.animate(withDuration: 0.18) {
                animations()
            }
        } else {
            animations()
        }
    }
    
    private func animateRowHover(_ row: UIView, hovering: Bool) {
        let scale: CGFloat = hovering ? 0.98 : 1.0
        UIView.animate(withDuration: 0.12) {
            row.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
    }
    
    private func animateRowPress(_ row: UIView) {
        UIView.animate(withDuration: 0.12, animations: {
            row.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        }) { _ in
            UIView.animate(withDuration: 0.18) {
                row.transform = .identity
            }
        }
    }
    
    private func toggleDevice(_ device: Device) {
        let action = device.isOn ? ControlAction.turnOff : ControlAction.turnOn
        
        DeviceManager.shared.controlDevice(device.id, action: action) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.refreshDeviceStatus()
                } else {
                    let errorMessage = error?.localizedDescription ?? "未知错误"
                    self?.showAlert(title: "错误", message: "操作失败: \(errorMessage)")
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension LightingControlViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lightingDevices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "LightingDeviceCell", for: indexPath) as? LightingDeviceCell else {
            return UITableViewCell()
        }
        
        let device = lightingDevices[indexPath.row]
        cell.configure(with: device)
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension LightingControlViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let device = lightingDevices[indexPath.row]
        toggleDevice(device)
    }
}

// MARK: - LightingDeviceCell

class LightingDeviceCell: UITableViewCell {
    
    // MARK: - UI Components
    
    private let iconImageView = UIImageView()
    private let nameLabel = UILabel()
    private let controlSwitch = UISwitch()
    private let statusIndicator = UIView()
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .white
        layer.cornerRadius = 8
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowRadius = 2
        
        setupIconImageView()
        setupLabels()
        setupSwitch()
        setupIndicator()
        setupConstraints()
    }
    
    private func setupIconImageView() {
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0)
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 13.0, *) {
            iconImageView.image = UIImage(systemName: "lightbulb.fill")
        } else {
            // iOS 10兼容性处理
            iconImageView.image = createFallbackIcon()
        }
        
        contentView.addSubview(iconImageView)
    }
    
    private func setupLabels() {
        nameLabel.font = UIFont.boldSystemFont(ofSize: 16)
        nameLabel.textColor = .darkText
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(nameLabel)
    }
    
    private func setupSwitch() {
        controlSwitch.onTintColor = UIColor(red: 52.0/255.0, green: 199.0/255.0, blue: 89.0/255.0, alpha: 1.0)
        controlSwitch.addTarget(self, action: #selector(switchValueChanged), for: .valueChanged)
        controlSwitch.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(controlSwitch)
    }
    
    private func setupIndicator() {
        statusIndicator.backgroundColor = .lightGray
        statusIndicator.layer.cornerRadius = 4
        statusIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(statusIndicator)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // 图标
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 32),
            iconImageView.heightAnchor.constraint(equalToConstant: 32),
            
            // 名称标签
            nameLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 16),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: controlSwitch.leadingAnchor, constant: -16),
            
            // 开关
            controlSwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            controlSwitch.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            // 状态指示器
            statusIndicator.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            statusIndicator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            statusIndicator.widthAnchor.constraint(equalToConstant: 8),
            statusIndicator.heightAnchor.constraint(equalToConstant: 8),
            
            // 内容视图高度
            contentView.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    // MARK: - Public Methods
    
    func configure(with device: Device) {
        nameLabel.text = device.name
        controlSwitch.isOn = device.isOn
        
        // 更新状态显示
        switch device.status {
        case .online:
            statusIndicator.backgroundColor = device.isOn ? 
                UIColor(red: 52.0/255.0, green: 199.0/255.0, blue: 89.0/255.0, alpha: 1.0) : 
                UIColor(red: 255.0/255.0, green: 59.0/255.0, blue: 48.0/255.0, alpha: 1.0)
        case .offline:
            statusIndicator.backgroundColor = .gray
        case .error:
            statusIndicator.backgroundColor = .red
        case .unknown:
            statusIndicator.backgroundColor = .lightGray
        }
        
        // 离线状态时禁用开关
        controlSwitch.isEnabled = device.status == .online
    }
    
    // MARK: - Private Methods
    
    private func createFallbackIcon() -> UIImage? {
        let size = CGSize(width: 32, height: 32)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        context.setFillColor(UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0).cgColor)
        context.setStrokeColor(UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0).cgColor)
        
        // 绘制灯泡形状
        let bulbRect = CGRect(x: 10, y: 6, width: 12, height: 16)
        context.fillEllipse(in: bulbRect)
        context.fill(CGRect(x: 8, y: 20, width: 16, height: 6))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    @objc private func switchValueChanged() {
        // 开关状态改变时通知父视图控制器
        // 这里可以通过代理或通知机制实现
    }
}

class LightTileView: UIControl {
    private let bgView = UIView()
    private let gradient = CAGradientLayer()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let statusDot = UIView()
    private let deleteButton = UIButton(type: .system)
    var onChanged: ((Bool) -> Void)?
    var onDeleteRequested: (() -> Void)?
    var title: String = "" { didSet { titleLabel.text = title } }
    var icon: UIImage? { didSet { iconView.image = icon } }
    private(set) var isOn: Bool = false
    private var isDeleteMode: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    private func setup() {
        layer.cornerRadius = 16
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.12
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 10
        
        gradient.colors = [
            UIColor(white: 1.0, alpha: 1.0).cgColor,
            UIColor(white: 0.98, alpha: 1.0).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        bgView.layer.insertSublayer(gradient, at: 0)
        bgView.layer.cornerRadius = 16
        bgView.clipsToBounds = true
        bgView.isUserInteractionEnabled = false
        bgView.translatesAutoresizingMaskIntoConstraints = false
        
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .darkText
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.85
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        statusDot.backgroundColor = UIColor.lightGray
        statusDot.layer.cornerRadius = 5
        statusDot.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(bgView)
        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(statusDot)
        addSubview(deleteButton)
        
        NSLayoutConstraint.activate([
            bgView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bgView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bgView.topAnchor.constraint(equalTo: topAnchor),
            bgView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconView.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14),
            
            statusDot.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            statusDot.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            statusDot.widthAnchor.constraint(equalToConstant: 10),
            statusDot.heightAnchor.constraint(equalToConstant: 10),
            heightAnchor.constraint(equalToConstant: 108)
        ])
        
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            deleteButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        }
        deleteButton.tintColor = UIColor(red: 255/255, green: 59/255, blue: 48/255, alpha: 1)
        deleteButton.alpha = 0
        deleteButton.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            deleteButton.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            deleteButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            deleteButton.widthAnchor.constraint(equalToConstant: 24),
            deleteButton.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        addTarget(self, action: #selector(tap), for: .touchUpInside)
        addTarget(self, action: #selector(pressDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(pressUp), for: [.touchUpInside, .touchDragExit, .touchCancel])
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        addGestureRecognizer(longPress)
        
        if #available(iOS 13.4, *) {
            let interaction = UIPointerInteraction(delegate: self)
            addInteraction(interaction)
        }
        applyAppearance(animated: false)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
    }
    func setOn(_ on: Bool, animated: Bool) {
        isOn = on
        applyAppearance(animated: animated)
    }
    func setDeleteMode(_ enabled: Bool, animated: Bool) {
        isDeleteMode = enabled
        let changes = {
            self.deleteButton.alpha = enabled ? 1 : 0
            self.deleteButton.transform = enabled ? .identity : CGAffineTransform(scaleX: 0.8, y: 0.8)
        }
        if animated {
            UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseInOut], animations: {
                changes()
            })
        } else {
            changes()
        }
    }
    @objc private func tap() {
        setOn(!isOn, animated: true)
        onChanged?(isOn)
    }
    @objc private func pressDown() {
        UIView.animate(withDuration: 0.12) {
            self.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        }
    }
    @objc private func pressUp() {
        UIView.animate(withDuration: 0.18) {
            self.transform = .identity
        }
    }
    private func applyAppearance(animated: Bool) {
        let onStart = UIColor(red: 255/255, green: 243/255, blue: 206/255, alpha: 1).cgColor
        let onEnd = UIColor(red: 255/255, green: 229/255, blue: 159/255, alpha: 1).cgColor
        let offStart = UIColor(white: 1.0, alpha: 1.0).cgColor
        let offEnd = UIColor(white: 0.98, alpha: 1.0).cgColor
        let dotOn = UIColor(red: 52/255, green: 199/255, blue: 89/255, alpha: 1)
        let dotOff = UIColor.lightGray
        let iconColor = isOn ? UIColor.orange : UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0)
        let changes = {
            self.gradient.colors = self.isOn ? [onStart, onEnd] : [offStart, offEnd]
            self.statusDot.backgroundColor = self.isOn ? dotOn : dotOff
            self.iconView.tintColor = iconColor
        }
        if animated {
            UIView.transition(with: bgView, duration: 0.2, options: .transitionCrossDissolve, animations: {
                changes()
            })
        } else {
            changes()
        }
    }
    @objc private func handleLongPress(_ gr: UILongPressGestureRecognizer) {
        if gr.state == .began {
            setDeleteMode(true, animated: true)
        }
    }
    @objc private func deleteTapped() {
        onDeleteRequested?()
    }
}

@available(iOS 13.4, *)
extension LightTileView: UIPointerInteractionDelegate {
    func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
        let effect = UIPointerEffect.highlight(UITargetedPreview(view: self))
        let shape = UIPointerShape.roundedRect(bounds, radius: 16)
        return UIPointerStyle(effect: effect, shape: shape)
    }
}

class CollapsibleSectionView: UIView {
    private let header = UIControl()
    private let titleLabel = UILabel()
    private let iconView = UIImageView()
    private let chevronView = UIImageView()
    private let deleteButton = UIButton(type: .system)
    let contentStack = UIStackView()
    private var collapsed = false
    var onCollapseChanged: ((Bool) -> Void)?
    var onDeleteGroupRequested: (() -> Void)?
    var isCollapsed: Bool { collapsed }
    private var contentHeightConstraint: NSLayoutConstraint?
    private var contentTopConstraint: NSLayoutConstraint?
    
    init(title: String, icon: UIImage?) {
        super.init(frame: .zero)
        setup(title: title, icon: icon)
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup(title: "", icon: nil)
    }
    private func setup(title: String, icon: UIImage?) {
        translatesAutoresizingMaskIntoConstraints = false
        
        header.translatesAutoresizingMaskIntoConstraints = false
        header.layer.cornerRadius = 14
        header.backgroundColor = UIColor(white: 1.0, alpha: 1.0)
        header.addTarget(self, action: #selector(toggleCollapse), for: .touchUpInside)
        
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0)
        iconView.image = icon
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        
        if #available(iOS 13.0, *) {
            chevronView.image = UIImage(systemName: "chevron.down")
        }
        chevronView.tintColor = .gray
        chevronView.translatesAutoresizingMaskIntoConstraints = false
        
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.alignment = .fill
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(header)
        header.addSubview(iconView)
        header.addSubview(titleLabel)
        header.addSubview(chevronView)
        addSubview(contentStack)
        
        contentTopConstraint = contentStack.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 12)
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: topAnchor),
            header.leadingAnchor.constraint(equalTo: leadingAnchor),
            header.trailingAnchor.constraint(equalTo: trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: 60),
            
            iconView.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            
            chevronView.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -16),
            chevronView.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            chevronView.widthAnchor.constraint(equalToConstant: 16),
            chevronView.heightAnchor.constraint(equalToConstant: 16),
            
            contentTopConstraint!,
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            deleteButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        }
        deleteButton.tintColor = UIColor(red: 255/255, green: 59/255, blue: 48/255, alpha: 1)
        deleteButton.alpha = 0
        deleteButton.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        deleteButton.addTarget(self, action: #selector(deleteGroupTapped), for: .touchUpInside)
        header.addSubview(deleteButton)
        NSLayoutConstraint.activate([
            deleteButton.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            deleteButton.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -44),
            deleteButton.widthAnchor.constraint(equalToConstant: 24),
            deleteButton.heightAnchor.constraint(equalToConstant: 24)
        ])
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleHeaderLongPress(_:)))
        header.addGestureRecognizer(longPress)
        
        contentHeightConstraint = contentStack.heightAnchor.constraint(equalToConstant: 0)
        contentHeightConstraint?.isActive = false
        
        updateChevron(animated: false)
    }
    
    func setCollapsed(_ value: Bool, animated: Bool) {
        collapsed = value
        contentHeightConstraint?.isActive = value
        contentTopConstraint?.constant = value ? 0 : 12
        contentStack.isHidden = value
        updateChevron(animated: animated)
    }
    
    @objc private func toggleCollapse() {
        collapsed.toggle()
        let duration: TimeInterval = 0.3
        if collapsed {
            contentHeightConstraint?.isActive = true
            contentTopConstraint?.constant = 0
            for v in contentStack.arrangedSubviews {
                v.alpha = 1
                v.transform = .identity
            }
            UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.4, options: [.curveEaseInOut], animations: {
                self.contentStack.alpha = 0
                self.contentStack.transform = CGAffineTransform(translationX: 0, y: -8)
                self.chevronView.transform = CGAffineTransform(rotationAngle: .pi/2)
                self.superview?.layoutIfNeeded()
            }) { _ in
                self.contentStack.isHidden = true
                self.contentStack.alpha = 1
                self.contentStack.transform = .identity
                self.onCollapseChanged?(true)
            }
        } else {
            self.contentStack.isHidden = false
            contentHeightConstraint?.isActive = false
            contentTopConstraint?.constant = 12
            self.contentStack.alpha = 0
            self.contentStack.transform = CGAffineTransform(translationX: 0, y: 8)
            UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.4, options: [.curveEaseInOut], animations: {
                self.contentStack.alpha = 1
                self.contentStack.transform = .identity
                self.chevronView.transform = CGAffineTransform(rotationAngle: 0)
                self.superview?.layoutIfNeeded()
            }) { _ in
                self.onCollapseChanged?(false)
            }
        }
    }
    
    @objc private func handleHeaderLongPress(_ gr: UILongPressGestureRecognizer) {
        if gr.state == .began {
            UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseInOut], animations: {
                self.deleteButton.alpha = 1
                self.deleteButton.transform = .identity
            })
        }
    }
    @objc private func deleteGroupTapped() {
        onDeleteGroupRequested?()
    }
    
    private func updateChevron(animated: Bool) {
        let rotation: CGFloat = collapsed ? .pi/2 : 0
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
                self.chevronView.transform = CGAffineTransform(rotationAngle: rotation)
            }
        } else {
            chevronView.transform = CGAffineTransform(rotationAngle: rotation)
        }
    }
    
}
