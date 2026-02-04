//
//  DeviceManager.swift
//  WuhanWaterConservationControlSystem
//
//  Created by SOLO Builder on 2025/12/23.
//  Copyright © 2025 WuhanWaterConservation. All rights reserved.
//

import Foundation

enum DeviceType: String, CaseIterable {
    case lighting = "lighting"
    case computer = "computer"
    case projector = "projector"
    case exhibitPower = "exhibit_power"
}

enum DeviceStatus: String {
    case online = "online"
    case offline = "offline"
    case error = "error"
    case unknown = "unknown"
}

enum ControlAction: String {
    case turnOn = "on"
    case turnOff = "off"
    case toggle = "toggle"
    case allOn = "all_on"
    case allOff = "all_off"
}

struct Device {
    let id: String
    let name: String
    let type: DeviceType
    var status: DeviceStatus
    var isOn: Bool
    var lastUpdate: Date
    
    init(id: String, name: String, type: DeviceType, status: DeviceStatus = .unknown, isOn: Bool = false) {
        self.id = id
        self.name = name
        self.type = type
        self.status = status
        self.isOn = isOn
        self.lastUpdate = Date()
    }
}

protocol DeviceManagerDelegate: AnyObject {
    func deviceManager(_ manager: DeviceManager, didUpdateDevice device: Device)
    func deviceManager(_ manager: DeviceManager, didFailWithError error: Error)
    func deviceManager(_ manager: DeviceManager, didReceiveStatus status: [String: Any])
}

class DeviceManager: NSObject {
    
    // MARK: - Properties
    
    static let shared = DeviceManager()
    
    weak var delegate: DeviceManagerDelegate?
    
    private var devices: [String: Device] = [:]
    private var deviceGroups: [DeviceType: [String]] = [:]
    
    private let statusUpdateInterval: TimeInterval = 5.0
    private var statusUpdateTimer: Timer?
    
