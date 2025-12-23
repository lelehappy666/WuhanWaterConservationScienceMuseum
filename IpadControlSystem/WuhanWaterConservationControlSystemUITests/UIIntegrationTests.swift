//
//  UIIntegrationTests.swift
//  WuhanWaterConservationControlSystemUITests
//
//  Created by SOLO Builder on 2025/12/23.
//  Copyright © 2025 WuhanWaterConservation. All rights reserved.
//

import XCTest

class UIIntegrationTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDown() {
        app = nil
        super.tearDown()
    }
    
    // MARK: - Main Interface Tests
    
    func testMainInterfaceLoads() {
        // 验证主界面元素存在
        XCTAssertTrue(app.staticTexts["武汉节水科技馆"].exists)
        XCTAssertTrue(app.staticTexts["中控系统"].exists)
        
        // 验证设备控制按钮存在
        XCTAssertTrue(app.buttons["灯光"].exists)
        XCTAssertTrue(app.buttons["电脑"].exists)
        XCTAssertTrue(app.buttons["投影"].exists)
        XCTAssertTrue(app.buttons["展品"].exists)
        
        // 验证设置按钮存在
        XCTAssertTrue(app.buttons["gear"].exists)
    }
    
    func testConnectionStatusDisplay() {
        // 验证连接状态显示
        let connectionStatusLabel = app.staticTexts.matching(identifier: "connectionStatus").firstMatch
        XCTAssertTrue(connectionStatusLabel.exists)
        
        // 验证连接状态指示器存在
        let connectionIndicator = app.otherElements.matching(identifier: "connectionIndicator").firstMatch
        XCTAssertTrue(connectionIndicator.exists)
    }
    
    // MARK: - Navigation Tests
    
    func testLightingControlNavigation() {
        let lightingButton = app.buttons["灯光"]
        XCTAssertTrue(lightingButton.exists)
        
        lightingButton.tap()
        
        // 验证导航到灯光控制页面
        XCTAssertTrue(app.navigationBars["灯光控制"].exists)
        XCTAssertTrue(app.tables.firstMatch.exists)
        
        // 测试返回功能
        app.navigationBars.buttons["返回"].tap()
        XCTAssertTrue(app.staticTexts["武汉节水科技馆"].exists)
    }
    
    func testComputerControlNavigation() {
        let computerButton = app.buttons["电脑"]
        XCTAssertTrue(computerButton.exists)
        
        computerButton.tap()
        
        // 验证导航到电脑控制页面
        XCTAssertTrue(app.navigationBars["电脑控制"].exists)
        XCTAssertTrue(app.tables.firstMatch.exists)
        
        // 测试返回功能
        app.navigationBars.buttons["返回"].tap()
        XCTAssertTrue(app.staticTexts["武汉节水科技馆"].exists)
    }
    
    func testProjectorControlNavigation() {
        let projectorButton = app.buttons["投影"]
        XCTAssertTrue(projectorButton.exists)
        
        projectorButton.tap()
        
        // 验证导航到投影控制页面
        XCTAssertTrue(app.navigationBars["投影控制"].exists)
        XCTAssertTrue(app.tables.firstMatch.exists)
        
        // 测试返回功能
        app.navigationBars.buttons["返回"].tap()
        XCTAssertTrue(app.staticTexts["武汉节水科技馆"].exists)
    }
    
    func testExhibitPowerNavigation() {
        let exhibitButton = app.buttons["展品"]
        XCTAssertTrue(exhibitButton.exists)
        
        exhibitButton.tap()
        
        // 验证导航到展品电源页面
        XCTAssertTrue(app.navigationBars["展品电源"].exists)
        XCTAssertTrue(app.buttons["全部开启"].exists)
        XCTAssertTrue(app.buttons["全部关闭"].exists)
        
        // 测试返回功能
        app.navigationBars.buttons["返回"].tap()
        XCTAssertTrue(app.staticTexts["武汉节水科技馆"].exists)
    }
    
    func testSettingsNavigation() {
        let settingsButton = app.buttons["gear"]
        XCTAssertTrue(settingsButton.exists)
        
        settingsButton.tap()
        
        // 验证导航到设置页面
        XCTAssertTrue(app.navigationBars["网络设置"].exists)
        XCTAssertTrue(app.textFields["serverAddress"].exists)
        XCTAssertTrue(app.textFields["port"].exists)
        
        // 测试返回功能
        app.navigationBars.buttons["返回"].tap()
        XCTAssertTrue(app.staticTexts["武汉节水科技馆"].exists)
    }
    
    // MARK: - Device Control Tests
    
    func testDeviceToggle() {
        // 导航到灯光控制页面
        app.buttons["灯光"].tap()
        
        // 等待页面加载
        let table = app.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 5))
        
        // 获取第一个设备开关
        let firstSwitch = table.switches.firstMatch
        XCTAssertTrue(firstSwitch.exists)
        
        // 记录初始状态
        let initialState = firstSwitch.value as? String
        
        // 切换开关状态
        firstSwitch.tap()
        
        // 验证状态改变
        let newState = firstSwitch.value as? String
        XCTAssertNotEqual(initialState, newState)
    }
    
    func testBatchControl() {
        // 导航到灯光控制页面
        app.buttons["灯光"].tap()
        
        // 等待页面加载
        let allOnButton = app.buttons["全部开启"]
        XCTAssertTrue(allOnButton.waitForExistence(timeout: 5))
        
        // 测试全部开启功能
        allOnButton.tap()
        
        // 处理确认弹窗
        let alert = app.alerts.firstMatch
        if alert.exists {
            alert.buttons["确定"].tap()
        }
        
        // 验证操作成功
        XCTAssertTrue(app.staticTexts.matching(identifier: "successMessage").firstMatch.waitForExistence(timeout: 10))
    }
    
    // MARK: - Settings Tests
    
    func testNetworkSettings() {
        // 导航到设置页面
        app.buttons["gear"].tap()
        
        // 等待页面加载
        let serverAddressField = app.textFields["serverAddress"]
        XCTAssertTrue(serverAddressField.waitForExistence(timeout: 5))
        
        // 清除现有内容
        serverAddressField.tap()
        serverAddressField.typeText("")
        
        // 输入新的服务器地址
        let newServerAddress = "192.168.1.100"
        serverAddressField.typeText(newServerAddress)
        
        // 测试端口设置
        let portField = app.textFields["port"]
        portField.tap()
        portField.typeText("")
        portField.typeText("8080")
        
        // 测试连接按钮
        let connectButton = app.buttons["连接"]
        XCTAssertTrue(connectButton.exists)
        connectButton.tap()
        
        // 验证连接状态更新
        let statusLabel = app.staticTexts.matching(identifier: "connectionStatus").firstMatch
        XCTAssertTrue(statusLabel.waitForExistence(timeout: 10))
    }
    
    // MARK: - Error Handling Tests
    
    func testNetworkErrorHandling() {
        // 导航到设置页面
        app.buttons["gear"].tap()
        
        // 设置无效的服务器地址
        let serverAddressField = app.textFields["serverAddress"]
        serverAddressField.tap()
        serverAddressField.typeText("")
        serverAddressField.typeText("invalid.server.address")
        
        // 尝试连接
        let connectButton = app.buttons["连接"]
        connectButton.tap()
        
        // 验证错误处理
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 15))
        XCTAssertTrue(alert.staticTexts["连接失败"].exists || alert.staticTexts["错误"].exists)
        
        // 关闭错误弹窗
        alert.buttons["确定"].tap()
    }
    
    func testDeviceControlErrorHandling() {
        // 导航到灯光控制页面
        app.buttons["灯光"].tap()
        
        // 等待页面加载
        let table = app.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 5))
        
        // 模拟设备离线状态
        // 注意：这需要后端配合模拟离线状态
        
        // 尝试控制离线设备
        let firstSwitch = table.switches.firstMatch
        if firstSwitch.exists {
            firstSwitch.tap()
            
            // 验证错误处理
            let alert = app.alerts.firstMatch
            if alert.waitForExistence(timeout: 5) {
                XCTAssertTrue(alert.staticTexts["设备离线"].exists || alert.staticTexts["操作失败"].exists)
                alert.buttons["确定"].tap()
            }
        }
    }
    
    // MARK: - Performance Tests
    
    func testAppLaunchPerformance() {
        measure {
            app.launch()
            
            // 等待主界面完全加载
            XCTAssertTrue(app.staticTexts["武汉节水科技馆"].waitForExistence(timeout: 10))
        }
    }
    
    func testNavigationPerformance() {
        // 预加载应用
        app.launch()
        XCTAssertTrue(app.staticTexts["武汉节水科技馆"].waitForExistence(timeout: 10))
        
        measure {
            // 测试导航性能
            app.buttons["灯光"].tap()
            XCTAssertTrue(app.navigationBars["灯光控制"].waitForExistence(timeout: 5))
            
            app.navigationBars.buttons["返回"].tap()
            XCTAssertTrue(app.staticTexts["武汉节水科技馆"].waitForExistence(timeout: 5))
        }
    }
    
    func testDeviceControlPerformance() {
        // 导航到灯光控制页面
        app.buttons["灯光"].tap()
        
        // 等待页面加载
        let table = app.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 5))
        
        measure {
            // 测试设备控制性能
            let switches = table.switches
            if switches.count > 0 {
                switches.firstMatch.tap()
                
                // 等待响应
                _ = app.staticTexts.matching(identifier: "successMessage").firstMatch.waitForExistence(timeout: 2)
            }
        }
    }
    
    // MARK: - Memory Tests
    
    func testMemoryUsage() {
        app.launch()
        
        // 执行多次导航操作
        for _ in 0..<10 {
            app.buttons["灯光"].tap()
            app.navigationBars.buttons["返回"].tap()
            
            app.buttons["电脑"].tap()
            app.navigationBars.buttons["返回"].tap()
            
            app.buttons["投影"].tap()
            app.navigationBars.buttons["返回"].tap()
            
            app.buttons["展品"].tap()
            app.navigationBars.buttons["返回"].tap()
        }
        
        // 验证应用仍然响应
        XCTAssertTrue(app.staticTexts["武汉节水科技馆"].exists)
        
        // 强制垃圾回收（iOS自动管理内存）
        // 这里主要验证没有内存泄漏导致的崩溃
    }
    
    // MARK: - Background Tests
    
    func testBackgroundBehavior() {
        app.launch()
        
        // 验证主界面
        XCTAssertTrue(app.staticTexts["武汉节水科技馆"].exists)
        
        // 模拟进入后台
        XCUIDevice.shared.press(XCUIDevice.Button.home)
        
        // 等待一段时间
        sleep(5)
        
        // 重新激活应用
        app.activate()
        
        // 验证应用状态恢复
        XCTAssertTrue(app.staticTexts["武汉节水科技馆"].waitForExistence(timeout: 10))
        
        // 验证连接状态仍然有效
        let connectionStatus = app.staticTexts.matching(identifier: "connectionStatus").firstMatch
        XCTAssertTrue(connectionStatus.exists)
    }
    
    // MARK: - Orientation Tests
    
    func testOrientationChanges() {
        app.launch()
        
        // 验证初始状态
        XCTAssertTrue(app.staticTexts["武汉节水科技馆"].exists)
        
        // 测试横屏
        XCUIDevice.shared.orientation = .landscapeLeft
        sleep(2)
        XCTAssertTrue(app.staticTexts["武汉节水科技馆"].exists)
        
        // 测试竖屏
        XCUIDevice.shared.orientation = .portrait
        sleep(2)
        XCTAssertTrue(app.staticTexts["武汉节水科技馆"].exists)
        
        // 测试反向横屏
        XCUIDevice.shared.orientation = .landscapeRight
        sleep(2)
        XCTAssertTrue(app.staticTexts["武汉节水科技馆"].exists)
        
        // 恢复竖屏
        XCUIDevice.shared.orientation = .portrait
    }
}