//
//  ProtocolCodec.swift
//  WuhanWaterConservationControlSystem
//
//  Created by SOLO Builder on 2025/12/23.
//  Copyright © 2025 WuhanWaterConservation. All rights reserved.
//

import Foundation

// MARK: - Protocol Definitions

struct Command {
    let id: String
    let deviceId: String
    let deviceType: DeviceType
    let action: ControlAction
    let parameters: [String: Any]
    let timestamp: Date
    
    init(id: String = UUID().uuidString,
         deviceId: String,
         deviceType: DeviceType,
         action: ControlAction,
         parameters: [String: Any] = [:]) {
        self.id = id
        self.deviceId = deviceId
        self.deviceType = deviceType
        self.action = action
        self.parameters = parameters
        self.timestamp = Date()
    }
}

struct Response {
    let id: String
    let status: ResponseStatus
    let message: String
    let data: [String: Any]
    let timestamp: Date
    
    enum ResponseStatus: String {
        case success = "success"
        case error = "error"
        case timeout = "timeout"
        case invalid = "invalid"
    }
    
    init(id: String,
         status: ResponseStatus,
         message: String,
         data: [String: Any] = [:]) {
        self.id = id
        self.status = status
        self.message = message
        self.data = data
        self.timestamp = Date()
    }
}

// MARK: - Protocol Codec

class ProtocolCodec {
    
    // MARK: - Constants
    
    private static let startDelimiter: UInt8 = 0xAA
    private static let endDelimiter: UInt8 = 0x55
    private static let maxPacketSize = 1024
    private static let headerSize = 8
    
    // MARK: - Command Encoding
    
    static func encodeCommand(_ command: Command) -> Data? {
        var packet = Data()
        
        // 起始符
        packet.append(startDelimiter)
        
        // 命令ID (4字节)
        guard let commandIdData = command.id.data(using: .utf8) else { return nil }
        packet.append(commandIdData.prefix(4))
        
        // 设备ID (2字节)
        guard let deviceId = UInt16(command.deviceId.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)) else {
            return nil
        }
        packet.append(contentsOf: withUnsafeBytes(of: deviceId.bigEndian) { Data($0) })
        
        // 设备类型 (1字节)
        packet.append(command.deviceType.rawValue.data(using: .utf8)?.first ?? 0x00)
        
        // 动作类型 (1字节)
        packet.append(command.action.rawValue.data(using: .utf8)?.first ?? 0x00)
        
        // 参数长度 (2字节)
        let parametersData = encodeParameters(command.parameters)
        let parametersLength = UInt16(parametersData.count)
        packet.append(contentsOf: withUnsafeBytes(of: parametersLength.bigEndian) { Data($0) })
        
        // 参数字段
        packet.append(parametersData)
        
        // 校验和 (2字节)
        let checksum = calculateChecksum(packet)
        packet.append(contentsOf: withUnsafeBytes(of: checksum.bigEndian) { Data($0) })
        
        // 结束符
        packet.append(endDelimiter)
        
