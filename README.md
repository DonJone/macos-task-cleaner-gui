<p align="center">
  <img src="docs/images/app-icon-128.png" width="128" height="128" alt="Task Cleaner App Icon" />
</p>

<h1 align="center">Task Cleaner</h1>

<p align="center">
  <strong>Native macOS Menu Bar Foreground Process Cleaner & Whitelist Manager</strong>
</p>

<p align="center">
  <a href="README.md">English</a> | <a href="README_ZH.md">简体中文</a>
</p>

<p align="center">
  <a href="https://apple.com/macos"><img src="https://img.shields.io/badge/Platform-macOS%2013%2B-000000?logo=apple&logoColor=white" alt="Platform: macOS 13+" /></a>
  <img src="https://img.shields.io/badge/Architecture-Apple%20Silicon%20%7C%20AMD64-blue" alt="Architecture: Apple Silicon | AMD64" />
  <a href="https://swift.org/"><img src="https://img.shields.io/badge/Swift-5.9%2B-F05138?logo=swift&logoColor=white" alt="Swift: 5.9+" /></a>
  <img src="https://img.shields.io/badge/UI-SwiftUI%20%7C%20AppKit-007AFF?logo=swift&logoColor=white" alt="UI: SwiftUI | AppKit" />
  <a href="https://www.rust-lang.org/"><img src="https://img.shields.io/badge/Core%20Engine-Rust-dea584?logo=rust&logoColor=white" alt="Core Engine: Rust" /></a>
  <img src="https://img.shields.io/badge/Languages-24%20Locales-teal" alt="Languages: 24 Locales" />
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-GNU%20AGPLv3-blue" alt="License: GNU AGPLv3" /></a>
  <a href="COMMERCIAL.md"><img src="https://img.shields.io/badge/Commercial-License%20Available-orange" alt="Commercial License Available" /></a>
</p>

A native macOS menu bar status item application for high-precision foreground application cleanup and whitelist management. Built with Swift and SwiftUI on top of the high-performance `macos-task-cleaner-core` Rust engine.

---

## Visual Interface Showcase

<p align="center">
  <img src="docs/images/gui-main-en.png" width="380" alt="macOS Task Cleaner Menu Bar Popover Interface" />
</p>

---

## Key Features

* **Native Menu Bar Status Item**: Resides quietly in the macOS menu bar with a live badge displaying the number of active foreground tasks.
* **Three-Part Summary Dashboard**:
  * **Clear Foreground Apps**: Real-time counter of unwhitelisted foreground applications scheduled for cleanup.
  * **Keep Active / Protected**: Count of protected applications across L1-L4 whitelist tiers.
  * **Total Active Apps**: Quick overview of all discovered foreground graphical processes.
* **Granular Process Control**:
  * **Individual Trash Icon**: Terminate specific foreground applications instantly with a single click.
  * **One-Click Whitelist Toggle**: Add or remove applications from persistent configuration directly from the list.
* **Clean All One-Click Action**: Smoothly terminates all unexempted foreground tasks simultaneously.
* **Native AppKit Finder Voluntary Quit**: Quits Finder using AppKit `NSRunningApplication.terminate()` to prevent `launchd` from treating it as an abnormal crash and immediately respawning it.
* **Non-Intrusive POSIX Escalation**: Triggers `SIGTERM -> polling grace period -> SIGKILL` sequence, bypassing modal save/confirm dialogs without system friction.
* **Authentic macOS System Utility Styling**: Follows Apple Human Interface Guidelines with dark chassis aesthetics, technical micro-grid backgrounds, and crisp typography.
* **24 Global Languages & Automatic Locale Detection**: Automatically detects macOS system locale across 24 languages with seamless runtime switching.
* **Modern Launch at Login**: Native macOS 13+ `SMAppService` integration with zero background daemon overhead.

---

## Download & Quick Install

### Option 1: Drag-and-Drop DMG Installer (Recommended)