    // 预设设备配置
    private let defaultDevices: [Device] = [
        // 灯光设备
        Device(id: "light_001", name: "主展厅灯光", type: .lighting),
        Device(id: "light_002", name: "互动区灯光", type: .lighting),
        Device(id: "light_003", name: "演示区灯光", type: .lighting),
        Device(id: "light_004", name: "走廊灯光", type: .lighting),
        
        // 电脑设备
        Device(id: "computer_001", name: "主控电脑", type: .computer),
        Device(id: "computer_002", name: "展示电脑1", type: .computer),
        Device(id: "computer_003", name: "展示电脑2", type: .computer),
        Device(id: "computer_004", name: "演示电脑", type: .computer),
        
        // 投影仪设备
        Device(id: "projector_001", name: "主展厅投影仪", type: .projector),
        Device(id: "projector_002", name: "互动区投影仪", type: .projector),
        Device(id: "projector_003", name: "演示区投影仪", type: .projector),
        
        // 展品电源
        Device(id: "exhibit_001", name: "节水演示展品", type: .exhibitPower),
        Device(id: "exhibit_002", name: "互动体验展品", type: .exhibitPower),
        Device(id: "exhibit_003", name: "科普展示展品", type: .exhibitPower),
        Device(id: "exhibit_004", name: "实验设备展品", type: .exhibitPower)
    ]
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupDefaultDevices()
        setupTCPConnection()
        startStatusUpdates()
    }
    
    deinit {
        stopStatusUpdates()
    }
    
    // MARK: - Public Methods
    
    func getDevice(byId deviceId: String) -> Device? {
        return devices[deviceId]
    }
    
    func getAllDevices() -> [Device] {
        return Array(devices.values)
    }
    
    func getDevices(byType type: DeviceType) -> [Device] {
        guard let deviceIds = deviceGroups[type] else { return [] }
        return deviceIds.compactMap { devices[$0] }
    }
    
    func controlDevice(_ deviceId: String, action: ControlAction, completion: ((Bool, Error?) -> Void)? = nil) {
        guard let device = devices[deviceId] else {
            let error = NSError(domain: "DeviceManagerError", code: -1, userInfo: [NSLocalizedDescriptionKey: "设备未找到"])
            DispatchQueue.main.async {
                completion?(false, error)
                self.delegate?.deviceManager(self, didFailWithError: error)
            }
            return
        }
        
        // 构建控制命令
        let command = buildControlCommand(device: device, action: action)
        
        // 发送TCP命令
        TCPConnectionManager.shared.sendHexCommand(command) { [weak self] success, error in
            guard let self = self else { return }
            if success {
                self.updateDeviceStatus(deviceId: deviceId, action: action)
                DispatchQueue.main.async {
                    completion?(true, nil)
                }
            } else {
                DispatchQueue.main.async {
                    completion?(false, error)
                    if let error = error {
                        self.delegate?.deviceManager(self, didFailWithError: error)
                    }
                }
            }
        }
    }
    
    func controlAllDevices(ofType type: DeviceType, action: ControlAction, completion: ((Bool, Error?) -> Void)? = nil) {
        let devicesOfType = getDevices(byType: type)
        
        guard !devicesOfType.isEmpty else {
            let error = NSError(domain: "DeviceManagerError", code: -2, userInfo: [NSLocalizedDescriptionKey: "该类型设备不存在"])
            DispatchQueue.main.async {
                completion?(false, error)
                self.delegate?.deviceManager(self, didFailWithError: error)
            }
            return
        }
        
        // 批量控制命令
        let command = buildBatchControlCommand(devices: devicesOfType, action: action)
        
        TCPConnectionManager.shared.sendHexCommand(command) { [weak self] success, error in
            guard let self = self else { return }
            if success {
                for device in devicesOfType {
                    self.updateDeviceStatus(deviceId: device.id, action: action)
                }
                DispatchQueue.main.async {
                    completion?(true, nil)
                }
            } else {
                DispatchQueue.main.async {
                    completion?(false, error)
                    if let error = error {
                        self.delegate?.deviceManager(self, didFailWithError: error)
                    }
                }
            }
        }
    }
    
    func refreshDeviceStatus(completion: ((Bool) -> Void)? = nil) {
        let statusCommand = buildStatusCommand()
        
        TCPConnectionManager.shared.sendHexCommand(statusCommand) { [weak self] success, error in
            guard let self = self else { return }
            if success {
                DispatchQueue.main.async {
                    completion?(true)
                }
            } else {
                DispatchQueue.main.async {
                    completion?(false)
                    if let error = error {
                        self.delegate?.deviceManager(self, didFailWithError: error)
                    }
                }
            }
        }
    }
    
    func clearTemporaryData() {
        // 清理临时数据，用于内存管理
        // 这里可以添加具体的清理逻辑
    }
    
    // MARK: - Private Methods
    
    private func setupDefaultDevices() {
        for device in defaultDevices {
            devices[device.id] = device
            
            // 按类型分组
            if deviceGroups[device.type] == nil {
                deviceGroups[device.type] = []
            }
            deviceGroups[device.type]?.append(device.id)
        }
        
        print("Device Manager: Initialized \(devices.count) devices")
    }
    
    private func setupTCPConnection() {
        // 设置TCP连接回调
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTCPConnectionStatus),
            name: Notification.Name("TCPConnectionStatusChanged"),
            object: nil
        )
    }
    
    private func startStatusUpdates() {
        stopStatusUpdates()
        DispatchQueue.main.async { [weak self] in
            self?.statusUpdateTimer = Timer.scheduledTimer(withTimeInterval: self?.statusUpdateInterval ?? 5.0, repeats: true) { [weak self] _ in
                self?.refreshDeviceStatus()
            }
        }
    }
    
    private func stopStatusUpdates() {
        statusUpdateTimer?.invalidate()
        statusUpdateTimer = nil
    }
    
    private func buildControlCommand(device: Device, action: ControlAction) -> String {
        // 构建HEX格式的控制命令
        // 格式: [起始符][设备ID][命令类型][参数][校验和][结束符]
        
        let deviceIdHex = String(format: "%04X", Int(device.id.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)) ?? 0)
        let commandType = getCommandTypeHex(action: action)
        let parameters = getCommandParameters(device: device, action: action)
        
        let command = "AA\(deviceIdHex)\(commandType)\(parameters)55"
        
        // 计算校验和
        let checksum = calculateChecksum(command: command)
        
        return command + checksum
    }
    
    private func buildBatchControlCommand(devices: [Device], action: ControlAction) -> String {
        // 构建批量控制命令
        let deviceIdsHex = devices.map { device in
            String(format: "%04X", Int(device.id.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)) ?? 0)
        }.joined()
        
        let commandType = getCommandTypeHex(action: action)
        let command = "BB\(deviceIdsHex)\(commandType)55"
        let checksum = calculateChecksum(command: command)
        
        return command + checksum
    }
    
    private func buildStatusCommand() -> String {
        // 构建状态查询命令
        return "CC000000000055" + calculateChecksum(command: "CC000000000055")
    }
    
    private func getCommandTypeHex(action: ControlAction) -> String {
        switch action {
        case .turnOn:
            return "01"
        case .turnOff:
            return "02"
        case .toggle:
            return "03"
        case .allOn:
            return "04"
        case .allOff:
            return "05"
        }
    }
    
    private func getCommandParameters(device: Device, action: ControlAction) -> String {
        // 根据设备和动作生成参数
        switch device.type {
        case .lighting:
            return action == .turnOn ? "64" : "00" // 亮度: 100% 或 0%
        case .computer:
            return "00" // 电脑开关无特殊参数
        case .projector:
            return "00" // 投影仪开关无特殊参数
        case .exhibitPower:
            return "00" // 展品电源无特殊参数
        }
    }
    
    private func calculateChecksum(command: String) -> String {
        // 简单的校验和计算
        let bytes = Array(command.utf8)
        let sum = bytes.reduce(0) { $0 + Int($1) }
        return String(format: "%02X", sum % 256)
    }
    
    private func updateDeviceStatus(deviceId: String, action: ControlAction) {
        guard var device = devices[deviceId] else { return }
        
        // 根据动作更新设备状态
        switch action {
        case .turnOn:
            device.isOn = true
            device.status = .online
        case .turnOff:
            device.isOn = false
            device.status = .online
        case .toggle:
            device.isOn = !device.isOn
            device.status = .online
        case .allOn:
            device.isOn = true
            device.status = .online
        case .allOff:
            device.isOn = false
            device.status = .online
        }
        
        device.lastUpdate = Date()
        devices[deviceId] = device
        
        DispatchQueue.main.async {
            self.delegate?.deviceManager(self, didUpdateDevice: device)
        }
    }
    
    @objc private func handleTCPConnectionStatus(_ notification: Notification) {
        // 处理TCP连接状态变化
        if let isConnected = notification.userInfo?["isConnected"] as? Bool {
            if !isConnected {
                // 连接断开，标记所有设备为离线状态
                for (deviceId, var device) in devices {
                    device.status = .offline
                    devices[deviceId] = device
                    DispatchQueue.main.async {
                        self.delegate?.deviceManager(self, didUpdateDevice: device)
                    }
                }
            }
        }
    }
}

