//
//  ProjectorControlViewController.swift
//  WuhanWaterConservationControlSystem
//
//  Created by SOLO Builder on 2025/12/23.
//  Copyright © 2025 WuhanWaterConservation. All rights reserved.
//

import UIKit

class ProjectorControlViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let tableView = UITableView()
    private let allOffButton = UIButton(type: .system)
    private let hexPanelStackView = UIStackView()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .landscape }
    override var shouldAutorotate: Bool { false }
    
    // MARK: - Properties
    
    private var projectorDevices: [Device] = []
    private var isLoading = false
    private var currentColumns: Int = 2
    private struct CustomDevice: Codable {
        let name: String
        let onHex: String
        let offHex: String
        let icon: String
    }
    private var customDevicesByGroup: [String: [CustomDevice]] = [:]
    private var collapseStates: [String: Bool] = [:]
    private var tileStates: [String: Bool] = [:]
    private var deletedPresetTitles: Set<String> = []
    private var deletedPresetGroups: Set<String> = []
    private var deleteLocks: Set<String> = []
    private let deleteLockInterval: TimeInterval = 0.8
    private let customDevicesKey = "projector_custom_devices"
    private let collapseStatesKey = "projector_collapsed_states"
    private let tileStatesKey = "projector_tile_states"
    private let deletedPresetTitlesKey = "projector_deleted_preset_titles"
    private let deletedPresetGroupsKey = "projector_deleted_preset_groups"
    private var pendingNewGroupName: String?
    private var pendingIconSymbol: String?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadProjectorDevices()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshDeviceStatus()
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
    
    // MARK: - Setup
    
    private func setupUI() {
        title = "投影一键开关"
        view.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
        
        setupNavigationBar()
        setupScrollContainer()
        setupTableView()
        setupAllOffButton()
        setupHexPanel()
        setupConstraints()
    }
    
    private func setupNavigationBar() {
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = false
        }
        
        let backButton = UIBarButtonItem(title: "返回", style: .plain, target: self, action: #selector(backButtonTapped))
        navigationItem.leftBarButtonItem = backButton
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonTapped))
        let refreshButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshButtonTapped))
        navigationItem.rightBarButtonItems = [addButton, refreshButton]
        
        if let navBar = navigationController?.navigationBar {
            navBar.setBackgroundImage(UIImage(), for: .default)
            navBar.shadowImage = UIImage()
            navBar.isTranslucent = true
            navBar.barTintColor = .white
            navBar.tintColor = UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0)
            navBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        }
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
        tableView.register(ProjectorDeviceCell.self, forCellReuseIdentifier: "ProjectorDeviceCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(tableView)
    }
    
    private func setupAllOffButton() {
        allOffButton.setTitle("全部关闭", for: .normal)
        allOffButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        allOffButton.backgroundColor = UIColor(red: 255.0/255.0, green: 59.0/255.0, blue: 48.0/255.0, alpha: 1.0)
        allOffButton.setTitleColor(.white, for: .normal)
        allOffButton.layer.cornerRadius = 12
        allOffButton.layer.shadowColor = UIColor.black.cgColor
        allOffButton.layer.shadowOpacity = 0.2
        allOffButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        allOffButton.layer.shadowRadius = 4
        allOffButton.addTarget(self, action: #selector(allOffButtonTapped), for: .touchUpInside)
        allOffButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(allOffButton)
    }
    
    // 已移除顶部状态文字
    
    private func setupHexPanel() {
        hexPanelStackView.axis = .vertical
        hexPanelStackView.distribution = .fill
        hexPanelStackView.spacing = 16
        hexPanelStackView.alignment = .fill
        hexPanelStackView.isLayoutMarginsRelativeArrangement = true
        hexPanelStackView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        hexPanelStackView.translatesAutoresizingMaskIntoConstraints = false
        customDevicesByGroup = loadCustomDevices()
        collapseStates = loadCollapseStates()
        tileStates = loadTileStates()
        loadDeletedPresets()
        
        var groups: [String: [Device]] = [:]
        for d in projectorDevices {
            if !deletedPresetTitles.contains(d.name) {
                let g = groupName(for: d.name)
                groups[g, default: []].append(d)
            }
        }
        var orderedGroupNames: [String] = []
        for g in ["主展厅投影", "互动区投影", "演示区投影", "其他"] {
            if (groups[g] != nil || customDevicesByGroup[g] != nil) && !deletedPresetGroups.contains(g) {
                orderedGroupNames.append(g)
            }
        }
        for g in customDevicesByGroup.keys where !deletedPresetGroups.contains(g) {
            if !orderedGroupNames.contains(g) { orderedGroupNames.append(g) }
        }
        
        for name in orderedGroupNames {
            let sectionIcon: UIImage? = {
                if #available(iOS 13.0, *) { return UIImage(systemName: "video.fill") }
                return nil
            }()
            let section = CollapsibleSectionView(title: name, icon: sectionIcon)
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
            struct TileData { let title: String; let deviceId: String?; let onHex: String?; let offHex: String?; let iconName: String? }
            var combined: [TileData] = []
            if let arr = groups[name] {
                for d in arr {
                    combined.append(TileData(title: d.name, deviceId: d.id, onHex: nil, offHex: nil, iconName: "video.fill"))
                }
            }
            if let customs = customDevicesByGroup[name] {
                for c in customs {
                    combined.append(TileData(title: c.name, deviceId: nil, onHex: c.onHex, offHex: c.offHex, iconName: c.icon))
                }
            }
            for td in combined {
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
                tile.title = td.title
                if #available(iOS 13.0, *) {
                    if let s = td.iconName { tile.icon = UIImage(systemName: s) }
                }
                let deviceInitial = projectorDevices.first(where: { $0.name == td.title })?.isOn ?? false
                let initialOn = tileStates[td.title] ?? deviceInitial
                tile.setOn(initialOn, animated: false)
                tile.onChanged = { [weak self] isOn in
                    guard let self = self else { return }
                    guard TCPConnectionManager.shared.isConnected else {
                        tile.setOn(!isOn, animated: true)
                        self.showAlert(title: "错误", message: "未连接到服务器")
                        return
                    }
                    if let did = td.deviceId {
                        let action: ControlAction = isOn ? .turnOn : .turnOff
                        DeviceManager.shared.controlDevice(did, action: action) { success, error in
                            DispatchQueue.main.async {
                                if success {
                                    self.saveTileState(title: td.title, isOn: isOn)
                                    self.refreshDeviceStatus()
                                } else {
                                    tile.setOn(!isOn, animated: true)
                                    let msg = error?.localizedDescription ?? "未知错误"
                                    self.showAlert(title: "发送失败", message: msg)
                                }
                            }
                        }
                    } else {
                        let cmd = isOn ? (td.onHex ?? "") : (td.offHex ?? "")
                        TCPConnectionManager.shared.sendHexCommand(cmd) { success, error in
                            DispatchQueue.main.async {
                                if success {
                                    self.saveTileState(title: td.title, isOn: isOn)
                                } else {
                                    tile.setOn(!isOn, animated: true)
                                    let msg = error?.localizedDescription ?? "未知错误"
                                    self.showAlert(title: "发送失败", message: msg)
                                }
                            }
                        }
                    }
                }
                tile.onDeleteRequested = { [weak self] in
                    self?.confirmDeleteDevice(inGroup: name, title: td.title)
                }
                rowStack?.addArrangedSubview(tile)
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
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        } else {
            view.addSubview(scrollView)
            scrollView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        }
        if #available(iOS 11.0, *) {
            scrollView.bottomAnchor.constraint(equalTo: allOffButton.topAnchor).isActive = true
            allOffButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30).isActive = true
        } else {
            scrollView.bottomAnchor.constraint(equalTo: allOffButton.topAnchor).isActive = true
            allOffButton.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor, constant: -30).isActive = true
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
            hexPanelStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            allOffButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            allOffButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            allOffButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        if #available(iOS 11.0, *) {
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
        } else {
            tableView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: 20).isActive = true
        }
        hexPanelStackView.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 20).isActive = true
        contentView.bottomAnchor.constraint(equalTo: hexPanelStackView.bottomAnchor, constant: 20).isActive = true
    }
    
    // MARK: - Data Loading
    
    private func loadProjectorDevices() {
        isLoading = true
        
        // 获取所有投影设备
        projectorDevices = DeviceManager.shared.getDevices(byType: .projector)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isLoading = false
            self?.tableView.reloadData()
            self?.clearStackView(self!.hexPanelStackView)
            self?.setupHexPanel()
        }
    }
    
    private func refreshDeviceStatus() {
        DeviceManager.shared.refreshDeviceStatus { [weak self] success in
            if success {
                self?.projectorDevices = DeviceManager.shared.getDevices(byType: .projector)
                self?.tableView.reloadData()
                self?.clearStackView(self!.hexPanelStackView)
                self?.setupHexPanel()
            }
        }
    }
    
    // 顶部状态文字已删除
    
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
    
    @objc private func allOffButtonTapped() {
        guard !projectorDevices.isEmpty else {
            showAlert(title: "提示", message: "没有可控制的投影设备")
            return
        }
        
        let alert = UIAlertController(title: "确认操作", message: "确定要关闭所有投影设备吗？", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .destructive) { [weak self] _ in
            self?.turnOffAllProjectorDevices()
        })
        
        present(alert, animated: true)
    }
    
    private func turnOffAllProjectorDevices() {
        isLoading = true
        allOffButton.isEnabled = false
        allOffButton.setTitle("正在执行...", for: .normal)
        
        DeviceManager.shared.controlAllDevices(ofType: .projector, action: .allOff) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.allOffButton.isEnabled = true
                self?.allOffButton.setTitle("全部关闭", for: .normal)
                
                if success {
                    self?.showAlert(title: "成功", message: "所有投影设备已关闭")
                    self?.refreshDeviceStatus()
                } else {
                    let errorMessage = error?.localizedDescription ?? "未知错误"
                    self?.showAlert(title: "错误", message: "操作失败: \(errorMessage)")
                }
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
    
    private func groupName(for name: String) -> String {
        if name.contains("主展厅") { return "主展厅投影" }
        if name.contains("互动") { return "互动区投影" }
        if name.contains("演示") { return "演示区投影" }
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
    
    private func loadCustomDevices() -> [String: [CustomDevice]] {
        let ud = UserDefaults.standard
        guard let data = ud.data(forKey: customDevicesKey) else { return [:] }
        let decoder = JSONDecoder()
        if let dict = try? decoder.decode([String: [CustomDevice]].self, from: data) {
            return dict
        }
        return [:]
    }
    private func saveCustomDevices(_ dict: [String: [CustomDevice]]) {
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
    private func customsByGroupSanitized(_ dict: [String: [CustomDevice]]) -> [String: [CustomDevice]] {
        var out = dict
        for (k, v) in out {
            if v.isEmpty { out.removeValue(forKey: k) }
        }
        return out
    }
    @objc private func addButtonTapped() {
        presentGroupSelection()
    }
    private func allGroupNames() -> [String] {
        var set = Set<String>()
        for d in projectorDevices { set.insert(groupName(for: d.name)) }
        for k in customDevicesByGroup.keys { set.insert(k) }
        return Array(set)
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
        alert.addTextField { tf in tf.placeholder = "分组名称" }
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
        let icons: [(String, String)] = [("投影", "video.fill"), ("电脑", "desktopcomputer"), ("灯光", "lightbulb.fill"), ("电源", "power")]
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
        alert.addTextField { $0.placeholder = "设备名称" }
        alert.addTextField { $0.placeholder = "开启指令 HEX" }
        alert.addTextField { $0.placeholder = "关闭指令 HEX" }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "创建", style: .default, handler: { _ in
            let name = alert.textFields?[0].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let onHex = alert.textFields?[1].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let offHex = alert.textFields?[2].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard let group = self.pendingNewGroupName, !name.isEmpty, !onHex.isEmpty, !offHex.isEmpty else { return }
            let icon = self.pendingIconSymbol ?? "video.fill"
            var dict = self.customDevicesByGroup
            var arr = dict[group] ?? []
            arr.append(CustomDevice(name: name, onHex: onHex, offHex: offHex, icon: icon))
            dict[group] = arr
            self.customDevicesByGroup = dict
            self.saveCustomDevices(dict)
            self.clearStackView(self.hexPanelStackView)
            self.setupHexPanel()
        }))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension ProjectorControlViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return projectorDevices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ProjectorDeviceCell", for: indexPath) as? ProjectorDeviceCell else {
            return UITableViewCell()
        }
        
        let device = projectorDevices[indexPath.row]
        cell.configure(with: device)
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ProjectorControlViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let device = projectorDevices[indexPath.row]
        toggleDevice(device)
    }
}

// MARK: - ProjectorDeviceCell

class ProjectorDeviceCell: UITableViewCell {
    
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
        iconImageView.tintColor = UIColor(red: 0.6, green: 0.2, blue: 1.0, alpha: 1.0)
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 13.0, *) {
            iconImageView.image = UIImage(systemName: "video.fill")
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
        
        context.setFillColor(UIColor(red: 0.6, green: 0.2, blue: 1.0, alpha: 1.0).cgColor)
        context.setStrokeColor(UIColor(red: 0.6, green: 0.2, blue: 1.0, alpha: 1.0).cgColor)
        
        // 绘制投影仪形状
        context.fillEllipse(in: CGRect(x: 6, y: 8, width: 20, height: 16))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    @objc private func switchValueChanged() {
        // 开关状态改变时通知父视图控制器
        // 这里可以通过代理或通知机制实现
    }
}
