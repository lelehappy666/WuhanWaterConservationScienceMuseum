//
//  ProtocolCodecTests.swift
//  WuhanWaterConservationControlSystemTests
//
//  Created by SOLO Builder on 2025/12/23.
//  Copyright © 2025 WuhanWaterConservation. All rights reserved.
//

import XCTest
@testable import WuhanWaterConservationControlSystem

class ProtocolCodecTests: XCTestCase {
    
    // MARK: - Command Encoding Tests
    
    func testBasicCommandEncoding() {
        let command = Command(
            deviceId: "light_001",
            deviceType: .lighting,
            action: .turnOn
        )
        
        let encodedData = ProtocolCodec.encodeCommand(command)
        
        XCTAssertNotNil(encodedData)
        XCTAssertGreaterThan(encodedData!.count, 0)
        
        // 验证起始符和结束符
        XCTAssertEqual(encodedData!.first, ProtocolCodec.startDelimiter)
        XCTAssertEqual(encodedData!.last, ProtocolCodec.endDelimiter)
    }
    
    func testCommandEncodingWithParameters() {
        let parameters: [String: Any] = [
            "brightness": 75,
            "colorTemperature": 4000
        ]
        
        let command = Command(
            deviceId: "light_002",
            deviceType: .lighting,
            action: .turnOn,
            parameters: parameters
        )
        
        let encodedData = ProtocolCodec.encodeCommand(command)
        
        XCTAssertNotNil(encodedData)
        XCTAssertGreaterThan(encodedData!.count, ProtocolCodec.headerSize)
    }
    
    func testBatchCommandEncoding() {
        let deviceIds = ["light_001", "light_002", "light_003"]
        
        let command = ProtocolCodec.buildBatchCommand(
            deviceIds: deviceIds,
            deviceType: .lighting,
            action: .allOn
        )
        
        let encodedData = ProtocolCodec.encodeCommand(command)
        
        XCTAssertNotNil(encodedData)
        XCTAssertGreaterThan(encodedData!.count, 0)
    }
    
    func testStatusQueryCommandEncoding() {
        let command = ProtocolCodec.buildStatusQueryCommand(deviceId: "light_001")
        
        let encodedData = ProtocolCodec.encodeCommand(command)
        
        XCTAssertNotNil(encodedData)
        XCTAssertGreaterThan(encodedData!.count, 0)
    }
    
    // MARK: - Response Decoding Tests
    
