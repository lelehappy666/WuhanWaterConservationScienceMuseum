# 武汉节水科技馆视频点播控制系统 (VideoPlay)

这是一个基于 **React + TypeScript + Vite** 开发的视频点播前端项目。它集成了 **腾讯云开发 (Tencent CloudBase)**，用于实现视频列表管理、用户匿名登录以及在点击播放时直接更新云数据库中的路径信息。

## 🛠 技术栈

- **前端框架**: React 18
- **构建工具**: Vite
- **语言**: TypeScript
- **样式**: Tailwind CSS (配合 Framer Motion 实现动画)
- **后端/云服务**: 腾讯云开发 (CloudBase) - 云数据库、匿名登录
- **路由**: React Router v6

## 🚀 快速开始

### 1. 环境准备

确保本地已安装 Node.js (推荐 v16+)。

### 2. 安装依赖

```bash
npm install
```

### 3. 配置环境变量

在项目根目录创建或检查 `.env` 文件，确保包含腾讯云环境 ID：

```env
VITE_TCB_ENV_ID=your-env-id  # 例如: test-3goem7h983cb2f0e
```

### 4. 启动开发服务器

```bash
npm run dev
```

访问 `http://localhost:5173` 即可预览。

## ☁️ 腾讯云开发配置 (关键)

本项目依赖云开发服务，本地调试前请务必完成以下配置，否则会报错 `without auth` 或 `ResourceNotFound`。

详细排查请参考 [CHECK_CONFIGURATION.md](./CHECK_CONFIGURATION.md)。

### 1. Web 安全域名

- 登录 [腾讯云开发控制台](https://console.cloud.tencent.com/tcb) -> **环境设置** -> **安全配置**。
- 在 **WEB安全域名** 中添加：
  - `localhost:5173`
  - `127.0.0.1:5173`

### 2. 开启匿名登录

- 控制台 -> **登录授权**。
- 确保 **匿名登录** 状态为 **已开启**。

### 3. 数据库集合

- 控制台 -> **数据库**。
- 创建集合：`WuHan`。
- 权限设置：推荐 **所有用户可读**。
- 数据结构示例：
  ```json
  {
    "Name": "节水宣传片",
    "URL": "https://example.com/video.mp4",
    "Info": "视频简介...",
    "Time": "2023-10-01"
  }
  ```

### 4. 播放与路径更新

点击播放时，前端直接更新云数据库集合 `CloudVideoPath` 中 `_id="CloudVideoPath"` 文档的 `Path` 字段为当前视频标题。无需云函数。

## 📂 项目结构

```
src/
├── components/     # 通用组件 (DebugPanel, Layout, VideoCard 等)
├── hooks/          # 自定义 Hooks (useVideos 等)
├── pages/          # 页面组件 (Home, VideoDetail)
├── store/          # 状态管理 (Zustand)
├── utils/
│   ├── service.ts  # 核心业务逻辑 (云开发初始化、数据库查询、数据库更新)
│   └── types.ts    # TypeScript 类型定义
└── App.tsx         # 路由配置
```

## 🐛 调试与常见问题

页面右下角内置了 **Debug Panel**，实时显示：

- 云开发初始化状态
- 登录状态 (UID)
- 数据库连接测试结果
- 关键日志 (初始化/登录状态/数据库读写结果)

**常见报错：**

- `Operation failed with error: ... without auth`: 未配置 Web 安全域名。
- `ResourceNotFound: Db or Table not exist`: 数据库集合 `WuHan` 未创建。

## 📦 构建部署

```bash
npm run build
```

构建产物将输出到 `dist` 目录，可直接部署到腾讯云静态网站托管或其他 Web 服务器。
