# macOS Task Cleaner GUI (`TaskCleaner.app`)

<p align="left">
  <a href="README.md">English</a> | <a href="README_ZH.md">简体中文</a>
</p>

A lightweight, native macOS menu bar application designed for non-intrusive foreground task clearance and whitelist management. Built with Swift and SwiftUI, integrated seamlessly with the high-performance [macos-task-cleaner-core](https://github.com/DonJone/macos-task-cleaner-core) engine and [macos-task-cleaner-cli](https://github.com/DonJone/macos-task-cleaner-cli).

---

## Interface Showcase

| Native Menu Bar Popover (`TaskCleaner.app`) | Interactive CLI Companion (`mtc -i`) |
| :---: | :---: |
| <img src="docs/images/gui-menubar.png" width="340" alt="macOS Task Cleaner Menu Bar Interface" /> | <img src="docs/images/cli-interactive.png" width="480" alt="macOS Task Cleaner Interactive CLI" /> |

---

## Key Features

* **Native Menu Bar Extra**: Resides quietly in the macOS status bar with a pill-shaped template icon, displaying a live badge of active unexempted foreground tasks.
* **Modern Popover Panel**: Single-click access to a translucent, native popover showing active foreground applications, high-resolution icons, and Bundle Identifiers.
* **Dynamic Window Height**: Automatically adapts popover panel height to list size (holds 3 to 6 applications with smooth scrolling for larger lists).
* **Single-Task Termination & Whitelist Management**:
  * **Individual Trash Icon**: Terminate specific foreground applications instantly.
  * **Vertical Ellipsis Menu (`⋮`)**: Add applications permanently to `~/.config/mtc/config.toml` or copy Bundle Identifiers.
  * **Protected List Management**: Review and remove applications from the protection whitelist directly from the GUI.
* **Non-Intrusive POSIX Escalation**: Triggers `SIGTERM -> grace polling -> SIGKILL` via the underlying `mtc` bridge, bypassing modal save/confirm dialogs.
* **Authentic macOS System Utility Styling**: Employs dark monitor screen squircle aesthetics matching macOS Terminal and Activity Monitor.

---

## Build & Installation

Requires macOS 13.0+ (Ventura, Sonoma, Sequoia) and Swift 5.9+:

```bash
git clone https://github.com/DonJone/macos-task-cleaner-gui.git
cd macos-task-cleaner-gui

# Compile and package Release bundle
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
* `Sources/Models.swift`: Data models and high-resolution AppKit icon resolution.
* `scripts/build_app.sh`: Automated release compilation and App Bundle packaging script.
* `scripts/generate_app_icon.swift`: Native vector icon generator for `AppIcon.icns`.

---

## Related Projects

* **Core Engine Library (Rust)**: [macos-task-cleaner-core](https://github.com/DonJone/macos-task-cleaner-core)
* **Command-Line Interface (Rust)**: [macos-task-cleaner-cli](https://github.com/DonJone/macos-task-cleaner-cli)

---

## License

MIT License. Copyright (c) 2026 DonJone.