    func testBasicResponseDecoding() {
        // 创建测试响应数据
        var responseData = Data()
        responseData.append(ProtocolCodec.startDelimiter)
        
        // 命令ID (4字节)
        let commandId = "TEST"
        responseData.append(commandId.data(using: .utf8)!)
        
        // 设备ID (2字节)
        let deviceId: UInt16 = 1
        responseData.append(contentsOf: withUnsafeBytes(of: deviceId.bigEndian) { Data($0) })
        
        // 状态 (1字节)
        responseData.append(ProtocolCodec.encodeStatus(.success))
        
        // 消息长度 (2字节)
        let message = "Success"
        let messageData = message.data(using: .utf8)!
        let messageLength = UInt16(messageData.count)
        responseData.append(contentsOf: withUnsafeBytes(of: messageLength.bigEndian) { Data($0) })
        
        // 消息内容
        responseData.append(messageData)
        
        // 校验和 (2字节)
        let checksum = ProtocolCodec.calculateChecksum(responseData)
        responseData.append(contentsOf: withUnsafeBytes(of: checksum.bigEndian) { Data($0) })
        
        // 结束符
        responseData.append(ProtocolCodec.endDelimiter)
        
        let response = ProtocolCodec.decodeResponse(responseData)
        
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.status, .success)
        XCTAssertEqual(response?.message, message)
    }
    
    func testErrorResponseDecoding() {
        // 创建错误响应数据
        var responseData = Data()
        responseData.append(ProtocolCodec.startDelimiter)
        
        // 命令ID (4字节)
        let commandId = "TEST"
        responseData.append(commandId.data(using: .utf8)!)
        
        // 设备ID (2字节)
        let deviceId: UInt16 = 1
        responseData.append(contentsOf: withUnsafeBytes(of: deviceId.bigEndian) { Data($0) })
        
        // 状态 (1字节) - 错误
        responseData.append(ProtocolCodec.encodeStatus(.error))
        
        // 消息长度 (2字节)
        let message = "Device not found"
        let messageData = message.data(using: .utf8)!
        let messageLength = UInt16(messageData.count)
        responseData.append(contentsOf: withUnsafeBytes(of: messageLength.bigEndian) { Data($0) })
        
        // 消息内容
        responseData.append(messageData)
        
        // 校验和 (2字节)
        let checksum = ProtocolCodec.calculateChecksum(responseData)
        responseData.append(contentsOf: withUnsafeBytes(of: checksum.bigEndian) { Data($0) })
        
        // 结束符
        responseData.append(ProtocolCodec.endDelimiter)
        
        let response = ProtocolCodec.decodeResponse(responseData)
        
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.status, .error)
        XCTAssertEqual(response?.message, message)
    }
    
    func testInvalidResponseDecoding() {
        // 测试无效数据
        let invalidData = Data([0xFF, 0xFF, 0xFF])
        let response = ProtocolCodec.decodeResponse(invalidData)
        
        XCTAssertNil(response)
    }
    
    func testChecksumValidation() {
        // 创建有效响应
        var responseData = Data()
        responseData.append(ProtocolCodec.startDelimiter)
        
        let commandId = "TEST"
        responseData.append(commandId.data(using: .utf8)!)
        
        let deviceId: UInt16 = 1
        responseData.append(contentsOf: withUnsafeBytes(of: deviceId.bigEndian) { Data($0) })
        
        responseData.append(ProtocolCodec.encodeStatus(.success))
        
        let message = "Test"
        let messageData = message.data(using: .utf8)!
        let messageLength = UInt16(messageData.count)
        responseData.append(contentsOf: withUnsafeBytes(of: messageLength.bigEndian) { Data($0) })
        
        responseData.append(messageData)
        
        // 计算正确的校验和
        let correctChecksum = ProtocolCodec.calculateChecksum(responseData)
        responseData.append(contentsOf: withUnsafeBytes(of: correctChecksum.bigEndian) { Data($0) })
        
        responseData.append(ProtocolCodec.endDelimiter)
        
        let response = ProtocolCodec.decodeResponse(responseData)
        XCTAssertNotNil(response)
        
        // 修改校验和使其无效
        responseData[responseData.count - 3] = 0xFF
        responseData[responseData.count - 2] = 0xFF
        
        let invalidResponse = ProtocolCodec.decodeResponse(responseData)
        XCTAssertNil(invalidResponse)
    }
    
    // MARK: - Validation Tests
    
    func testCommandValidation() {
        let validCommand = Command(
            deviceId: "light_001",
            deviceType: .lighting,
            action: .turnOn,
            parameters: ["brightness": 50]
        )
        
        let isValid = ProtocolCodec.validateCommand(validCommand)
        XCTAssertTrue(isValid)
    }
    
    func testInvalidCommandValidation() {
        let invalidCommand = Command(
            deviceId: "", // 空设备ID
            deviceType: .lighting,
            action: .turnOn
        )
        
        let isValid = ProtocolCodec.validateCommand(invalidCommand)
        XCTAssertFalse(isValid)
    }
    
    func testResponseValidation() {
        let validResponse = Response(
            id: "test_response",
            status: .success,
            message: "Operation successful"
        )
        
        let isValid = ProtocolCodec.validateResponse(validResponse)
        XCTAssertTrue(isValid)
    }
    
    func testInvalidResponseValidation() {
        let invalidResponse = Response(
            id: "", // 空ID
            status: .error,
            message: "" // 空消息
        )
        
        let isValid = ProtocolCodec.validateResponse(invalidResponse)
        XCTAssertFalse(isValid)
    }
    
    // MARK: - Performance Tests
    
    func testCommandEncodingPerformance() {
        let command = Command(
            deviceId: "light_001",
            deviceType: .lighting,
            action: .turnOn,
            parameters: ["brightness": 75, "colorTemperature": 4000]
        )
        
        measure {
            for _ in 0..<1000 {
                _ = ProtocolCodec.encodeCommand(command)
            }
        }
    }
    
    func testResponseDecodingPerformance() {
        // 创建测试响应数据
        var responseData = Data()
        responseData.append(ProtocolCodec.startDelimiter)
        
        let commandId = "TEST"
        responseData.append(commandId.data(using: .utf8)!)
        
        let deviceId: UInt16 = 1
        responseData.append(contentsOf: withUnsafeBytes(of: deviceId.bigEndian) { Data($0) })
        
        responseData.append(ProtocolCodec.encodeStatus(.success))
        
        let message = "Performance test response"
        let messageData = message.data(using: .utf8)!
        let messageLength = UInt16(messageData.count)
        responseData.append(contentsOf: withUnsafeBytes(of: messageLength.bigEndian) { Data($0) })
        
        responseData.append(messageData)
        
        let checksum = ProtocolCodec.calculateChecksum(responseData)
        responseData.append(contentsOf: withUnsafeBytes(of: checksum.bigEndian) { Data($0) })
        
        responseData.append(ProtocolCodec.endDelimiter)
        
        measure {
            for _ in 0..<1000 {
                _ = ProtocolCodec.decodeResponse(responseData)
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorMessageGeneration() {
        let encodingError = ProtocolCodec.ProtocolError.encodingError
        let errorMessage = ProtocolCodec.handleError(encodingError)
        
        XCTAssertEqual(errorMessage, "Data encoding error")
        
        let checksumError = ProtocolCodec.ProtocolError.checksumMismatch
        let checksumErrorMessage = ProtocolCodec.handleError(checksumError)
        
        XCTAssertEqual(checksumErrorMessage, "Checksum verification failed")
    }
    
    func testMalformedDataHandling() {
        // 测试各种畸形数据
        let malformedDataCases = [
            Data(), // 空数据
            Data([ProtocolCodec.startDelimiter]), // 只有起始符
            Data([ProtocolCodec.startDelimiter, 0x00, 0x00]), // 不完整数据
            Data([0xFF, 0xFF, 0xFF, 0xFF]), // 无效数据
        ]
        
        for malformedData in malformedDataCases {
            let response = ProtocolCodec.decodeResponse(malformedData)
            XCTAssertNil(response, "Should not decode malformed data")
        }
    }
}