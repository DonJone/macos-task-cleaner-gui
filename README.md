# macOS Task Cleaner GUI (`TaskCleaner.app`)

面向 macOS 的状态栏常驻任务清场图形界面客户端。采用原生 SwiftUI 架构与 AppKit 深度集成开发，提供轻量、现代、一键式的后台任务清理与白名单管理体验。

---

## 核心特性

* **原生菜单栏常驻 (Menu Bar Extra)**：优雅驻留在 macOS 顶部菜单栏，实时展示当前处于活跃状态的前台应用数量徽标。
* **现代浮窗面板 (Window Style Popover)**：点击菜单栏图标即刻展开半透明浮层面板，支持直观查看所有前台应用与真实高清图标。
* **一键平滑清场**：高亮大按钮直观触发三段式优雅下线 (`SIGTERM -> 轮询 -> SIGKILL`)，完全绕过各类阻塞式确认弹窗。
* **一键加白名单**：在应用列表中直接点击“+ 白名单”，立即将指定应用持久化写入全局配置文件 `~/.config/mtc/config.toml` 并自动刷新状态。
* **白名单折叠视图**：支持快速查看已被系统四级白名单保护的应用及其匹配规则。
* **深度解耦与协同**：底层与 [macos-task-cleaner-core](https://github.com/DonJone/macos-task-cleaner-core) 及 [macos-task-cleaner-cli](https://github.com/DonJone/macos-task-cleaner-cli) 共享统一的状态逻辑与配置源。

---

## 编译与打包

要求 macOS 13.0+ 及 Swift 5.9+ 环境：

```bash
git clone https://github.com/DonJone/macos-task-cleaner-gui.git
cd macos-task-cleaner-gui

# 使用内置脚本一键编译并生成 TaskCleaner.app
./scripts/build_app.sh
```

打包完成后的应用程序位于 `build/TaskCleaner.app`。

---

## 安装运行

### 移动至应用程序目录

```bash
# 复制至全局应用程序目录
cp -R build/TaskCleaner.app /Applications/
# 或仅安装至当前用户
cp -R build/TaskCleaner.app ~/Applications/
```

### 直接启动

```bash
open /Applications/TaskCleaner.app
```

启动后即可在 macOS 顶部菜单栏看到扫把图标，点击即可进行全流程交互。

---

## 项目代码结构

* `Sources/TaskCleanerApp.swift`：应用程序入口与 `MenuBarExtra` 声明
* `Sources/TaskCleanerMenuView.swift`：SwiftUI 交互浮层面板、前台应用列表与行视图
* `Sources/TaskCleanerViewModel.swift`：状态机管理、异步扫描与清场调度
* `Sources/MTCBridge.swift`：与底座 `mtc` 引擎及 TOML 配置的通信桥接层
* `Sources/Models.swift`：数据模型定义与应用图标动态提取
* `scripts/build_app.sh`：自动编译与 `TaskCleaner.app` 打包脚本

---

## 关联项目

* **核心算法与进程引擎库**：[macos-task-cleaner-core](https://github.com/DonJone/macos-task-cleaner-core)
* **命令行客户端**：[macos-task-cleaner-cli](https://github.com/DonJone/macos-task-cleaner-cli)

---

## 许可协议

MIT License
