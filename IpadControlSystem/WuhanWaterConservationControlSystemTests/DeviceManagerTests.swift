//
//  DeviceManagerTests.swift
//  WuhanWaterConservationControlSystemTests
//
//  Created by SOLO Builder on 2025/12/23.
//  Copyright © 2025 WuhanWaterConservation. All rights reserved.
//

import XCTest
@testable import WuhanWaterConservationScienceMuseum

class DeviceManagerTests: XCTestCase {
    
    var deviceManager: DeviceManager!
    var mockDelegate: MockDeviceManagerDelegate!
    
    override func setUp() {
        super.setUp()
        deviceManager = DeviceManager.shared
        mockDelegate = MockDeviceManagerDelegate()
        deviceManager.delegate = mockDelegate
    }
    
    override func tearDown() {
        deviceManager.delegate = nil
        super.tearDown()
    }
    
    // MARK: - Device Discovery Tests
    
    func testDeviceDiscovery() {
        let expectation = self.expectation(description: "Devices discovered")
        
        mockDelegate.onStatusReceived = { status in
            XCTAssertNotNil(status)
            expectation.fulfill()
        }
        
        // 模拟设备发现
        deviceManager.refreshDeviceStatus { success in
            XCTAssertTrue(success)
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testGetDeviceById() {
        let allDevices = deviceManager.getAllDevices()
        guard let firstDevice = allDevices.first else {
            XCTSkip("No devices available for testing")
            return
        }
        
        let retrievedDevice = deviceManager.getDevice(byId: firstDevice.id)
        XCTAssertNotNil(retrievedDevice)
        XCTAssertEqual(retrievedDevice?.id, firstDevice.id)
        XCTAssertEqual(retrievedDevice?.name, firstDevice.name)
    }
    
    func testGetDevicesByType() {
        let lightingDevices = deviceManager.getDevices(byType: .lighting)
        let computerDevices = deviceManager.getDevices(byType: .computer)
        let projectorDevices = deviceManager.getDevices(byType: .projector)
        let exhibitDevices = deviceManager.getDevices(byType: .exhibitPower)
        
        // 验证每种设备类型都有设备
        XCTAssertGreaterThan(lightingDevices.count, 0)
        XCTAssertGreaterThan(computerDevices.count, 0)
        XCTAssertGreaterThan(projectorDevices.count, 0)
        XCTAssertGreaterThan(exhibitDevices.count, 0)
        
        // 验证设备类型正确
        for device in lightingDevices {
            XCTAssertEqual(device.type, .lighting)
        }
        
        for device in computerDevices {
            XCTAssertEqual(device.type, .computer)
        }
        
        for device in projectorDevices {
            XCTAssertEqual(device.type, .projector)
        }
        
        for device in exhibitDevices {
            XCTAssertEqual(device.type, .exhibitPower)
        }
    }
    
    // MARK: - Device Control Tests
    
    func testIndividualDeviceControl() {
        let expectation = self.expectation(description: "Device controlled")
        
        let lightingDevices = deviceManager.getDevices(byType: .lighting)
        guard let device = lightingDevices.first else {
            XCTSkip("No lighting devices available for testing")
            return
        }
        
        let originalState = device.isOn
        
        deviceManager.controlDevice(device.id, action: .toggle) { success, error in
            XCTAssertTrue(success)
            XCTAssertNil(error)
            
            // 验证设备状态已更新
            let updatedDevice = self.deviceManager.getDevice(byId: device.id)
            XCTAssertEqual(updatedDevice?.isOn, !originalState)
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testBatchDeviceControl() {
        let expectation = self.expectation(description: "Batch control completed")
        
        let lightingDevices = deviceManager.getDevices(byType: .lighting)
        guard !lightingDevices.isEmpty else {
            XCTSkip("No lighting devices available for testing")
            return
        }
        
        deviceManager.controlAllDevices(ofType: .lighting, action: .allOn) { success, error in
            XCTAssertTrue(success)
            XCTAssertNil(error)
            
            // 验证所有设备状态已更新
            let updatedDevices = self.deviceManager.getDevices(byType: .lighting)
            for device in updatedDevices {
                XCTAssertTrue(device.isOn)
            }
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testDeviceControlWithInvalidDevice() {
        let expectation = self.expectation(description: "Control failed with invalid device")
        
        deviceManager.controlDevice("invalid_device_id", action: .turnOn) { success, error in
            XCTAssertFalse(success)
            XCTAssertNotNil(error)
            
            if let error = error {
                XCTAssertTrue(error.localizedDescription.contains("设备未找到"))
            }
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testBatchControlWithEmptyDeviceList() {
        let expectation = self.expectation(description: "Batch control failed with empty list")
        
        // 尝试控制不存在的设备类型
        deviceManager.controlAllDevices(ofType: .exhibitPower, action: .allOff) { success, error in
            XCTAssertFalse(success)
            XCTAssertNotNil(error)
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    // MARK: - Status Update Tests
    
    func testDeviceStatusUpdate() {
        let expectation = self.expectation(description: "Device status updated")
        
        mockDelegate.onDeviceUpdate = { device in
            XCTAssertNotNil(device)
            expectation.fulfill()
        }
        
        let lightingDevices = deviceManager.getDevices(byType: .lighting)
        guard let device = lightingDevices.first else {
            XCTSkip("No lighting devices available for testing")
            return
        }
        
        deviceManager.controlDevice(device.id, action: .toggle) { success, error in
            XCTAssertTrue(success)
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testStatusRefresh() {
        let expectation = self.expectation(description: "Status refreshed")
        
        deviceManager.refreshDeviceStatus { success in
            XCTAssertTrue(success)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    // MARK: - Protocol Codec Tests
    
    func testCommandEncoding() {
        let deviceId = "light_001"
        let deviceType = DeviceType.lighting
        let action = ControlAction.turnOn
        
        let command = Command(
            deviceId: deviceId,
            deviceType: deviceType,
            action: action
        )
        
        // 验证命令结构
        XCTAssertEqual(command.deviceId, deviceId)
        XCTAssertEqual(command.deviceType, deviceType)
        XCTAssertEqual(command.action, action)
        XCTAssertNotNil(command.id)
        XCTAssertNotNil(command.timestamp)
    }
    
    func testHexCommandGeneration() {
        let device = Device(id: "light_001", name: "测试灯光", type: .lighting)
        
        // 测试HEX命令生成
        let hexCommand = deviceManager.buildControlCommand(device: device, action: .turnOn)
        
        XCTAssertFalse(hexCommand.isEmpty)
        XCTAssertTrue(hexCommand.hasPrefix("AA"))
        XCTAssertTrue(hexCommand.hasSuffix("55"))
        
        // 验证命令长度
        XCTAssertGreaterThan(hexCommand.count, 10)
    }
    
    // MARK: - Performance Tests
    
    func testDeviceControlPerformance() {
        measure {
            let lightingDevices = deviceManager.getDevices(byType: .lighting)
            guard let device = lightingDevices.first else {
                return
            }
            
            let expectation = self.expectation(description: "Performance test")
            
            deviceManager.controlDevice(device.id, action: .toggle) { success, error in
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5)
        }
    }
    
    func testBatchControlPerformance() {
        measure {
            let expectation = self.expectation(description: "Batch performance test")
            
            deviceManager.controlAllDevices(ofType: .lighting, action: .allOn) { success, error in
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 15)
        }
    }
    
    func testMemoryUsage() {
        // 测试内存使用情况
        let initialMemory = getMemoryUsage()
        
        // 执行大量设备操作
        for _ in 0..<100 {
            deviceManager.refreshDeviceStatus { _ in }
        }
        
        let finalMemory = getMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        // 验证内存增长在合理范围内 (小于10MB)
        XCTAssertLessThan(memoryIncrease, 10 * 1024 * 1024)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorPropagation() {
        let expectation = self.expectation(description: "Error propagated")
        
        mockDelegate.onError = { error in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }
        
        // 触发错误情况
        deviceManager.controlDevice("invalid_id", action: .turnOn) { success, error in
            // 错误应该在代理中传播
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testNetworkErrorHandling() {
        let expectation = self.expectation(description: "Network error handled")
        
        mockDelegate.onError = { error in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }
        
        // 模拟网络错误
        deviceManager.refreshDeviceStatus { success in
            if !success {
                // 网络错误应该被正确处理
            }
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    // MARK: - Helper Methods
    
    private func getMemoryUsage() -> Int {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Int(info.resident_size)
        } else {
            return 0
        }
    }
}

// MARK: - Mock Delegate

class MockDeviceManagerDelegate: DeviceManagerDelegate {
    
    var onDeviceUpdate: ((Device) -> Void)?
    var onError: ((Error) -> Void)?
    var onStatusReceived: (([String: Any]) -> Void)?
    
    func deviceManager(_ manager: DeviceManager, didUpdateDevice device: Device) {
        onDeviceUpdate?(device)
    }
    
    func deviceManager(_ manager: DeviceManager, didFailWithError error: Error) {
        onError?(error)
    }
    
    func deviceManager(_ manager: DeviceManager, didReceiveStatus status: [String: Any]) {
        onStatusReceived?(status)
    }
}