//
//  TCPConnectionManagerTests.swift
//  WuhanWaterConservationControlSystemTests
//
//  Created by SOLO Builder on 2025/12/23.
//  Copyright © 2025 WuhanWaterConservation. All rights reserved.
//

import XCTest
@testable import WuhanWaterConservationControlSystem

class TCPConnectionManagerTests: XCTestCase {
    
    var connectionManager: TCPConnectionManager!
    var mockDelegate: MockTCPConnectionDelegate!
    
    override func setUp() {
        super.setUp()
        connectionManager = TCPConnectionManager.shared
        mockDelegate = MockTCPConnectionDelegate()
        connectionManager.delegate = mockDelegate
    }
    
    override func tearDown() {
        connectionManager.disconnect()
        connectionManager.delegate = nil
        super.tearDown()
    }
    
    // MARK: - Connection Tests
    
    func testConnectionEstablishment() {
        let expectation = self.expectation(description: "Connection established")
        
        mockDelegate.onConnect = {
            expectation.fulfill()
        }
        
        connectionManager.setupConnection(host: "127.0.0.1", port: 8080)
        
        waitForExpectations(timeout: 10, handler: nil)
        XCTAssertTrue(mockDelegate.isConnected)
    }
    
    func testConnectionFailure() {
        let expectation = self.expectation(description: "Connection failed")
        
        mockDelegate.onFailToConnect = { error in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }
        
        // 使用无效的地址测试连接失败
        connectionManager.setupConnection(host: "invalid.address", port: 9999)
        
        waitForExpectations(timeout: 15, handler: nil)
        XCTAssertFalse(mockDelegate.isConnected)
    }
    
    func testDisconnection() {
        let connectExpectation = self.expectation(description: "Connected")
        let disconnectExpectation = self.expectation(description: "Disconnected")
        
        mockDelegate.onConnect = {
            connectExpectation.fulfill()
        }
        
        mockDelegate.onDisconnect = { error in
            disconnectExpectation.fulfill()
        }
        
        // 先建立连接
        connectionManager.setupConnection(host: "127.0.0.1", port: 8080)
        wait(for: [connectExpectation], timeout: 10)
        
        // 然后断开连接
        connectionManager.disconnect()
        wait(for: [disconnectExpectation], timeout: 5)
        
        XCTAssertFalse(mockDelegate.isConnected)
    }
    
    // MARK: - Data Transmission Tests
    
    func testCommandSending() {
        let connectExpectation = self.expectation(description: "Connected")
        let sendExpectation = self.expectation(description: "Data sent")
        
        mockDelegate.onConnect = {
            connectExpectation.fulfill()
        }
        
        mockDelegate.onReceiveData = { data in
            XCTAssertGreaterThan(data.count, 0)
            sendExpectation.fulfill()
        }
        
        connectionManager.setupConnection(host: "127.0.0.1", port: 8080)
        wait(for: [connectExpectation], timeout: 10)
        
        // 发送测试命令
        connectionManager.sendCommand("TEST_COMMAND")
        wait(for: [sendExpectation], timeout: 5)
    }
    
    func testHexCommandSending() {
        let connectExpectation = self.expectation(description: "Connected")
        let sendExpectation = self.expectation(description: "Hex data sent")
        
        mockDelegate.onConnect = {
            connectExpectation.fulfill()
        }
        
        mockDelegate.onReceiveData = { data in
            XCTAssertGreaterThan(data.count, 0)
            sendExpectation.fulfill()
        }
        
        connectionManager.setupConnection(host: "127.0.0.1", port: 8080)
        wait(for: [connectExpectation], timeout: 10)
        
        // 发送HEX命令
        connectionManager.sendHexCommand("AA01020304BB")
        wait(for: [sendExpectation], timeout: 5)
    }
    
    // MARK: - Reconnection Tests
    
    func testAutoReconnection() {
        let connectExpectation = self.expectation(description: "Initial connection")
        let reconnectExpectation = self.expectation(description: "Reconnected")
        
        var connectionCount = 0
        
        mockDelegate.onConnect = {
            connectionCount += 1
            if connectionCount == 1 {
                connectExpectation.fulfill()
            } else if connectionCount == 2 {
                reconnectExpectation.fulfill()
            }
        }
        
        // 建立初始连接
        connectionManager.setupConnection(host: "127.0.0.1", port: 8080)
        wait(for: [connectExpectation], timeout: 10)
        
        // 模拟连接断开
        connectionManager.disconnect()
        
        // 等待重连
        wait(for: [reconnectExpectation], timeout: 30)
        XCTAssertGreaterThanOrEqual(connectionCount, 2)
    }
    
