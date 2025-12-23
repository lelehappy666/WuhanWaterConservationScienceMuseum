//
//  TCPConnectionManager.swift
//  WuhanWaterConservationControlSystem
//
//  Created by SOLO Builder on 2025/12/23.
//  Copyright © 2025 WuhanWaterConservation. All rights reserved.
//

import Foundation
import UIKit

protocol TCPConnectionManagerDelegate: AnyObject {
    func tcpConnectionDidConnect()
    func tcpConnectionDidDisconnect(error: Error?)
    func tcpConnectionDidReceiveData(_ data: Data)
    func tcpConnectionDidFailToConnect(error: Error)
}

class TCPConnectionManager: NSObject {
    
    // MARK: - Properties
    
    static let shared = TCPConnectionManager()
    
    weak var delegate: TCPConnectionManagerDelegate?
    
    private var host: String = ""
    private var port: Int = 8080
    private var inputStream: InputStream?
    private var outputStream: OutputStream?
    
    private(set) var isConnected: Bool = false
    private var isConnecting: Bool = false
    
    private var heartbeatTimer: Timer?
    private var reconnectTimer: Timer?
    private var reconnectAttempts: Int = 0
    private let maxReconnectAttempts: Int = 5
    private let reconnectDelay: TimeInterval = 5.0
    private let heartbeatInterval: TimeInterval = 30.0
    
    private let connectionQueue = DispatchQueue(label: "com.wuhanwaterconservation.tcpconnection")
    private let dataQueue = DispatchQueue(label: "com.wuhanwaterconservation.tcpdata")
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupNetworkReachability()
    }
    
    deinit {
        disconnect()
        stopHeartbeat()
        stopReconnectTimer()
    }
    
    // MARK: - Public Methods
    
    func setupConnection(host: String = "192.168.200.31", port: Int = 6001) {
        self.host = host
        self.port = port
        connect()
    }
    
    func connect() {
        guard !isConnected && !isConnecting else {
            print("TCP Connection: Already connected or connecting")
            return
        }
        
        isConnecting = true
        print("TCP Connection: Attempting to connect to \(host):\(port)")
        
        connectionQueue.async { [weak self] in
            self?.establishConnection()
        }
    }
    
    func disconnect() {
        print("TCP Connection: Disconnecting")
        
        isConnected = false
        isConnecting = false
        reconnectAttempts = 0
        
        stopHeartbeat()
        
        connectionQueue.async { [weak self] in
            self?.closeStreams()
        }
    }
    
    func sendCommand(_ command: String) {
        guard isConnected, let data = command.data(using: .utf8) else {
            print("TCP Connection: Cannot send command - not connected")
            return
        }
        
        sendData(data)
    }
    
    func sendHexCommand(_ hexString: String) {
        guard isConnected else {
            print("TCP Connection: Cannot send hex command - not connected")
            return
        }
        
        let hexData = hexString.hexadecimalData()
        sendData(hexData)
    }
    
    func checkConnectionStatus() {
        if !isConnected {
            print("TCP Connection: Connection lost, attempting to reconnect")
            attemptReconnection()
        }
    }
    
    func maintainConnectionInBackground() {
        // 在后台维持连接的心跳
        guard UIApplication.shared.applicationState == .background else {
            return
        }
        
        if isConnected {
            sendHeartbeat()
        } else {
            attemptReconnection()
        }
    }
    
    func startHeartbeat() {
        stopHeartbeat()
        
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: heartbeatInterval, repeats: true) { [weak self] _ in
            self?.sendHeartbeat()
        }
    }
    
    // MARK: - Private Methods
    
    private func establishConnection() {
        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?
        
        // 创建TCP连接
        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault,
                                         host as CFString,
                                         UInt32(port),
                                         &readStream,
                                         &writeStream)
        
        guard let readStreamRef = readStream?.takeRetainedValue(),
              let writeStreamRef = writeStream?.takeRetainedValue() else {
            let error = NSError(domain: "TCPConnectionError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create streams"])
            handleConnectionError(error)
            return
        }
        
        inputStream = readStreamRef
        outputStream = writeStreamRef
        
        // 设置代理
        inputStream?.delegate = self
        outputStream?.delegate = self
        
        // 调度到主线程
        inputStream?.schedule(in: .current, forMode: .common)
        outputStream?.schedule(in: .current, forMode: .common)
        
        // 打开流
        inputStream?.open()
        outputStream?.open()
        
        // 开始运行循环
        RunLoop.current.run()
    }
    
    private func closeStreams() {
        inputStream?.close()
        outputStream?.close()
        
        inputStream?.remove(from: .current, forMode: .common)
        outputStream?.remove(from: .current, forMode: .common)
        
        inputStream = nil
        outputStream = nil
        
        CFRunLoopStop(CFRunLoopGetCurrent())
    }
    
    private func sendData(_ data: Data) {
        guard let outputStream = outputStream, outputStream.hasSpaceAvailable else {
            print("TCP Connection: Output stream not available")
            return
        }
        
        dataQueue.async { [weak self] in
            let bytesWritten = data.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) -> Int in
                guard let base = buffer.bindMemory(to: UInt8.self).baseAddress else {
                    return -1
                }
                return outputStream.write(base, maxLength: data.count)
            }
            
            if bytesWritten < 0 {
                if let error = outputStream.streamError {
                    print("TCP Connection: Write error - \(error.localizedDescription)")
                    self?.handleConnectionError(error)
                }
            } else {
                print("TCP Connection: Sent \(bytesWritten) bytes")
            }
        }
    }
    
    private func sendHeartbeat() {
        let heartbeatCommand = "PING"
        sendCommand(heartbeatCommand)
        print("TCP Connection: Heartbeat sent")
    }
    
    private func attemptReconnection() {
        guard reconnectAttempts < maxReconnectAttempts else {
            print("TCP Connection: Max reconnection attempts reached")
            delegate?.tcpConnectionDidDisconnect(error: NSError(domain: "TCPConnectionError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Max reconnection attempts reached"]))
            return
        }
        
        reconnectAttempts += 1
        print("TCP Connection: Attempting reconnection \(reconnectAttempts)/\(maxReconnectAttempts)")
        
        stopReconnectTimer()
        
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: reconnectDelay, repeats: false) { [weak self] _ in
            self?.connect()
        }
    }
    
    private func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }
    
    private func stopReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
    
    private func handleConnectionSuccess() {
        print("TCP Connection: Connected successfully")
        isConnected = true
        isConnecting = false
        reconnectAttempts = 0
        
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.tcpConnectionDidConnect()
        }
        
        startHeartbeat()
    }
    
    private func handleConnectionError(_ error: Error) {
        print("TCP Connection: Connection error - \(error.localizedDescription)")
        isConnected = false
        isConnecting = false
        
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.tcpConnectionDidFailToConnect(error: error)
        }
        
        // 尝试重连
        attemptReconnection()
    }
    
    private func handleDisconnection(error: Error?) {
        print("TCP Connection: Disconnected with error: \(error?.localizedDescription ?? "none")")
        isConnected = false
        isConnecting = false
        
        stopHeartbeat()
        
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.tcpConnectionDidDisconnect(error: error)
        }
        
        // 尝试重连
        if error != nil {
            attemptReconnection()
        }
    }
    
    private func setupNetworkReachability() {
        // 网络可达性检测
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(networkStatusChanged),
                                              name: UIApplication.didBecomeActiveNotification,
                                              object: nil)
    }
    
    @objc private func networkStatusChanged() {
        if !isConnected {
            print("TCP Connection: Network status changed, attempting reconnection")
            attemptReconnection()
        }
    }
}

