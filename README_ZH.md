# macOS Task Cleaner GUI (`TaskCleaner.app`)

<p align="left">
  <a href="README.md">English</a> | <a href="README_ZH.md">简体中文</a>
</p>

面向 macOS 的状态栏常驻任务清场图形界面客户端。采用原生 Swift 与 SwiftUI 架构结合 AppKit 深度集成开发，提供轻量、现代、零弹窗打扰的前台任务清理与白名单管理体验。

---

## 界面效果展示

| 状态栏常驻浮层客户端 (`TaskCleaner.app`) | 配套命令行向导 (`mtc -i`) |
| :---: | :---: |
| <img src="docs/images/gui-menubar.png" width="340" alt="macOS Task Cleaner 菜单栏界面" /> | <img src="docs/images/cli-interactive.png" width="480" alt="macOS Task Cleaner 交互式终端向导" /> |

---

## 核心特性

* **原生菜单栏常驻 (Menu Bar Extra)**：优雅驻留在 macOS 顶部菜单栏，采用纯净白色药丸镂空 X 图标，实时展示未受保护的前台活跃进程计数。
* **现代交互浮窗 (Window Style Popover)**：单键点击菜单栏图标即刻展开半透明浮层面板，支持高精度视网膜应用图标渲染与 Bundle ID 显示。
* **智能自适应高度**：列表高度根据首次打开时的进程数量智能适配（最少容纳 3 个，最多容纳 6 个，超出自动平滑滚动），杜绝界面跳动。
* **独立结束与白名单全功能管理**：
  * **单应用独立结束**：列表项右侧提供小垃圾桶图标，支持精准单独退出特定进程；
  * **竖向拓展菜单 (`⋮`)**：提供一键加入白名单并持久化写入 `~/.config/mtc/config.toml`，支持快速复制 Bundle ID；
  * **已保护应用管理**：切换至“已保护”标签页可直接查看所有白名单应用，并支持随时一键移出白名单。
* **无损分级降级清场**：高亮“结束”按钮触发 `SIGTERM -> 宽限期轮询 -> SIGKILL` 三段式安全退出协议，绕过阻塞式保存确认弹窗。
* **对标系统级实用工具质感**：严格遵循 Apple HIG 规范，应用图标与 Terminal、Activity Monitor 属于同一监视器暗屏家族风格。
* **原生适配 24 种国际主流语言与自动识别**：智能跟随 macOS 系统的首选语言偏好自动匹配，涵盖英语、简体中文、繁体中文、日语、韩语、法语、德语、西班牙语、葡萄牙语、意大利语、俄语、荷兰语、波兰语、土耳其语、阿拉伯语、泰语、越南语、印尼语、瑞典语、丹麦语、挪威语、芬兰语、捷克语、乌克兰语，并在底栏提供即时语言切换菜单。
* **首次开机自启动引导与常驻守护**：首次打开时提供优雅的原生自启动引导卡片，基于 macOS 13+ 原生 `SMAppService` 框架构建，支持在设置菜单随时一键开关开机启动状态。

---

## 编译与打包

要求 macOS 13.0+ 及 Swift 5.9+ / Xcode 环境：

```bash
git clone https://github.com/DonJone/macos-task-cleaner-gui.git
cd macos-task-cleaner-gui

# 使用内置脚本一键编译并组装 TaskCleaner.app
./scripts/build_app.sh

# 移动至应用程序目录
cp -R build/TaskCleaner.app /Applications/
open /Applications/TaskCleaner.app
```

---

## 项目代码结构

* `Sources/TaskCleanerApp.swift`：应用程序入口与 `MenuBarExtra` 声明、托盘原生矢量绘制
* `Sources/TaskCleanerMenuView.swift`：SwiftUI 交互浮层面板、动态高度协调器、应用行视图与操作菜单
* `Sources/TaskCleanerViewModel.swift`：状态机管理、异步扫描与清场调度
* `Sources/MTCBridge.swift`：与底层 `mtc` 引擎及 TOML 配置的通信桥接层
* `Sources/Models.swift`：数据模型定义与应用图标动态提取
* `scripts/build_app.sh`：自动编译与 `TaskCleaner.app` 打包脚本
* `scripts/generate_app_icon.swift`：应用官方 AppIcon 矢量生成器

---

## 关联项目

* **核心算法与进程引擎库 (Rust)**：[macos-task-cleaner-core](https://github.com/DonJone/macos-task-cleaner-core)
* **命令行客户端 (Rust)**：[macos-task-cleaner-cli](https://github.com/DonJone/macos-task-cleaner-cli)

---

## 许可协议

MIT License. Copyright (c) 2026 DonJone.
