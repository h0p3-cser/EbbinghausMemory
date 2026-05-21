# 艾伦耶格尔记忆曲线

<p align="center">
  <img src="艾伦耶格尔遗忘曲线/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" alt="App Icon" width="128" />
</p>

<p align="center">
  <strong>基于艾伦耶格尔遗忘曲线的 macOS 记忆复习提醒工具</strong>
</p>

<p align="center">
  <a href="https://github.com/h0p3-cser/EbbinghausMemory/releases"><img src="https://img.shields.io/badge/下载-DMG-blue" alt="下载"></a>
  <a href="https://github.com/h0p3-cser/EbbinghausMemory/blob/main/LICENSE"><img src="https://img.shields.io/badge/许可证-MIT-green" alt="许可证"></a>
  <a><img src="https://img.shields.io/badge/macOS-12.0%2B-orange" alt="macOS"></a>
</p>

---

## 功能特色

### 🧠 智能复习计划
- 根据艾伦耶格尔遗忘曲线自动生成复习时间表
- 8 个复习阶段：20分钟 → 1小时 → 9小时 → 1天 → 2天 → 6天 → 14天 → 31天
- 每次完成复习自动推进到下一阶段

### 📂 分组管理
- 支持创建彩色分组文件夹，按主题整理记忆项目
- 无分组的项目直接在侧边栏列表中显示

### 📊 桌面小组件
- 今日复习小组件：在桌面/通知中心显示当日需要复习的项目
- 颜色指示：有任务时标题变为 Apple 风格绿色
- 实时同步主应用数据

### 🔔 提醒通知
- 可自定义每日提醒时间
- 支持开启/关闭通知
- macOS 原生通知系统集成

### 🗂 批量操作
- 支持多选模式，勾选项目进行批量操作
- 批量删除带双重确认弹窗，防止误操作

### 📝 完成记录
- 已完成复习的项目自动归档至完成记录
- 可查看历史完成情况

---

## 系统要求

| 组件 | 最低版本 |
|------|----------|
| macOS | 12.0+ |
| 小组件 | macOS 14.0+ |

> **无需 Xcode。** DMG 安装后直接可用，永不过期。

---

## 安装

### 📦 DMG 安装（推荐）
1. 从 [Releases](https://github.com/h0p3-cser/EbbinghausMemory/releases) 下载最新 `.dmg`
2. 拖拽 `艾伦耶格尔记忆曲线.app` 到 `Applications` 文件夹
3. 首次打开若提示「无法验证开发者」，**右键点击 → 打开** 即可
4. 完成！

### 🔨 源码构建
```bash
git clone https://github.com/h0p3-cser/EbbinghausMemory.git
cd EbbinghausMemory
bash build_dmg.sh
```

或在 Xcode 中打开 `艾伦耶格尔.xcodeproj`，选择 `艾伦耶格尔遗忘曲线` scheme 构建。

---

## 使用指南

### 创建记忆项目
1. 点击左下角 **+** 按钮
2. 输入记忆项目名称（如 "英语单词 List 1"）
3. 选择创建日期和所属分组（可选）
4. 点击"创建"

### 每日复习
- 打开应用后，左侧列表显示今日待复习项目
- 点击项目进入详情，查看复习进度
- 完成复习后点击对应阶段按钮打钩
- 所有阶段完成后，项目自动归档

### 使用小组件
1. 在桌面右键 → 编辑小组件
2. 搜索 "艾伦耶格尔" 或 "记忆"
3. 选择 "今日艾伦耶格尔" 小组件
4. 拖拽到桌面或通知中心

### 批量管理
1. 点击工具栏 "☑" 按钮进入批量模式
2. 勾选需要操作的项目
3. 点击工具栏删除按钮（带确认弹窗）

---

## 技术架构

- **UI 框架**：SwiftUI (macOS)
- **数据持久化**：UserDefaults + App Group
- **小组件**：WidgetKit (TimelineProvider)
- **通知**：UserNotifications
- **签名**：Apple 开发证书 + 无 provisioning profile（永不过期）

### 项目结构

```
艾宾浩斯记忆曲线工具/
├── 艾伦耶格尔.xcodeproj/             # Xcode 工程
├── 艾伦耶格尔遗忘曲线/                # 主应用源码
│   ├── ContentView.swift             # 主界面布局
│   ├── MainViewModel.swift           # 核心业务逻辑
│   ├── MemoryItemModel.swift         # 数据模型
│   ├── PersistenceController.swift   # 数据持久化
│   ├── NotificationManager.swift     # 通知管理
│   ├── WidgetSharedStore.swift       # 小组件数据共享
│   └── Assets.xcassets/              # 资源（含 AppIcon）
├── 艾伦耶格尔今日小组件/              # 桌面小组件源码
│   ├── TodayReviewWidget.swift       # 小组件实现
│   └── Info.plist                   # 小组件配置
├── build_dmg.sh                     # 一键构建 DMG
└── README.md
```

---

## 版本记录

### v1.0.0 (2026-05-21)
- 🎉 首个正式发布
- ✅ Apple 开发证书签名，无 provisioning profile，永不过期
- ✅ 桌面小组件完整可用
- ✅ 无需 Xcode，拖拽安装即可
- ✅ DMG 一键安装包
- 🔧 修复 provisioning profile 7 天过期问题
- 🔧 ad-hoc 签名 + dev cert 重签混合方案
- 📝 含完整中文 README 和安装说明

---

## 许可证

MIT License

---

*Made with ❤️ on macOS*