    func testMaxReconnectionAttempts() {
        let failExpectation = self.expectation(description: "Max reconnection attempts reached")
        
        mockDelegate.onFailToConnect = { error in
            if let nsError = error as NSError? {
                if nsError.code == -2 { // Max reconnection attempts
                    failExpectation.fulfill()
                }
            }
        }
        
        // 使用无效地址触发重连失败
        connectionManager.setupConnection(host: "invalid.address.test", port: 9999)
        
        wait(for: [failExpectation], timeout: 60)
    }
    
    // MARK: - Heartbeat Tests
    
    func testHeartbeatMechanism() {
        let connectExpectation = self.expectation(description: "Connected")
        let heartbeatExpectation = self.expectation(description: "Heartbeat sent")
        
        var heartbeatCount = 0
        
        mockDelegate.onConnect = {
            connectExpectation.fulfill()
        }
        
        mockDelegate.onReceiveData = { data in
            if let response = String(data: data, encoding: .utf8),
               response.contains("PONG") {
                heartbeatCount += 1
                if heartbeatCount >= 2 {
                    heartbeatExpectation.fulfill()
                }
            }
        }
        
        connectionManager.setupConnection(host: "127.0.0.1", port: 8080)
        wait(for: [connectExpectation], timeout: 10)
        
        // 启动心跳
        connectionManager.startHeartbeat()
        
        // 等待心跳响应
        wait(for: [heartbeatExpectation], timeout: 70)
        XCTAssertGreaterThanOrEqual(heartbeatCount, 2)
    }
    
    // MARK: - Performance Tests
    
    func testConnectionPerformance() {
        measure {
            let expectation = self.expectation(description: "Connection performance")
            
            connectionManager.setupConnection(host: "127.0.0.1", port: 8080)
            
            mockDelegate.onConnect = {
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10)
            connectionManager.disconnect()
        }
    }
    
    func testDataTransmissionPerformance() {
        let connectExpectation = self.expectation(description: "Connected")
        
        mockDelegate.onConnect = {
            connectExpectation.fulfill()
        }
        
        connectionManager.setupConnection(host: "127.0.0.1", port: 8080)
        wait(for: [connectExpectation], timeout: 10)
        
        measure {
            for _ in 0..<100 {
                connectionManager.sendCommand("PERFORMANCE_TEST_COMMAND")
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testNetworkErrorHandling() {
        let errorExpectation = self.expectation(description: "Network error handled")
        
        mockDelegate.onDisconnect = { error in
            XCTAssertNotNil(error)
            errorExpectation.fulfill()
        }
        
        // 模拟网络错误
        connectionManager.setupConnection(host: "192.168.255.255", port: 8080)
        
        wait(for: [errorExpectation], timeout: 20)
    }
    
    func testInvalidHexCommandHandling() {
        let connectExpectation = self.expectation(description: "Connected")
        
        mockDelegate.onConnect = {
            connectExpectation.fulfill()
        }
        
        connectionManager.setupConnection(host: "127.0.0.1", port: 8080)
        wait(for: [connectExpectation], timeout: 10)
        
        // 测试无效的HEX命令
        connectionManager.sendHexCommand("INVALID_HEX")
        
        // 应该能正常处理，不会崩溃
        XCTAssertTrue(true)
    }
}

// MARK: - Mock Delegate

class MockTCPConnectionDelegate: TCPConnectionManagerDelegate {
    
    var isConnected = false
    var onConnect: (() -> Void)?
    var onDisconnect: ((Error?) -> Void)?
    var onReceiveData: ((Data) -> Void)?
    var onFailToConnect: ((Error) -> Void)?
    
    func tcpConnectionDidConnect() {
        isConnected = true
        onConnect?()
    }
    
    func tcpConnectionDidDisconnect(error: Error?) {
        isConnected = false
        onDisconnect?(error)
    }
    
    func tcpConnectionDidReceiveData(_ data: Data) {
        onReceiveData?(data)
    }
    
    func tcpConnectionDidFailToConnect(error: Error) {
        isConnected = false
        onFailToConnect?(error)
    }
}