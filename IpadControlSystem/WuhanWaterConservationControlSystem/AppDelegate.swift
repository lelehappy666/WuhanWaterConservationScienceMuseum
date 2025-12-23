//
//  AppDelegate.swift
//  WuhanWaterConservationControlSystem
//
//  Created by SOLO Builder on 2025/12/23.
//  Copyright © 2025 WuhanWaterConservation. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 设置应用基本配置
        setupApplicationAppearance()
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
            UINavigationController.attemptRotationToDeviceOrientation()
        }
        
        // 初始化TCP连接管理器
        TCPConnectionManager.shared.setupConnection()
        
        // 配置后台任务
        setupBackgroundTasks()
        
        // 设置内存管理
        setupMemoryManagement()
        
        return true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .landscape
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // 应用即将进入后台时保持TCP连接
        beginBackgroundTask()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // 应用进入后台时维持TCP心跳
        TCPConnectionManager.shared.startHeartbeat()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // 应用即将进入前台时恢复连接
        TCPConnectionManager.shared.checkConnectionStatus()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // 应用激活时结束后台任务
        endBackgroundTask()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // 应用终止时关闭TCP连接
        TCPConnectionManager.shared.disconnect()
    }

    // MARK: - Private Methods
    
    private func setupApplicationAppearance() {
        // 设置iOS 10风格的外观
        if #available(iOS 13.0, *) {
            UITabBar.appearance().tintColor = UIColor.systemBlue
            UINavigationBar.appearance().tintColor = UIColor.systemBlue
            UISwitch.appearance().onTintColor = UIColor.systemGreen
        } else {
            UITabBar.appearance().tintColor = UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0)
            UINavigationBar.appearance().tintColor = UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0)
            UISwitch.appearance().onTintColor = UIColor(red: 52.0/255.0, green: 199.0/255.0, blue: 89.0/255.0, alpha: 1.0)
        }
        
        // 设置导航栏样式
        UINavigationBar.appearance().barTintColor = UIColor.white
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.darkText
        ]
    }
    
    private func setupBackgroundTasks() {
        // 注册后台任务处理
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(handleMemoryWarning),
                                              name: UIApplication.didReceiveMemoryWarningNotification,
                                              object: nil)
    }
    
    private func setupMemoryManagement() {
        // 优化内存使用，适配iPad mini 4的A8处理器
        URLCache.shared.memoryCapacity = 4 * 1024 * 1024 // 4MB
        URLCache.shared.diskCapacity = 20 * 1024 * 1024 // 20MB
        
        
    }
    
    private func beginBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "TCPConnectionTask") {
            self.endBackgroundTask()
        }
        
        // 在后台维持TCP连接
        DispatchQueue.global(qos: .background).async {
            TCPConnectionManager.shared.maintainConnectionInBackground()
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    @objc private func handleMemoryWarning() {
        // 处理内存警告，清理缓存
        URLCache.shared.removeAllCachedResponses()
        
        
        
        // 清理临时数据
        DeviceManager.shared.clearTemporaryData()
    }
}
