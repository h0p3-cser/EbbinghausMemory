# 艾伦耶格尔记忆曲线

<p align="center">
  <img src="艾伦耶格尔遗忘曲线/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" alt="App Icon" width="128" />
</p>

<p align="center">
  <strong>基于艾伦耶格尔遗忘曲线的 macOS 记忆复习提醒工具</strong>
</p>

---

## 功能特色

### 🧠 智能复习计划
- 根据艾伦耶格尔遗忘曲线自动生成复习时间表
- 支持 8 个复习阶段：20分钟 → 1小时 → 9小时 → 1天 → 2天 → 6天 → 14天 → 31天
- 每次完成复习自动推进到下一阶段

### 📂 分组管理
- 支持创建彩色分组文件夹，按主题整理记忆项目
- 无分组的项目直接在侧边栏列表中显示
- 可拖拽移动项目至不同分组

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
| Xcode | 15.4+ (仅构建时需要) |

---

## 安装

### 方式一：直接下载
从 [Releases](https://github.com/h0pe_wsv/EbbinghausMemory/releases) 下载最新版 `.app`，拖入 `/Applications` 即可。

### 方式二：源码构建
```bash
git clone https://github.com/h0pe_wsv/EbbinghausMemory.git
cd EbbinghausMemory
open 艾伦耶格尔.xcodeproj
```

然后在 Xcode 中：
1. 选择 `艾伦耶格尔遗忘曲线` scheme
2. Product → Archive
3. 导出或直接运行

---

## 使用指南

### 创建记忆项目
1. 点击左下角 **+** 按钮
2. 输入记忆项目名称（如"英语单词 List 1"）
3. 选择创建日期和所属分组（可选）
4. 点击"创建"

### 每日复习
- 打开应用后，左侧列表显示今日待复习项目
- 点击项目进入详情，查看复习进度
- 完成复习后点击对应阶段按钮打钩
- 所有阶段完成后，项目自动归档

### 使用小组件
1. 在桌面右键 → 编辑小组件
2. 搜索"艾伦耶格尔"或"记忆"
3. 选择"今日艾伦耶格尔"小组件
4. 拖拽到桌面或通知中心

### 批量管理
1. 点击工具栏"☑"按钮进入批量模式
2. 勾选需要操作的项目
3. 点击工具栏删除按钮（带确认弹窗）

---

## 技术架构

- **UI 框架**：SwiftUI (macOS)
- **数据持久化**：JSON 文件 + App Group 共享
- **小组件**：WidgetKit (TimelineProvider)
- **通知**：UserNotifications
- **构建工具**：Xcode 15.4+, Swift 5.9+
- **最低部署目标**：macOS 12.0

### 项目结构

```
艾宾浩斯记忆曲线工具/
├── 艾伦耶格尔.xcodeproj/       # Xcode 工程
├── 艾伦耶格尔遗忘曲线/          # 主应用源码
│   ├── ContentView.swift       # 主界面布局
│   ├── MainViewModel.swift     # 核心业务逻辑
│   ├── MemoryItemModel.swift   # 数据模型
│   ├── PersistenceController.swift  # 数据持久化
│   ├── NotificationManager.swift    # 通知管理
│   ├── WidgetSharedStore.swift # 小组件数据共享
│   └── Assets.xcassets/       # 资源（含 AppIcon）
├── 艾伦耶格尔今日小组件/        # 桌面小组件源码
│   ├── TodayReviewWidget.swift # 小组件实现
│   └── Info.plist             # 小组件配置
└── README.md
```

---

## 许可证

MIT License

---

## 致谢

- 赫尔曼·艾伦耶格尔 (Hermann Ebbinghaus) - 遗忘曲线理论的奠基人
- Apple SwiftUI & WidgetKit 团队

---

*Made with ❤️ on macOS*

---

## 自动刷新 Provisioning Profile

开发签名证书每 7 天过期。项目内置了自动刷新脚本，每天凌晨自动重建并部署。

### 首次配置

```bash
# 1. 加载 LaunchAgent（只需一次）
launchctl load ~/Library/LaunchAgents/com.local.EbbinghausMemory.refresh.plist

# 2. 手动测试一次
bash refresh_profile.sh

# 3. 查看日志
tail ~/Library/Logs/com.local.EbbinghausMemory.refresh.log
```

之后每天凌晨 3:00 自动执行，无需人工干预。