// MARK: - Stream Delegate

extension TCPConnectionManager: StreamDelegate {
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case Stream.Event.hasBytesAvailable:
            if aStream == inputStream {
                readAvailableBytes()
            }
            
        case Stream.Event.hasSpaceAvailable:
            print("TCP Connection: Has space available")
            
        case Stream.Event.openCompleted:
            if aStream == outputStream {
                handleConnectionSuccess()
            }
            
        case Stream.Event.errorOccurred:
            if let error = aStream.streamError {
                handleConnectionError(error)
            }
            
        case Stream.Event.endEncountered:
            handleDisconnection(error: aStream.streamError)
            
        default:
            break
        }
    }
    
    private func readAvailableBytes() {
        guard let inputStream = inputStream else { return }
        
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        
        let bytesRead = inputStream.read(buffer, maxLength: bufferSize)
        
        if bytesRead > 0 {
            let data = Data(bytes: buffer, count: bytesRead)
            print("TCP Connection: Received \(bytesRead) bytes")
            
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.tcpConnectionDidReceiveData(data)
            }
        } else if bytesRead < 0 {
            if let error = inputStream.streamError {
                handleConnectionError(error)
            }
        }
    }
}

// MARK: - String Extension for Hex

extension String {
    func hexadecimalData() -> Data {
        var data = Data()
        var hex = self
        
        // 移除空格和特殊字符
        hex = hex.replacingOccurrences(of: " ", with: "")
        hex = hex.replacingOccurrences(of: "0x", with: "")
        
        var index = hex.startIndex
        while index < hex.endIndex {
            let nextIndex = hex.index(index, offsetBy: 2, limitedBy: hex.endIndex) ?? hex.endIndex
            let byteString = hex[index..<nextIndex]
            if let num = UInt8(String(byteString), radix: 16) {
                data.append(num)
            }
            index = nextIndex
        }
        
        return data
    }
}

extension TCPConnectionManager {
    func sendHexCommand(_ hexString: String, completion: ((Bool, Error?) -> Void)?) {
        print("TCP Connection: Sending HEX - \(hexString)")
        guard isConnected else {
            let err = NSError(domain: "TCPConnectionError",
                              code: -3,
                              userInfo: [NSLocalizedDescriptionKey: "Not connected"])
            DispatchQueue.main.async {
                completion?(false, err)
            }
            return
        }
        let hexData = hexString.hexadecimalData()
        guard let outputStream = outputStream, outputStream.hasSpaceAvailable else {
            let err = NSError(domain: "TCPConnectionError",
                              code: -4,
                              userInfo: [NSLocalizedDescriptionKey: "Output stream not available"])
            DispatchQueue.main.async {
                completion?(false, err)
            }
            return
        }
        dataQueue.async { [weak self] in
            let bytesWritten = hexData.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) -> Int in
                guard let base = buffer.bindMemory(to: UInt8.self).baseAddress else { return -1 }
                return outputStream.write(base, maxLength: hexData.count)
            }
            if bytesWritten < 0 {
                let error = outputStream.streamError ?? NSError(domain: "TCPConnectionError",
                                                                code: -5,
                                                                userInfo: [NSLocalizedDescriptionKey: "Unknown write error"])
                DispatchQueue.main.async {
                    completion?(false, error)
                }
                self?.handleConnectionError(error)
            } else {
                DispatchQueue.main.async {
                    completion?(true, nil)
                }
            }
        }
    }
}