// MARK: - TCPConnectionManagerDelegate

extension DeviceManager: TCPConnectionManagerDelegate {
    
    func tcpConnectionDidConnect() {
        print("Device Manager: TCP connection established")
        refreshDeviceStatus()
    }
    
    func tcpConnectionDidDisconnect(error: Error?) {
        print("Device Manager: TCP connection disconnected - \(error?.localizedDescription ?? "unknown error")")
        
        // 标记所有设备为离线状态
        for (deviceId, var device) in devices {
            device.status = .offline
            devices[deviceId] = device
            DispatchQueue.main.async {
                self.delegate?.deviceManager(self, didUpdateDevice: device)
            }
        }
    }
    
    func tcpConnectionDidReceiveData(_ data: Data) {
        // 解析接收到的数据并更新设备状态
        parseReceivedData(data)
    }
    
    func tcpConnectionDidFailToConnect(error: Error) {
        print("Device Manager: TCP connection failed - \(error.localizedDescription)")
        delegate?.deviceManager(self, didFailWithError: error)
    }
    
    private func parseReceivedData(_ data: Data) {
        // 简单的数据解析逻辑
        // 实际应用中需要根据具体的协议格式进行解析
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("Device Manager: Received response - \(responseString)")
            
            // 这里添加具体的状态解析逻辑
            // 例如解析设备状态、确认命令执行结果等
            
            let status: [String: Any] = [
                "timestamp": Date().timeIntervalSince1970,
                "response": responseString
            ]
            
            DispatchQueue.main.async {
                self.delegate?.deviceManager(self, didReceiveStatus: status)
            }
        }
    }
}
