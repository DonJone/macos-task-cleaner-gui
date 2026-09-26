<p align="center">
  <img src="docs/images/app-icon-128.png" width="128" height="128" alt="Task Cleaner 应用图标" />
</p>

<h1 align="center">Task Cleaner</h1>

<p align="center">
  <strong>面向 macOS 的轻量、工程级状态栏任务清场与白名单管理客户端</strong>
</p>

<p align="center">
  <a href="README.md">English</a> | <a href="README_ZH.md">简体中文</a>
</p>

<p align="center">
  <a href="https://apple.com/macos"><img src="https://img.shields.io/badge/平台-macOS%2013%2B-000000?logo=apple&logoColor=white" alt="平台: macOS 13+" /></a>
  <img src="https://img.shields.io/badge/架构-Apple%20Silicon%20%7C%20AMD64-blue" alt="架构: Apple Silicon | AMD64" />
  <a href="https://swift.org/"><img src="https://img.shields.io/badge/编程语言-Swift%205.9%2B-F05138?logo=swift&logoColor=white" alt="Swift: 5.9+" /></a>
  <img src="https://img.shields.io/badge/界面库-SwiftUI%20%7C%20AppKit-007AFF?logo=swift&logoColor=white" alt="UI: SwiftUI | AppKit" />
  <a href="https://brew.sh/"><img src="https://img.shields.io/badge/Homebrew-支持%20Cask%20安装-orange?logo=homebrew&logoColor=white" alt="Homebrew: 支持 Cask 安装" /></a>
  <a href="https://www.rust-lang.org/"><img src="https://img.shields.io/badge/核心引擎-Rust-dea584?logo=rust&logoColor=white" alt="核心引擎: Rust" /></a>
  <img src="https://img.shields.io/badge/国际化-24%20种常用语言-teal" alt="语言: 24 种语言" />
  <a href="LICENSE"><img src="https://img.shields.io/badge/开源协议-GNU%20AGPLv3-blue" alt="开源协议: GNU AGPLv3" /></a>
  <a href="COMMERCIAL.md"><img src="https://img.shields.io/badge/商业许可-可授权-orange" alt="商业许可: 可授权" /></a>
</p>

面向 macOS 状态栏的原生前台任务清场与白名单管理应用。基于 Swift 与 SwiftUI 原生开发，底层深度集成高性能 `macos-task-cleaner-core` Rust 引擎。

---

## 界面效果展示

### 菜单栏常驻交互浮窗

<p align="center">
  <img src="docs/images/gui-main-zh.png" width="380" alt="macOS Task Cleaner 菜单栏常驻浮层" />
</p>

### 伴随终端交互向导与清场报告

| 终端交互向导 (`mtc -i`) | 批量清场执行报告 (`mtc --execute`) |
| :---: | :---: |
| <img src="docs/images/cli-interactive-zh.png" width="460" alt="macOS Task Cleaner 交互式终端向导" /> | <img src="docs/images/cli-exec-zh.png" width="460" alt="macOS Task Cleaner 批量清场执行报告" /> |

---

## 核心特性

* **原生菜单栏常驻 (Menu Bar Extra)**：优雅驻留在 macOS 顶部菜单栏，采用纯净白色药丸镂空图标，实时展示未受保护的前台活跃进程计数。
* **三段式清晰状态栏统计**：
  * **待清理前台任务**：实时统计当前命中清理范围、即将被退出的前台应用数量。
  * **保留常驻 / 已保护**：展示处于 L1 至 L4 各保护层级中的应用总数。
  * **查看全部活动应用**：展开查看当前系统所有活跃前台图形应用。
* **精细化单任务控制**：
  * **单应用独立结束**：列表项右侧提供小垃圾桶图标，支持精准单独退出特定进程。
  * **一键加白与取消**：列表项右侧提供加锁/盾牌图标，点击可一键添加至用户白名单或移除保护。
* **一键全部清理**：点击底部的“全部清理”按钮，瞬时优雅平稳退出全部未加白的前台应用。
* **原生 AppKit 访达 (Finder) 退出协议**：通过调用 `NSRunningApplication.terminate()` 退出访达，使系统守护进程 `launchd` 识别为自愿退出，彻底解决传统 POSIX `kill` 导致的“闪退又瞬间弹回”复活死循环。
* **无损分级降级清场**：触发 `SIGTERM -> 宽限期轮询 -> SIGKILL` 三段式安全退出协议，绕过应用层阻塞式保存确认弹窗。
* **对标系统级实用工具质感**：严格遵循 Apple HIG 规范，采用深色监视器屏幕基底、暗调微网格与微浮雕操作按钮。
* **原生适配 24 种国际主流语言与自动识别**：智能跟随 macOS 系统的首选语言偏好自动匹配，涵盖英语、简体中文、繁体中文、日语、韩语、法语、德语、西班牙语、葡萄牙语、意大利语、俄语、荷兰语、波兰语、土耳其语、阿拉伯语、泰语、越南语、印尼语、瑞典语、丹麦语、挪威语、芬兰语、捷克语、乌克兰语，并在底栏提供即时语言切换菜单。
* **开机自启动引导与常驻守护**：基于 macOS 13+ 原生 `SMAppService` 框架构建，零后台守护常驻开销，支持在设置菜单随时一键开关。

