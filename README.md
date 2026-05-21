# 艾伦耶格尔记忆曲线

<p align="center">
  <img src="艾伦耶格尔遗忘曲线/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" alt="App Icon" width="128" />
</p>

<p align="center">
  <strong>基于艾伦耶格尔遗忘曲线的 macOS 记忆复习提醒工具</strong>
</p>

<p align="center">
  <a href="https://github.com/h0p3-cser/EbbinghausMemory/releases"><img src="https://img.shields.io/badge/下载-DMG-blue" alt="下载"></a>
  <a><img src="https://img.shields.io/badge/macOS-12.0%2B-orange" alt="macOS"></a>
</p>

---

## 功能特色

- **智能复习计划** — 艾伦耶格尔遗忘曲线 8 阶段自动排程
- **分组管理** — 彩色分组文件夹，按主题整理
- **桌面小组件** — 今日复习一览，有任务时标题变绿
- **通知提醒** — 自定义时间 + macOS 原生通知
- **批量操作** — 多选 + 双重确认删除

---

## 系统要求

| 组件 | 最低版本 |
|------|----------|
| macOS | 12.0+ |
| 小组件 | macOS 14.0+ |

---

## 安装

### 📦 DMG 安装
1. 从 [Releases](https://github.com/h0p3-cser/EbbinghausMemory/releases) 下载最新 `.dmg`
2. 拖拽 App 到 Applications → 首次右键打开即可

### 🔨 源码构建
```bash
git clone https://github.com/h0p3-cser/EbbinghausMemory.git
cd EbbinghausMemory
bash build_dmg.sh
```

---

## 使用指南

| 操作 | 方式 |
|------|------|
| 创建项目 | 左下角 + → 输入名称 → 创建 |
| 每日复习 | 点击项目 → 详情 → 打钩完成 |
| 小组件 | 桌面右键 → 编辑小组件 → 搜索"艾伦耶格尔" |
| 批量管理 | 工具栏 ☑ → 勾选 → 删除 |

---

## 可持续性

| 场景 | 方案 |
|------|------|
| **有 Xcode** | DMG 内 `setup_auto_refresh.command` 一键安装，每天凌晨自动刷新凭证，永不过期 |
| **无 Xcode** | 小组件 7 天后失效，重新下载新版 DMG 即可恢复 |

---

## 项目结构

```
├── 艾伦耶格尔遗忘曲线/          # 主应用源码
├── 艾伦耶格尔今日小组件/        # 桌面小组件
├── build_dmg.sh                # 一键构建 DMG
├── setup_auto_refresh.command  # 自动刷新安装脚本
└── README.md
```

---

## 版本记录

### v1.0.1 (2026-05-21)
- 🐛 修复：桌面小组件无法显示（恢复 entitlements + provisioning profile）
- 🔧 签名方案：Apple 开发证书 + App Groups entitlements + 自动刷新
- 📦 更新 DMG 含安装说明和自动刷新脚本
- 📝 添加可持续性说明和完整版本记录

### v1.0.0 (2026-05-14)
- 🎉 首个正式发布
- ✅ 基础记忆曲线复习功能
- ✅ 分组管理 + 批量操作
- ✅ 桌面小组件
- ✅ 自定义通知提醒

---

## 许可证

MIT License