Download the pre-built, ready-to-use disk image for your Mac architecture from [GitHub Releases](https://github.com/macos-task-cleaner/macos-task-cleaner-gui/releases/latest):

| Architecture | Applicable Hardware | Direct Download Link |
| :--- | :--- | :--- |
| **Apple Silicon** (`arm64`) | Apple M1 / M2 / M3 / M4 Macs | [TaskCleaner-macOS-arm64.dmg](https://github.com/macos-task-cleaner/macos-task-cleaner-gui/releases/latest/download/TaskCleaner-macOS-arm64.dmg) |
| **AMD64 / Intel** (`x86_64`) | Intel-based Macs | [TaskCleaner-macOS-x86_64.dmg](https://github.com/macos-task-cleaner/macos-task-cleaner-gui/releases/latest/download/TaskCleaner-macOS-x86_64.dmg) |
| **Universal** (`universal`) | Compatible with all Macs | [TaskCleaner-macOS-universal.dmg](https://github.com/macos-task-cleaner/macos-task-cleaner-gui/releases/latest/download/TaskCleaner-macOS-universal.dmg) |

Open the `.dmg` file and drag `Task Cleaner.app` into your `Applications` directory.

### Option 2: Build from Source

Requires macOS 13.0+ and Xcode / Swift 5.9+:

```bash
git clone https://github.com/macos-task-cleaner/macos-task-cleaner-gui.git
cd macos-task-cleaner-gui

# Compile and package Release bundle (supports: arm64 | x86_64 | universal | all | native)
./scripts/build_app.sh

# Install to Applications folder
cp -R build/TaskCleaner.app /Applications/
open /Applications/TaskCleaner.app
```

---

## Project Structure

* `Sources/TaskCleanerApp.swift`: Application entry point and `MenuBarExtra` declaration with template tray icon.
* `Sources/TaskCleanerMenuView.swift`: SwiftUI interactive popover, dynamic height coordinator, list rows, and action menus.
* `Sources/TaskCleanerViewModel.swift`: State machine management, process scanning, and asynchronous termination dispatch.
* `Sources/MTCBridge.swift`: Communication bridge with the `mtc` core engine and TOML configuration files.
* `Sources/LaunchAtLoginManager.swift`: Native `SMAppService` launch-at-login integration and first-run onboarding coordinator.
* `Sources/I18n.swift`: 24-language internationalization registry and runtime locale switcher.
* `Sources/Models.swift`: Data models and high-resolution AppKit icon resolution.
* `scripts/build_app.sh`: Automated release compilation, App Bundle assembly, and DMG drag-and-drop packaging.
* `scripts/generate_app_icon.swift`: Native vector icon generator for `AppIcon.icns`.
* `scripts/generate_dmg_background.swift`: Retina 2x DMG drag-and-drop installer background generator.

---

## Command-Line Tool Companion

If you prefer terminal-driven workflows, shell scripts, or automation shortcuts, you can also install the companion command-line client **`mtc`**:

* **CLI Repository**: [macos-task-cleaner-cli](https://github.com/macos-task-cleaner/macos-task-cleaner-cli)
* **Core Engine**: [macos-task-cleaner-core](https://github.com/macos-task-cleaner/macos-task-cleaner-core)

The GUI application shares the same underlying configuration file (`~/.config/mtc/config.toml`) with the CLI tool, so whitelist rules added via the GUI or terminal stay synchronized automatically.

---

## License & Commercial Terms

This project is dual-licensed:

1. **Open-Source License**: Licensed under the **GNU Affero General Public License v3.0 (AGPLv3)** for individual, academic, and non-commercial open-source usage. Under this license, any derivative work, modification, or network-accessible service utilizing this codebase must release its complete corresponding source code under the AGPLv3. See [LICENSE](LICENSE) for details.
2. **Commercial License**: For enterprise deployment, proprietary closed-source bundling, white-labeling, or integration into commercial utilities where AGPLv3 compliance cannot be met, a separate commercial license is required. See [COMMERCIAL.md](COMMERCIAL.md) for licensing terms and acquisition details.
3. **Trademark Policy**: All product names, logos, and icon assets are protected. Forked distributions must be de-branded. See [TRADEMARK.md](TRADEMARK.md).

Copyright (c) 2026 DonJone. All rights reserved.