---

## 下载与快速安装

### 方式一：通过 Homebrew Cask 安装 (推荐)

```bash
# 添加官方 Tap 软件源
brew tap macos-task-cleaner/tap

# 一键安装图形客户端 (包含内嵌的命令行工具)
brew install --cask task-cleaner

# 启动应用
open -a "Task Cleaner"
```

### 方式二：推荐 DMG 拖拽式安装镜像

前往 [GitHub Releases](https://github.com/macos-task-cleaner/macos-task-cleaner-gui/releases/latest) 直接下载适用于您 Mac 架构的安装镜像：

| 硬件架构 | 适用设备 | 安装包直链下载 |
| :--- | :--- | :--- |
| **Apple Silicon** (`arm64`) | Apple M1 / M2 / M3 / M4 芯片 Mac | [TaskCleaner-macOS-arm64.dmg](https://github.com/macos-task-cleaner/macos-task-cleaner-gui/releases/latest/download/TaskCleaner-macOS-arm64.dmg) |
| **AMD64 / Intel** (`x86_64`) | Intel 处理器 / AMD64 架构 Mac | [TaskCleaner-macOS-x86_64.dmg](https://github.com/macos-task-cleaner/macos-task-cleaner-gui/releases/latest/download/TaskCleaner-macOS-x86_64.dmg) |
| **Universal** (`universal`) | 兼容全部 Apple Silicon 及 Intel Mac | [TaskCleaner-macOS-universal.dmg](https://github.com/macos-task-cleaner/macos-task-cleaner-gui/releases/latest/download/TaskCleaner-macOS-universal.dmg) |

双击打开下载的 `.dmg` 文件后，直接将 `Task Cleaner.app` 拖入 `Applications` 文件夹即可完成安装。

### 方式三：源码本地编译

要求 macOS 13.0+ 及 Swift 5.9+ / Xcode 环境：

```bash
git clone https://github.com/macos-task-cleaner/macos-task-cleaner-gui.git
cd macos-task-cleaner-gui

# 使用内置脚本一键编译并组装（支持参数: arm64 | x86_64 | universal | all | native）
./scripts/build_app.sh

# 移动至应用程序目录并启动
cp -R build/TaskCleaner.app /Applications/
open /Applications/TaskCleaner.app
```

---

## 项目代码结构

* `Sources/TaskCleanerApp.swift`：应用程序入口与 `MenuBarExtra` 声明、托盘原生矢量绘制
* `Sources/TaskCleanerMenuView.swift`：SwiftUI 交互浮层面板、动态高度协调器、应用行视图与操作菜单
* `Sources/TaskCleanerViewModel.swift`：状态机管理、异步扫描与清场调度
* `Sources/MTCBridge.swift`：与底层 `mtc` 引擎及 TOML 配置的通信桥接层
* `Sources/LaunchAtLoginManager.swift`：原生 `SMAppService` 开机自启动集成与首次引导协调器
* `Sources/I18n.swift`：24 种常用语言国际化注册表与运行时多语言切换器
* `Sources/Models.swift`：数据模型定义与应用图标动态提取
* `scripts/build_app.sh`：自动编译、`TaskCleaner.app` 组装及 DMG 可视化拖拽安装盘生成脚本
* `scripts/generate_app_icon.swift`：应用官方 AppIcon 矢量生成器
* `scripts/generate_dmg_background.swift`：2x Retina 分辨率 DMG 拖拽安装背景图生成器

---

## 关联项目

* **核心算法与进程引擎库 (Rust)**：[macos-task-cleaner-core](https://github.com/macos-task-cleaner/macos-task-cleaner-core)
* **命令行客户端 (Rust)**：[macos-task-cleaner-cli](https://github.com/macos-task-cleaner/macos-task-cleaner-cli)

---

## 许可协议与商业授权

本项目采用双重授权模式（Dual-Licensing Model）：

1. **开源许可证**：遵循 **GNU Affero General Public License v3.0 (AGPLv3)** 协议。个人学习、学术研究与非商业开源项目可免费使用与修改；凡修改或基于本项目构建衍生作品（包括通过网络提供交互服务的 SaaS / 云端调用形态），均须向公众无偿开源全部衍生代码。详见 [LICENSE](LICENSE)。
2. **商业许可协议 (Commercial License)**：面向企业客户、闭源专有产品集成、白标重命名销售或无法遵守 AGPLv3 传染性条款的商业场景，必须事先取得商业授权许可证。详见 [COMMERCIAL.md](COMMERCIAL.md)。
3. **商标与品牌保护**：项目名称、标识图形与应用图标均受版权及商标保护。任何二次分发或分叉 (Fork) 版本必须彻底去除官方品牌元素。详见 [TRADEMARK.md](TRADEMARK.md)。

Copyright (c) 2026 DonJone. 保留所有权利。
