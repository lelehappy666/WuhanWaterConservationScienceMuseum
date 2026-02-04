//
//  ExhibitPowerControlViewController.swift
//  WuhanWaterConservationControlSystem
//
//  Created by SOLO Builder on 2025/12/23.
//  Copyright © 2025 WuhanWaterConservation. All rights reserved.
//

import UIKit

class ExhibitPowerControlViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let allOnButton = UIButton(type: .system)
    private let allOffButton = UIButton(type: .system)
    private let powerStatusView = UIView()
    private let powerIndicator = UIView()
    private let hexPanelStackView = UIStackView()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .landscape }
    override var shouldAutorotate: Bool { false }
    
    // MARK: - Properties
    
    private var exhibitDevices: [Device] = []
    private var isLoading = false
    private var isPowerOn: Bool = false
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
    private let customDevicesKey = "exhibit_custom_devices"
    private let collapseStatesKey = "exhibit_collapsed_states"
    private let tileStatesKey = "exhibit_tile_states"
    private let deletedPresetTitlesKey = "exhibit_deleted_preset_titles"
    private let deletedPresetGroupsKey = "exhibit_deleted_preset_groups"
    private var pendingNewGroupName: String?
    private var pendingIconSymbol: String?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadExhibitDevices()
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
        title = "展品电源总控"
        view.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
        
        setupNavigationBar()
        setupScrollContainer()
        setupPowerStatusView()
        setupHexPanel()
        setupControlButtons()
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
    // 顶部状态文字已删除
    
    private func setupPowerStatusView() {
        powerStatusView.backgroundColor = .white
        powerStatusView.layer.cornerRadius = 12
        powerStatusView.layer.shadowColor = UIColor.black.cgColor
        powerStatusView.layer.shadowOpacity = 0.1
        powerStatusView.layer.shadowOffset = CGSize(width: 0, height: 2)
        powerStatusView.layer.shadowRadius = 4
        powerStatusView.translatesAutoresizingMaskIntoConstraints = false
        
        powerIndicator.backgroundColor = .red
        powerIndicator.layer.cornerRadius = 30
        powerIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        powerStatusView.addSubview(powerIndicator)
        contentView.addSubview(powerStatusView)
    }
    
    // 设备数量文字已删除
    
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
        for d in exhibitDevices {
            if !deletedPresetTitles.contains(d.name) {
                let g = groupName(for: d.name)
                groups[g, default: []].append(d)
            }
        }
        var orderedGroupNames: [String] = []
        for g in ["节水展品", "互动展品", "科普展品", "实验展品", "其他"] {
            if (groups[g] != nil || customDevicesByGroup[g] != nil) && !deletedPresetGroups.contains(g) {
                orderedGroupNames.append(g)
            }
        }
        for g in customDevicesByGroup.keys where !deletedPresetGroups.contains(g) {
            if !orderedGroupNames.contains(g) { orderedGroupNames.append(g) }
        }
        
        for name in orderedGroupNames {
            let sectionIcon: UIImage? = {
                if #available(iOS 13.0, *) { return UIImage(systemName: "power") }
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
                    combined.append(TileData(title: d.name, deviceId: d.id, onHex: nil, offHex: nil, iconName: "power"))
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
                let deviceInitial = exhibitDevices.first(where: { $0.name == td.title })?.isOn ?? false
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
    
    private func setupControlButtons() {
        allOnButton.setTitle("全部开启", for: .normal)
        allOnButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        allOnButton.backgroundColor = UIColor(red: 52.0/255.0, green: 199.0/255.0, blue: 89.0/255.0, alpha: 1.0)
        allOnButton.setTitleColor(.white, for: .normal)
        allOnButton.layer.cornerRadius = 16
        allOnButton.layer.shadowColor = UIColor.black.cgColor
        allOnButton.layer.shadowOpacity = 0.2
        allOnButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        allOnButton.layer.shadowRadius = 8
        allOnButton.addTarget(self, action: #selector(allOnButtonTapped), for: .touchUpInside)
        allOnButton.translatesAutoresizingMaskIntoConstraints = false
        
        allOffButton.setTitle("全部关闭", for: .normal)
        allOffButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        allOffButton.backgroundColor = UIColor(red: 255.0/255.0, green: 59.0/255.0, blue: 48.0/255.0, alpha: 1.0)
        allOffButton.setTitleColor(.white, for: .normal)
        allOffButton.layer.cornerRadius = 16
        allOffButton.layer.shadowColor = UIColor.black.cgColor
        allOffButton.layer.shadowOpacity = 0.2
        allOffButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        allOffButton.layer.shadowRadius = 8
        allOffButton.addTarget(self, action: #selector(allOffButtonTapped), for: .touchUpInside)
        allOffButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(allOnButton)
        view.addSubview(allOffButton)
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
            
            powerStatusView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            powerStatusView.widthAnchor.constraint(equalToConstant: 200),
            powerStatusView.heightAnchor.constraint(equalToConstant: 200),
            
            powerIndicator.centerXAnchor.constraint(equalTo: powerStatusView.centerXAnchor),
            powerIndicator.centerYAnchor.constraint(equalTo: powerStatusView.centerYAnchor),
            powerIndicator.widthAnchor.constraint(equalToConstant: 60),
            powerIndicator.heightAnchor.constraint(equalToConstant: 60),
            
            hexPanelStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            hexPanelStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            allOnButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            allOnButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            allOnButton.heightAnchor.constraint(equalToConstant: 80),
            
            allOffButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            allOffButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            allOffButton.heightAnchor.constraint(equalToConstant: 80)
        ])
        if #available(iOS 11.0, *) {
            powerStatusView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40).isActive = true
        } else {
            powerStatusView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: 40).isActive = true
        }
        hexPanelStackView.topAnchor.constraint(equalTo: powerStatusView.bottomAnchor, constant: 20).isActive = true
        contentView.bottomAnchor.constraint(equalTo: hexPanelStackView.bottomAnchor, constant: 20).isActive = true
    }
    
    // MARK: - Data Loading
    
    private func loadExhibitDevices() {
        isLoading = true
        
        exhibitDevices = DeviceManager.shared.getDevices(byType: .exhibitPower)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isLoading = false
            self?.updateUI()
            self?.clearStackView(self!.hexPanelStackView)
            self?.setupHexPanel()
        }
    }
    
    private func refreshDeviceStatus() {
        DeviceManager.shared.refreshDeviceStatus { [weak self] success in
            if success {
                self?.exhibitDevices = DeviceManager.shared.getDevices(byType: .exhibitPower)
                self?.updateUI()
                self?.clearStackView(self!.hexPanelStackView)
                self?.setupHexPanel()
            }
        }
    }
    
    private func updateUI() {
        let onlineCount = exhibitDevices.filter { $0.status == .online }.count
        let totalCount = exhibitDevices.count
        
        // 更新电源状态
        isPowerOn = onlineCount > 0
        updatePowerStatus()
        
        // 更新按钮状态
        allOnButton.isEnabled = !isLoading
        allOffButton.isEnabled = !isLoading
    }
    
    private func updatePowerStatus() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self else { return }
            
            if self.isPowerOn {
                self.powerIndicator.backgroundColor = UIColor(red: 52.0/255.0, green: 199.0/255.0, blue: 89.0/255.0, alpha: 1.0)
            } else {
                self.powerIndicator.backgroundColor = .red
            }
        }
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
        guard !exhibitDevices.isEmpty else {
            showAlert(title: "提示", message: "没有可控制的展品设备")
            return
        }
        
        let alert = UIAlertController(title: "确认操作", message: "确定要开启所有展品电源吗？", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            self?.turnOnAllExhibitDevices()
        })
        
        present(alert, animated: true)
    }
    
    @objc private func allOffButtonTapped() {
        guard !exhibitDevices.isEmpty else {
            showAlert(title: "提示", message: "没有可控制的展品设备")
            return
        }
        
        let alert = UIAlertController(title: "确认操作", message: "确定要关闭所有展品电源吗？", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .destructive) { [weak self] _ in
            self?.turnOffAllExhibitDevices()
        })
        
        present(alert, animated: true)
    }
    
    private func turnOnAllExhibitDevices() {
        isLoading = true
        allOnButton.isEnabled = false
        allOffButton.isEnabled = false
        allOnButton.setTitle("正在开启...", for: .normal)
        
        DeviceManager.shared.controlAllDevices(ofType: .exhibitPower, action: .allOn) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.allOnButton.isEnabled = true
                self?.allOffButton.isEnabled = true
                self?.allOnButton.setTitle("全部开启", for: .normal)
                
                if success {
                    self?.showAlert(title: "成功", message: "所有展品电源已开启")
                    self?.refreshDeviceStatus()
                } else {
                    let errorMessage = error?.localizedDescription ?? "未知错误"
                    self?.showAlert(title: "错误", message: "操作失败: \(errorMessage)")
                }
            }
        }
    }
    
    private func turnOffAllExhibitDevices() {
        isLoading = true
        allOnButton.isEnabled = false
        allOffButton.isEnabled = false
        allOffButton.setTitle("正在关闭...", for: .normal)
        
        DeviceManager.shared.controlAllDevices(ofType: .exhibitPower, action: .allOff) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.allOnButton.isEnabled = true
                self?.allOffButton.isEnabled = true
                self?.allOffButton.setTitle("全部关闭", for: .normal)
                
                if success {
                    self?.showAlert(title: "成功", message: "所有展品电源已关闭")
                    self?.refreshDeviceStatus()
                } else {
                    let errorMessage = error?.localizedDescription ?? "未知错误"
                    self?.showAlert(title: "错误", message: "操作失败: \(errorMessage)")
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    private func groupName(for name: String) -> String {
        if name.contains("节水") { return "节水展品" }
        if name.contains("互动") { return "互动展品" }
        if name.contains("科普") { return "科普展品" }
        if name.contains("实验") { return "实验展品" }
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
        for d in exhibitDevices { set.insert(groupName(for: d.name)) }
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
        let icons: [(String, String)] = [("电源", "power"), ("灯光", "lightbulb.fill"), ("投影", "video.fill"), ("电脑", "desktopcomputer")]
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
            let icon = self.pendingIconSymbol ?? "power"
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
