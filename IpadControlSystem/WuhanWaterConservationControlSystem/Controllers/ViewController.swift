//
//  ViewController.swift
//  WuhanWaterConservationControlSystem
//
//  Created by SOLO Builder on 2025/12/23.
//  Copyright © 2025 WuhanWaterConservation. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let connectionStatusView = UIView()
    private let connectionStatusLabel = UILabel()
    private let connectionIndicator = UIView()
    
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    private let deviceStatusStackView = UIStackView()
    private let lightingCard = DeviceControlCard()
    private let computerCard = DeviceControlCard()
    private let projectorCard = DeviceControlCard()
    private let exhibitCard = DeviceControlCard()
    
    private let controlButtonsStackView = UIStackView()
    private let lightingButton = UIButton(type: .system)
    private let computerButton = UIButton(type: .system)
    private let projectorButton = UIButton(type: .system)
    private let exhibitButton = UIButton(type: .system)
    
    private let settingsButton = UIButton(type: .system)
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .landscape }
    override var shouldAutorotate: Bool { false }
    // MARK: - Properties
    
    private var connectionStatus: TCPConnectionStatus = .disconnected {
        didSet {
            updateConnectionStatusUI()
        }
    }
    
    enum TCPConnectionStatus {
        case connected
        case disconnected
        case connecting
        case error(String)
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDelegates()
        setupConnection()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateDeviceStatus()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
        
        setupConnectionStatusView()
        setupTitleLabels()
        setupDeviceCards()
        setupControlButtons()
        setupSettingsButton()
        
        setupConstraints()
    }
    
    private func setupConnectionStatusView() {
        connectionStatusView.backgroundColor = .white
        connectionStatusView.layer.cornerRadius = 8
        connectionStatusView.layer.shadowColor = UIColor.black.cgColor
        connectionStatusView.layer.shadowOpacity = 0.1
        connectionStatusView.layer.shadowOffset = CGSize(width: 0, height: 2)
        connectionStatusView.layer.shadowRadius = 4
        
        connectionIndicator.backgroundColor = .red
        connectionIndicator.layer.cornerRadius = 6
        connectionIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        connectionStatusLabel.text = "网络连接: 未连接"
        connectionStatusLabel.font = UIFont.systemFont(ofSize: 14)
        connectionStatusLabel.textColor = .darkGray
        connectionStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        connectionStatusView.addSubview(connectionIndicator)
        connectionStatusView.addSubview(connectionStatusLabel)
        view.addSubview(connectionStatusView)
    }
    
    private func setupTitleLabels() {
        titleLabel.text = "武汉节水科技馆"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 28)
        titleLabel.textColor = .darkText
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        subtitleLabel.text = "中控系统"
        subtitleLabel.font = UIFont.systemFont(ofSize: 20)
        subtitleLabel.textColor = .gray
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
    }
    
    private func setupDeviceCards() {
        deviceStatusStackView.axis = .horizontal
        deviceStatusStackView.distribution = .fillEqually
        deviceStatusStackView.spacing = 16
        deviceStatusStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // 设置设备卡片
        lightingCard.configure(
            title: "灯光一键全开/全关",
            icon: "lightbulb.fill",
            deviceType: .lighting,
            color: UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0)
        )
        
        computerCard.configure(
            title: "电脑一键开关",
            icon: "desktopcomputer",
            deviceType: .computer,
            color: UIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0)
        )
        
        projectorCard.configure(
            title: "投影一键开关",
            icon: "video.fill",
            deviceType: .projector,
            color: UIColor(red: 0.6, green: 0.2, blue: 1.0, alpha: 1.0)
        )
        
        exhibitCard.configure(
            title: "展品电源总控",
            icon: "power",
            deviceType: .exhibitPower,
            color: UIColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0)
        )
        
        deviceStatusStackView.addArrangedSubview(lightingCard)
        deviceStatusStackView.addArrangedSubview(computerCard)
        deviceStatusStackView.addArrangedSubview(projectorCard)
        deviceStatusStackView.addArrangedSubview(exhibitCard)
        
        view.addSubview(deviceStatusStackView)
    }
    
    private func setupControlButtons() {
        controlButtonsStackView.axis = .horizontal
        controlButtonsStackView.distribution = .fillEqually
        controlButtonsStackView.spacing = 20
        controlButtonsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        setupControlButton(lightingButton, title: "灯光", icon: "lightbulb.fill")
        setupControlButton(computerButton, title: "电脑", icon: "desktopcomputer")
        setupControlButton(projectorButton, title: "投影", icon: "video.fill")
        setupControlButton(exhibitButton, title: "展品", icon: "power")
        
        lightingButton.addTarget(self, action: #selector(lightingButtonTapped), for: .touchUpInside)
        computerButton.addTarget(self, action: #selector(computerButtonTapped), for: .touchUpInside)
        projectorButton.addTarget(self, action: #selector(projectorButtonTapped), for: .touchUpInside)
        exhibitButton.addTarget(self, action: #selector(exhibitButtonTapped), for: .touchUpInside)
        
        controlButtonsStackView.addArrangedSubview(lightingButton)
        controlButtonsStackView.addArrangedSubview(computerButton)
        controlButtonsStackView.addArrangedSubview(projectorButton)
        controlButtonsStackView.addArrangedSubview(exhibitButton)
        
        view.addSubview(controlButtonsStackView)
    }
    
    private func setupControlButton(_ button: UIButton, title: String, icon: String) {
        button.backgroundColor = .white
        button.layer.cornerRadius = 12
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.1
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4

        button.setTitle(title, for: .normal)
        button.setTitleColor(UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0), for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        
        if #available(iOS 13.0, *) {
            button.setImage(UIImage(systemName: icon), for: .normal)
        } else {
            // iOS 10兼容性处理
            // 仅显示文字标题
        }
    }
    
    private func setupSettingsButton() {
        if #available(iOS 13.0, *) {
            settingsButton.setImage(UIImage(systemName: "gear"), for: .normal)
        } else {
            settingsButton.setTitle("设置", for: .normal)
            settingsButton.setTitleColor(.darkGray, for: .normal)
        }
        settingsButton.backgroundColor = .white
        settingsButton.layer.cornerRadius = 8
        settingsButton.layer.shadowColor = UIColor.black.cgColor
        settingsButton.layer.shadowOpacity = 0.1
        settingsButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        settingsButton.layer.shadowRadius = 4
        settingsButton.tintColor = .darkGray
        settingsButton.addTarget(self, action: #selector(settingsButtonTapped), for: .touchUpInside)
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(settingsButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // 连接状态视图
            connectionStatusView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            connectionStatusView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            connectionStatusView.heightAnchor.constraint(equalToConstant: 50),
            
            connectionIndicator.centerYAnchor.constraint(equalTo: connectionStatusView.centerYAnchor),
            connectionIndicator.leadingAnchor.constraint(equalTo: connectionStatusView.leadingAnchor, constant: 16),
            connectionIndicator.widthAnchor.constraint(equalToConstant: 12),
            connectionIndicator.heightAnchor.constraint(equalToConstant: 12),
            
            connectionStatusLabel.centerYAnchor.constraint(equalTo: connectionStatusView.centerYAnchor),
            connectionStatusLabel.leadingAnchor.constraint(equalTo: connectionIndicator.trailingAnchor, constant: 12),
            connectionStatusLabel.trailingAnchor.constraint(equalTo: connectionStatusView.trailingAnchor, constant: -16),
            
            // 标题标签
            titleLabel.topAnchor.constraint(equalTo: connectionStatusView.bottomAnchor, constant: 30),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // 设备状态卡片
            deviceStatusStackView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
            deviceStatusStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            deviceStatusStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            deviceStatusStackView.heightAnchor.constraint(equalToConstant: 120),
            
            // 控制按钮
            controlButtonsStackView.topAnchor.constraint(equalTo: deviceStatusStackView.bottomAnchor, constant: 40),
            controlButtonsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            controlButtonsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            controlButtonsStackView.heightAnchor.constraint(equalToConstant: 80),
            
            // 设置按钮
            settingsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            settingsButton.widthAnchor.constraint(equalToConstant: 44),
            settingsButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        if #available(iOS 11.0, *) {
            connectionStatusView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
            settingsButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20).isActive = true
        } else {
            connectionStatusView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: 20).isActive = true
            settingsButton.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor, constant: -20).isActive = true
        }
    }
    
    // MARK: - Delegates
    
    private func setupDelegates() {
        TCPConnectionManager.shared.delegate = self
        DeviceManager.shared.delegate = self
    }
    
    private func setupConnection() {
        // 初始化TCP连接，优先使用设置保存的地址与端口
        let host = UserDefaults.standard.string(forKey: "serverAddress") ?? "192.168.200.31"
        let portString = UserDefaults.standard.string(forKey: "serverPort") ?? "6001"
        let port = Int(portString) ?? 6001
        TCPConnectionManager.shared.setupConnection(host: host, port: port)
    }
    
    // MARK: - UI Updates
    
    private func updateConnectionStatusUI() {
        switch connectionStatus {
        case .connected:
            connectionIndicator.backgroundColor = UIColor(red: 52.0/255.0, green: 199.0/255.0, blue: 89.0/255.0, alpha: 1.0)
            connectionStatusLabel.text = "网络连接: 已连接"
        case .disconnected:
            connectionIndicator.backgroundColor = .red
            connectionStatusLabel.text = "网络连接: 未连接"
        case .connecting:
            connectionIndicator.backgroundColor = UIColor(red: 255.0/255.0, green: 204.0/255.0, blue: 0.0/255.0, alpha: 1.0)
            connectionStatusLabel.text = "网络连接: 连接中..."
        case .error(let message):
            connectionIndicator.backgroundColor = .red
            connectionStatusLabel.text = "网络连接: 错误 - \(message)"
        }
    }
    
    private func updateDeviceStatus() {
        let allDevices = DeviceManager.shared.getAllDevices()
        
        // 更新各个卡片的状态
        let lightingDevices = allDevices.filter { $0.type == .lighting }
        let computerDevices = allDevices.filter { $0.type == .computer }
        let projectorDevices = allDevices.filter { $0.type == .projector }
        let exhibitDevices = allDevices.filter { $0.type == .exhibitPower }
        
        lightingCard.updateStatus(onlineCount: lightingDevices.filter { $0.status == .online }.count,
                                 totalCount: lightingDevices.count)
        
        computerCard.updateStatus(onlineCount: computerDevices.filter { $0.status == .online }.count,
                                totalCount: computerDevices.count)
        
        projectorCard.updateStatus(onlineCount: projectorDevices.filter { $0.status == .online }.count,
                                 totalCount: projectorDevices.count)
        
        exhibitCard.updateStatus(onlineCount: exhibitDevices.filter { $0.status == .online }.count,
                               totalCount: exhibitDevices.count)
    }
    
    // MARK: - Button Actions
    
    @objc private func lightingButtonTapped() {
        let lightingVC = LightingControlViewController()
        if let nav = navigationController {
            nav.pushViewController(lightingVC, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: lightingVC)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
    }
    
    @objc private func computerButtonTapped() {
        let computerVC = ComputerControlViewController()
        if let nav = navigationController {
            nav.pushViewController(computerVC, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: computerVC)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
    }
    
    @objc private func projectorButtonTapped() {
        let projectorVC = ProjectorControlViewController()
        if let nav = navigationController {
            nav.pushViewController(projectorVC, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: projectorVC)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
    }
    
    @objc private func exhibitButtonTapped() {
        let exhibitVC = ExhibitPowerControlViewController()
        if let nav = navigationController {
            nav.pushViewController(exhibitVC, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: exhibitVC)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
    }
    
    @objc private func settingsButtonTapped() {
        let settingsVC = SettingsViewController()
        if let nav = navigationController {
            nav.pushViewController(settingsVC, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: settingsVC)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
    }
}

// MARK: - TCPConnectionManagerDelegate

extension MainViewController: TCPConnectionManagerDelegate {
    
    func tcpConnectionDidConnect() {
        connectionStatus = .connected
        updateDeviceStatus()
    }
    
    func tcpConnectionDidDisconnect(error: Error?) {
        if let error = error {
            connectionStatus = .error(error.localizedDescription)
        } else {
            connectionStatus = .disconnected
        }
        updateDeviceStatus()
    }
    
    func tcpConnectionDidReceiveData(_ data: Data) {
        // 处理接收到的数据
        print("MainViewController: Received data - \(data)")
    }
    
    func tcpConnectionDidFailToConnect(error: Error) {
        connectionStatus = .error(error.localizedDescription)
    }
}

// MARK: - DeviceManagerDelegate

extension MainViewController: DeviceManagerDelegate {
    
    func deviceManager(_ manager: DeviceManager, didUpdateDevice device: Device) {
        updateDeviceStatus()
    }
    
    func deviceManager(_ manager: DeviceManager, didFailWithError error: Error) {
        let alert = UIAlertController(title: "设备错误", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    func deviceManager(_ manager: DeviceManager, didReceiveStatus status: [String: Any]) {
        print("MainViewController: Received status - \(status)")
    }
}
