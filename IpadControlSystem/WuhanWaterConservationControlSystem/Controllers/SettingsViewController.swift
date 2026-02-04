//
//  SettingsViewController.swift
//  WuhanWaterConservationControlSystem
//
//  Created by SOLO Builder on 2025/12/23.
//  Copyright © 2025 WuhanWaterConservation. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let connectionSettingsLabel = UILabel()
    private let serverAddressLabel = UILabel()
    private let serverAddressTextField = UITextField()
    private let portLabel = UILabel()
    private let portTextField = UITextField()
    
    private let connectionStatusLabel = UILabel()
    private let connectionIndicator = UIView()
    private let connectButton = UIButton(type: .system)
    private let disconnectButton = UIButton(type: .system)
    
    private let deviceSettingsLabel = UILabel()
    private let autoReconnectSwitch = UISwitch()
    private let autoReconnectLabel = UILabel()
    private let reconnectIntervalLabel = UILabel()
    private let reconnectIntervalTextField = UITextField()
    
    private let aboutLabel = UILabel()
    private let versionLabel = UILabel()
    private let appIconImageView = UIImageView()
    
    // MARK: - Properties
    
    private let defaultServerAddress = "192.168.200.31"
    private let defaultPort = "6001"
    private let defaultReconnectInterval = "5"
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .landscape }
    override var shouldAutorotate: Bool { false }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadSettings()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let navBar = navigationController?.navigationBar {
            navBar.setBackgroundImage(UIImage(), for: .default)
            navBar.shadowImage = UIImage()
            navBar.isTranslucent = true
            navBar.barTintColor = .white
            navBar.tintColor = UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0)
            navBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        }
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        title = "网络设置"
        view.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
        
        setupScrollView()
        setupConnectionSettings()
        setupDeviceSettings()
        setupAboutSection()
        setupConstraints()
        setupKeyboardHandling()
    }
    
    private func setupScrollView() {
        scrollView.backgroundColor = .clear
        scrollView.showsVerticalScrollIndicator = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.backgroundColor = .clear
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
    }
    
    private func setupConnectionSettings() {
        connectionSettingsLabel.text = "连接设置"
        connectionSettingsLabel.font = UIFont.boldSystemFont(ofSize: 20)
        connectionSettingsLabel.textColor = .darkText
        connectionSettingsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        serverAddressLabel.text = "服务器地址"
        serverAddressLabel.font = UIFont.systemFont(ofSize: 16)
        serverAddressLabel.textColor = .darkText
        serverAddressLabel.translatesAutoresizingMaskIntoConstraints = false
        
        serverAddressTextField.placeholder = defaultServerAddress
        serverAddressTextField.borderStyle = .roundedRect
        serverAddressTextField.keyboardType = .numbersAndPunctuation
        serverAddressTextField.returnKeyType = .next
        serverAddressTextField.delegate = self
        serverAddressTextField.translatesAutoresizingMaskIntoConstraints = false
        
        portLabel.text = "端口号"
        portLabel.font = UIFont.systemFont(ofSize: 16)
        portLabel.textColor = .darkText
        portLabel.translatesAutoresizingMaskIntoConstraints = false
        
        portTextField.placeholder = defaultPort
        portTextField.borderStyle = .roundedRect
        portTextField.keyboardType = .numberPad
        portTextField.returnKeyType = .done
        portTextField.delegate = self
        portTextField.translatesAutoresizingMaskIntoConstraints = false
        
        connectionStatusLabel.text = "连接状态: 未连接"
        connectionStatusLabel.font = UIFont.systemFont(ofSize: 14)
        connectionStatusLabel.textColor = .gray
        connectionStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        connectionIndicator.backgroundColor = .red
        connectionIndicator.layer.cornerRadius = 6
        connectionIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        connectButton.setTitle("连接", for: .normal)
        connectButton.backgroundColor = UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0)
        connectButton.setTitleColor(.white, for: .normal)
        connectButton.layer.cornerRadius = 8
        connectButton.addTarget(self, action: #selector(connectButtonTapped), for: .touchUpInside)
        connectButton.translatesAutoresizingMaskIntoConstraints = false
        
        disconnectButton.setTitle("断开连接", for: .normal)
        disconnectButton.backgroundColor = UIColor(red: 255.0/255.0, green: 59.0/255.0, blue: 48.0/255.0, alpha: 1.0)
        disconnectButton.setTitleColor(.white, for: .normal)
        disconnectButton.layer.cornerRadius = 8
        disconnectButton.addTarget(self, action: #selector(disconnectButtonTapped), for: .touchUpInside)
        disconnectButton.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(connectionSettingsLabel)
        contentView.addSubview(serverAddressLabel)
        contentView.addSubview(serverAddressTextField)
        contentView.addSubview(portLabel)
        contentView.addSubview(portTextField)
        contentView.addSubview(connectionStatusLabel)
        contentView.addSubview(connectionIndicator)
        contentView.addSubview(connectButton)
        contentView.addSubview(disconnectButton)
    }
    
    private func setupDeviceSettings() {
        deviceSettingsLabel.text = "设备设置"
        deviceSettingsLabel.font = UIFont.boldSystemFont(ofSize: 20)
        deviceSettingsLabel.textColor = .darkText
        deviceSettingsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        autoReconnectLabel.text = "自动重连"
        autoReconnectLabel.font = UIFont.systemFont(ofSize: 16)
        autoReconnectLabel.textColor = .darkText
        autoReconnectLabel.translatesAutoresizingMaskIntoConstraints = false
        
        autoReconnectSwitch.onTintColor = UIColor(red: 52.0/255.0, green: 199.0/255.0, blue: 89.0/255.0, alpha: 1.0)
        autoReconnectSwitch.isOn = true // 默认开启
        autoReconnectSwitch.translatesAutoresizingMaskIntoConstraints = false
        
        reconnectIntervalLabel.text = "重连间隔 (秒)"
        reconnectIntervalLabel.font = UIFont.systemFont(ofSize: 16)
        reconnectIntervalLabel.textColor = .darkText
        reconnectIntervalLabel.translatesAutoresizingMaskIntoConstraints = false
        
        reconnectIntervalTextField.placeholder = defaultReconnectInterval
        reconnectIntervalTextField.borderStyle = .roundedRect
        reconnectIntervalTextField.keyboardType = .numberPad
        reconnectIntervalTextField.returnKeyType = .done
        reconnectIntervalTextField.delegate = self
        reconnectIntervalTextField.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(deviceSettingsLabel)
        contentView.addSubview(autoReconnectLabel)
        contentView.addSubview(autoReconnectSwitch)
        contentView.addSubview(reconnectIntervalLabel)
        contentView.addSubview(reconnectIntervalTextField)
    }
    
    private func setupAboutSection() {
        aboutLabel.text = "关于"
        aboutLabel.font = UIFont.boldSystemFont(ofSize: 20)
        aboutLabel.textColor = .darkText
        aboutLabel.translatesAutoresizingMaskIntoConstraints = false
        
        appIconImageView.contentMode = .scaleAspectFit
        appIconImageView.layer.cornerRadius = 12
        appIconImageView.clipsToBounds = true
        appIconImageView.backgroundColor = UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0)
        appIconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        versionLabel.text = "版本 1.0.0"
        versionLabel.font = UIFont.systemFont(ofSize: 14)
        versionLabel.textColor = .gray
        versionLabel.textAlignment = .center
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(aboutLabel)
        contentView.addSubview(appIconImageView)
        contentView.addSubview(versionLabel)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // 滚动视图
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // 内容视图
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // 连接设置
            connectionSettingsLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            connectionSettingsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            serverAddressLabel.topAnchor.constraint(equalTo: connectionSettingsLabel.bottomAnchor, constant: 20),
            serverAddressLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            serverAddressTextField.topAnchor.constraint(equalTo: serverAddressLabel.bottomAnchor, constant: 8),
            serverAddressTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            serverAddressTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            serverAddressTextField.heightAnchor.constraint(equalToConstant: 44),
            
            portLabel.topAnchor.constraint(equalTo: serverAddressTextField.bottomAnchor, constant: 16),
            portLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            portTextField.topAnchor.constraint(equalTo: portLabel.bottomAnchor, constant: 8),
            portTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            portTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            portTextField.heightAnchor.constraint(equalToConstant: 44),
            
            connectionStatusLabel.topAnchor.constraint(equalTo: portTextField.bottomAnchor, constant: 16),
            connectionStatusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            connectionIndicator.centerYAnchor.constraint(equalTo: connectionStatusLabel.centerYAnchor),
            connectionIndicator.leadingAnchor.constraint(equalTo: connectionStatusLabel.trailingAnchor, constant: 8),
            connectionIndicator.widthAnchor.constraint(equalToConstant: 12),
            connectionIndicator.heightAnchor.constraint(equalToConstant: 12),
            
            connectButton.topAnchor.constraint(equalTo: connectionStatusLabel.bottomAnchor, constant: 20),
            connectButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            connectButton.widthAnchor.constraint(equalToConstant: 100),
            connectButton.heightAnchor.constraint(equalToConstant: 44),
            
            disconnectButton.topAnchor.constraint(equalTo: connectButton.topAnchor),
            disconnectButton.leadingAnchor.constraint(equalTo: connectButton.trailingAnchor, constant: 20),
            disconnectButton.widthAnchor.constraint(equalToConstant: 100),
            disconnectButton.heightAnchor.constraint(equalToConstant: 44),
            
            // 设备设置
            deviceSettingsLabel.topAnchor.constraint(equalTo: disconnectButton.bottomAnchor, constant: 40),
            deviceSettingsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            autoReconnectLabel.topAnchor.constraint(equalTo: deviceSettingsLabel.bottomAnchor, constant: 20),
            autoReconnectLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            autoReconnectSwitch.centerYAnchor.constraint(equalTo: autoReconnectLabel.centerYAnchor),
            autoReconnectSwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            reconnectIntervalLabel.topAnchor.constraint(equalTo: autoReconnectLabel.bottomAnchor, constant: 16),
            reconnectIntervalLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            reconnectIntervalTextField.topAnchor.constraint(equalTo: reconnectIntervalLabel.bottomAnchor, constant: 8),
            reconnectIntervalTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            reconnectIntervalTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            reconnectIntervalTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // 关于
            aboutLabel.topAnchor.constraint(equalTo: reconnectIntervalTextField.bottomAnchor, constant: 40),
            aboutLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            appIconImageView.topAnchor.constraint(equalTo: aboutLabel.bottomAnchor, constant: 20),
            appIconImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            appIconImageView.widthAnchor.constraint(equalToConstant: 80),
            appIconImageView.heightAnchor.constraint(equalToConstant: 80),
            
            versionLabel.topAnchor.constraint(equalTo: appIconImageView.bottomAnchor, constant: 16),
            versionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            versionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            versionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
        
        if #available(iOS 11.0, *) {
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        } else {
            scrollView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
            scrollView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor).isActive = true
        }
    }
    
    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Data Loading
    
    private func loadSettings() {
        // 加载保存的设置
        let serverAddress = UserDefaults.standard.string(forKey: "serverAddress") ?? defaultServerAddress
        let port = UserDefaults.standard.string(forKey: "serverPort") ?? defaultPort
        let reconnectInterval = UserDefaults.standard.string(forKey: "reconnectInterval") ?? defaultReconnectInterval
        let autoReconnect = UserDefaults.standard.bool(forKey: "autoReconnect")
        
        serverAddressTextField.text = serverAddress
        portTextField.text = port
        reconnectIntervalTextField.text = reconnectInterval
        autoReconnectSwitch.isOn = autoReconnect
        
        updateConnectionStatus()
    }
    
    private func saveSettings() {
        // 保存设置
        UserDefaults.standard.set(serverAddressTextField.text, forKey: "serverAddress")
        UserDefaults.standard.set(portTextField.text, forKey: "serverPort")
        UserDefaults.standard.set(reconnectIntervalTextField.text, forKey: "reconnectInterval")
        UserDefaults.standard.set(autoReconnectSwitch.isOn, forKey: "autoReconnect")
    }
    
    private func updateConnectionStatus() {
        let isConnected = TCPConnectionManager.shared.isConnected
        
        if isConnected {
            connectionStatusLabel.text = "连接状态: 已连接"
            connectionIndicator.backgroundColor = UIColor(red: 52.0/255.0, green: 199.0/255.0, blue: 89.0/255.0, alpha: 1.0)
            connectButton.isEnabled = false
            disconnectButton.isEnabled = true
        } else {
            connectionStatusLabel.text = "连接状态: 未连接"
            connectionIndicator.backgroundColor = .red
            connectButton.isEnabled = true
            disconnectButton.isEnabled = false
        }
    }
    
    // MARK: - Button Actions
    
    @objc private func connectButtonTapped() {
        guard let serverAddress = serverAddressTextField.text, !serverAddress.isEmpty,
              let portText = portTextField.text, let port = Int(portText) else {
            showAlert(title: "错误", message: "请输入有效的服务器地址和端口号")
            return
        }
        
        saveSettings()
        
        // 建立TCP连接
        TCPConnectionManager.shared.setupConnection(host: serverAddress, port: port)
        
        showAlert(title: "连接", message: "正在连接到服务器...")
    }
    
    @objc private func disconnectButtonTapped() {
        TCPConnectionManager.shared.disconnect()
        updateConnectionStatus()
        showAlert(title: "断开连接", message: "已断开与服务器的连接")
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func keyboardWillShow(notification: Notification) {
        guard let value = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardFrame = value.cgRectValue
        
        let keyboardHeight = keyboardFrame.height
        scrollView.contentInset.bottom = keyboardHeight
        scrollView.scrollIndicatorInsets.bottom = keyboardHeight
    }
    
    @objc private func keyboardWillHide(notification: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.scrollIndicatorInsets.bottom = 0
    }
    
    // MARK: - Helper Methods
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate

extension SettingsViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == serverAddressTextField {
            portTextField.becomeFirstResponder()
        } else if textField == portTextField {
            reconnectIntervalTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        saveSettings()
    }
}
