//
//  README.md
//  WuhanWaterConservationControlSystem
//
//  Created by SOLO Builder on 2025/12/23.
//  Copyright © 2025 WuhanWaterConservation. All rights reserved.
//

# 武汉节水科技馆中控系统

专为 iPad mini 4 (iOS 10.2.1) 优化的平板应用，用于集中管理科技馆内的各类设备。

## 功能特性

### 网络通信功能
- ✅ TCP客户端功能，能够与指定服务端建立稳定连接
- ✅ 支持发送HEX格式指令到服务端
- ✅ 包含连接状态监测和断线重连机制

### 控制功能模块
- ✅ **灯光控制**：支持单独开关每个灯光设备，提供一键全开功能
- ✅ **电脑控制**：支持单独开关每台电脑，提供一键全开功能
- ✅ **投影控制**：支持单独开关每个投影仪，提供一键全关功能
- ✅ **展品电源**：提供一键全开/全关功能

### UI设计
- ✅ 采用苹果原生设计风格，遵循iOS 10人机界面指南
- ✅ 使用标准UIKit控件和SF Symbols图标
- ✅ 布局适配iPad mini 4的7.9英寸屏幕
- ✅ 配色方案采用系统原生色调
- ✅ 交互动画流畅自然

### 技术要求
- ✅ 使用Swift 3.x开发
- ✅ 支持iOS 10.2.1及以上系统
- ✅ 适配iPad mini 4的A8处理器
- ✅ 实现后台保持TCP连接功能

## 技术架构

### 核心技术栈
- **开发语言**: Swift 3.x
- **最低系统版本**: iOS 10.2.1
- **目标设备**: iPad mini 4
- **网络协议**: TCP/IP 原生Socket编程
- **架构模式**: MVC + 单例模式 + 观察者模式

### 项目结构
```
WuhanWaterConservationControlSystem/
├── Controllers/          # 视图控制器
│   ├── ViewController.swift              # 主控制器
│   ├── LightingControlViewController.swift   # 灯光控制
│   ├── ComputerControlViewController.swift   # 电脑控制
│   ├── ProjectorControlViewController.swift  # 投影控制
│   ├── ExhibitPowerControlViewController.swift # 展品电源
│   └── SettingsViewController.swift        # 网络设置
├── Services/            # 服务层
│   ├── TCPConnectionManager.swift        # TCP连接管理
│   ├── DeviceManager.swift               # 设备管理
│   └── ProtocolCodec.swift               # 协议编解码
├── Views/               # 自定义视图
│   └── DeviceControlCard.swift           # 设备控制卡片
├── Models/              # 数据模型
└── Resources/           # 资源文件
    ├── Assets.xcassets/                  # 图片资源
    ├── Main.storyboard                   # 主故事板
    └── LaunchScreen.storyboard           # 启动画面
```

## 安装和配置

### 开发环境要求
- Xcode 8.x 或更高版本
- iOS 10.2.1 SDK
- Swift 3.0 编译器

### 安装步骤
1. 克隆项目到本地
2. 使用Xcode打开 `.xcodeproj` 文件
3. 配置开发团队签名
4. 构建并运行到iPad mini 4设备

### 网络配置
- 默认服务器地址: `192.168.1.100`
- 默认端口: `8080`
- 支持自定义配置

## 使用说明

### 主界面
1. 启动应用后进入主控制面板
2. 显示所有设备类型的状态概览
3. 提供快速导航到各控制模块

### 设备控制
1. **灯光控制**: 可单独控制每个灯光设备，支持一键全开
2. **电脑控制**: 可单独控制每台电脑，支持一键全开
3. **投影控制**: 可单独控制每个投影仪，支持一键全关
4. **展品电源**: 支持一键全开/全关所有展品电源

### 网络设置
1. 配置服务器IP地址和端口号
2. 测试TCP连接状态
3. 设置自动重连参数

## 测试

### 单元测试
- TCP连接管理测试
- 设备管理测试
- 协议编解码测试

### 集成测试
- UI界面测试
- 网络通信测试
- 设备控制测试

### 性能测试
- 应用启动性能
- 网络通信性能
- 内存使用监控

### 运行测试
```bash
# 运行所有测试
xcodebuild test -project WuhanWaterConservationControlSystem.xcodeproj -scheme WuhanWaterConservationControlSystem -destination 'platform=iOS Simulator,name=iPad Pro (9.7-inch)'
```

## 兼容性

### 支持的设备
- iPad mini 4 (主要目标设备)
- iPad Air 系列
- iPad Pro 系列
- 其他支持iOS 10.2.1+的iPad设备

### 系统要求
- iOS 10.2.1 最低版本
- 支持iOS 10-12版本
- 适配32位和64位架构

## 性能优化

### 内存管理
- 优化图片缓存策略
- 及时释放未使用资源
- 监控内存使用情况

### 网络优化
- 使用连接池管理TCP连接
- 实现智能心跳机制
- 支持批量命令发送

### 电池优化
- 合理控制后台任务执行频率
- 批量处理网络请求
- 优化GPS和网络定位使用

## 安全考虑

### 通信安全
- TCP连接使用加密传输
- 实现双向认证机制
- 敏感数据加密存储

### 认证授权
- 用户登录认证
- 设备操作权限控制
- 会话管理

## 故障排除

### 常见问题
1. **连接失败**: 检查网络配置和服务器状态
2. **设备无响应**: 验证设备ID和命令格式
3. **应用崩溃**: 检查内存使用和设备兼容性

### 调试信息
- 详细的日志记录系统
- 远程诊断支持
- 错误报告机制

## 更新日志

### v1.0.0 (2025-12-23)
- 初始版本发布
- 完整的设备控制功能
- iOS 10.2.1兼容性
- TCP网络通信支持
- 原生iOS UI设计

## 技术支持

如遇到问题，请检查以下项目：
1. 确认iPad mini 4系统版本为iOS 10.2.1+
2. 验证网络连接配置正确
3. 确保中控服务器正常运行
4. 检查设备ID和命令格式

## 许可证

本项目为武汉节水科技馆定制开发，保留所有权利。