        return packet
    }
    
    // MARK: - Response Decoding
    
    static func decodeResponse(_ data: Data) -> Response? {
        guard data.count >= headerSize else {
            print("ProtocolCodec: Data too short for valid response")
            return nil
        }
        
        var offset = 0
        
        // 验证起始符
        guard data[offset] == startDelimiter else {
            print("ProtocolCodec: Invalid start delimiter")
            return nil
        }
        offset += 1
        
        // 提取命令ID (4字节)
        let commandIdData = data.subdata(in: offset..<(offset + 4))
        let commandId = String(data: commandIdData, encoding: .utf8) ?? "unknown"
        offset += 4
        
        // 提取设备ID (2字节)
        let deviceIdData = data.subdata(in: offset..<(offset + 2))
        let deviceId = UInt16(bigEndian: deviceIdData.withUnsafeBytes { $0.load(as: UInt16.self) })
        offset += 2
        
        // 提取响应状态 (1字节)
        let statusByte = data[offset]
        let status = decodeStatus(statusByte)
        offset += 1
        
        // 提取消息长度 (2字节)
        let messageLengthData = data.subdata(in: offset..<(offset + 2))
        let messageLength = UInt16(bigEndian: messageLengthData.withUnsafeBytes { $0.load(as: UInt16.self) })
        offset += 2
        
        // 提取消息内容
        guard data.count >= offset + Int(messageLength) + 3 else {
            print("ProtocolCodec: Insufficient data for message and checksum")
            return nil
        }
        
        let messageData = data.subdata(in: offset..<(offset + Int(messageLength)))
        let message = String(data: messageData, encoding: .utf8) ?? "Unknown error"
        offset += Int(messageLength)
        
        // 提取数据字段 (如果存在)
        let remainingDataLength = data.count - offset - 3 // 减去校验和和结束符
        var responseData: [String: Any] = [:]
        
        if remainingDataLength > 0 {
            let responseDataBytes = data.subdata(in: offset..<(offset + remainingDataLength))
            responseData = decodeParameters(responseDataBytes)
        }
        
        // 验证校验和
        let checksumData = data.subdata(in: (data.count - 3)..<(data.count - 1))
        let receivedChecksum = UInt16(bigEndian: checksumData.withUnsafeBytes { $0.load(as: UInt16.self) })
        
        let calculatedChecksum = calculateChecksum(data.subdata(in: 0..<(data.count - 3)))
        
        guard receivedChecksum == calculatedChecksum else {
            print("ProtocolCodec: Checksum mismatch")
            return nil
        }
        
        // 验证结束符
        guard data[data.count - 1] == endDelimiter else {
            print("ProtocolCodec: Invalid end delimiter")
            return nil
        }
        
        return Response(
            id: commandId,
            status: status,
            message: message,
            data: responseData
        )
    }
    
    // MARK: - Helper Methods
    
    private static func encodeParameters(_ parameters: [String: Any]) -> Data {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
            return Data()
        }
        return jsonData
    }
    
    private static func decodeParameters(_ data: Data) -> [String: Any] {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
              let parameters = jsonObject as? [String: Any] else {
            return [:]
        }
        return parameters
    }
    
    private static func encodeStatus(_ status: Response.ResponseStatus) -> UInt8 {
        switch status {
        case .success:
            return 0x00
        case .error:
            return 0x01
        case .timeout:
            return 0x02
        case .invalid:
            return 0x03
        }
    }
    
    private static func decodeStatus(_ byte: UInt8) -> Response.ResponseStatus {
        switch byte {
        case 0x00:
            return .success
        case 0x01:
            return .error
        case 0x02:
            return .timeout
        case 0x03:
            return .invalid
        default:
            return .invalid
        }
    }
    
    private static func calculateChecksum(_ data: Data) -> UInt16 {
        var checksum: UInt32 = 0
        
        for byte in data {
            checksum += UInt32(byte)
        }
        
        return UInt16(checksum & 0xFFFF)
    }
    
    // MARK: - Command Builders
    
    static func buildLightingCommand(deviceId: String, action: ControlAction, brightness: Int? = nil) -> Command {
        var parameters: [String: Any] = [:]
        
        if let brightness = brightness {
            parameters["brightness"] = max(0, min(100, brightness))
        }
        
        return Command(
            deviceId: deviceId,
            deviceType: .lighting,
            action: action,
            parameters: parameters
        )
    }
    
    static func buildComputerCommand(deviceId: String, action: ControlAction) -> Command {
        return Command(
            deviceId: deviceId,
            deviceType: .computer,
            action: action
        )
    }
    
    static func buildProjectorCommand(deviceId: String, action: ControlAction) -> Command {
        return Command(
            deviceId: deviceId,
            deviceType: .projector,
            action: action
        )
    }
    
    static func buildExhibitPowerCommand(deviceId: String, action: ControlAction) -> Command {
        return Command(
            deviceId: deviceId,
            deviceType: .exhibitPower,
            action: action
        )
    }
    
    static func buildBatchCommand(deviceIds: [String], deviceType: DeviceType, action: ControlAction) -> Command {
        let parameters: [String: Any] = [
            "deviceIds": deviceIds,
            "count": deviceIds.count
        ]
        
        return Command(
            deviceId: "batch_\(UUID().uuidString.prefix(8))",
            deviceType: deviceType,
            action: action,
            parameters: parameters
        )
    }
    
    static func buildStatusQueryCommand(deviceId: String? = nil) -> Command {
        let targetDeviceId = deviceId ?? "all"
        
        return Command(
            deviceId: targetDeviceId,
            deviceType: .lighting, // 通用类型
            action: ControlAction.toggle // 用作查询标识
        )
    }
    
    // MARK: - Validation
    
    static func validateCommand(_ command: Command) -> Bool {
        // 验证设备ID格式
        guard !command.deviceId.isEmpty else {
            print("ProtocolCodec: Invalid device ID")
            return false
        }
        
        // 验证参数
        for (key, value) in command.parameters {
            if key.isEmpty {
                print("ProtocolCodec: Empty parameter key")
                return false
            }
            
            // 验证特定参数类型
            if key == "brightness" {
                guard let brightness = value as? Int, brightness >= 0 && brightness <= 100 else {
                    print("ProtocolCodec: Invalid brightness value")
                    return false
                }
            }
        }
        
        return true
    }
    
    static func validateResponse(_ response: Response) -> Bool {
        // 验证响应ID
        guard !response.id.isEmpty else {
            print("ProtocolCodec: Invalid response ID")
            return false
        }
        
        // 验证消息
        guard !response.message.isEmpty else {
            print("ProtocolCodec: Empty response message")
            return false
        }
        
        return true
    }
    
    // MARK: - Error Handling
    
    enum ProtocolError: Error {
        case invalidData
        case invalidFormat
        case checksumMismatch
        case encodingError
        case decodingError
        case validationError
    }
    
    static func handleError(_ error: ProtocolError) -> String {
        switch error {
        case .invalidData:
            return "Invalid data format"
        case .invalidFormat:
            return "Invalid protocol format"
        case .checksumMismatch:
            return "Checksum verification failed"
        case .encodingError:
            return "Data encoding error"
        case .decodingError:
            return "Data decoding error"
        case .validationError:
            return "Data validation failed"
        }
    }
}