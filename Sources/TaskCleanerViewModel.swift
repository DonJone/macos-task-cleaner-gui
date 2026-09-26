import Foundation
import SwiftUI
import AppKit
import Combine

public enum CleanerTab: Int, CaseIterable, Identifiable {
    case targets = 0
    case protected = 1
    case all = 2

    public var id: Int { rawValue }
}

@MainActor
public class TaskCleanerViewModel: ObservableObject {
    @Published public var summary: DryRunSummary?
    @Published public var isWorking: Bool = false
    @Published public var statusMessage: String?
    @Published public var selectedTab: CleanerTab = .targets
    @Published public var initialTargetCapacity: Int = 3

    public static weak var shared: TaskCleanerViewModel?

    public var isMenuTracking: Bool = false
    private var menuObservers: [NSObjectProtocol] = []
    private var hasCapturedSessionCapacity: Bool = false
    private var timerCancellable: AnyCancellable?
    private var workspaceObservers: [NSObjectProtocol] = []

    public init() {
        Self.shared = self
        _ = GlobalShortcutManager.shared

        let dc = NotificationCenter.default
        let beginObs = dc.addObserver(
            forName: NSMenu.didBeginTrackingNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.isMenuTracking = true
            }
        }
        let endObs = dc.addObserver(
            forName: NSMenu.didEndTrackingNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.isMenuTracking = false
            }
        }
        menuObservers = [beginObs, endObs]

        refresh(silent: true)
    }

    deinit {
        timerCancellable?.cancel()
        for obs in menuObservers {
            NotificationCenter.default.removeObserver(obs)
        }
        let nc = NSWorkspace.shared.notificationCenter
        for obs in workspaceObservers {
            nc.removeObserver(obs)
        }
    }

    private func updateInitialCapacityIfNeeded(from summary: DryRunSummary?) {
        guard !hasCapturedSessionCapacity else { return }
        if let count = summary?.target_count {
            self.initialTargetCapacity = min(6, max(3, count))
            self.hasCapturedSessionCapacity = true
        }
    }

    public func refresh(silent: Bool = false) {
        guard !isMenuTracking else { return }
        Task {
            if !silent {
                isWorking = true
            }

            let result = await Task.detached {
                MTCBridge.shared.fetchSummary()
            }.value

            guard !self.isMenuTracking else {
                if !silent { self.isWorking = false }
                return
            }

            if self.summary != result {
                self.summary = result
                self.updateInitialCapacityIfNeeded(from: result)
            }

            if !silent {
                self.isWorking = false
            }
        }
    }

    // MARK: - 实时前台进程监听系统 (Live Monitoring)
    public func startLiveMonitoring() {
        // 每次托盘面板重新打开时，重置会话锁，捕获第一次打开时的待结束进程数量
        hasCapturedSessionCapacity = false
        updateInitialCapacityIfNeeded(from: summary)

        // 1. 弹出瞬间立即执行一次静默刷新
        refresh(silent: true)

        // 2. 开启心跳 (每 2 秒自动同步，在 default 模式下运行，菜单追踪时自动静默挂起)
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 2.0, on: .main, in: .default)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, !self.isWorking, !self.isMenuTracking else { return }
                self.refresh(silent: true)
            }

        // 3. 订阅 macOS 原生应用生命周期事件 (即时感知应用启动、退出与激活)
        stopWorkspaceObservers()
        let nc = NSWorkspace.shared.notificationCenter

        let launchObs = nc.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, !self.isMenuTracking else { return }
                self.refresh(silent: true)
            }
        }

        let termObs = nc.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, !self.isMenuTracking else { return }
                self.refresh(silent: true)
            }
        }

        let actObs = nc.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, !self.isMenuTracking else { return }
                self.refresh(silent: true)
            }
        }

        workspaceObservers = [launchObs, termObs, actObs]
    }

    public func stopLiveMonitoring() {
        hasCapturedSessionCapacity = false
        timerCancellable?.cancel()
        timerCancellable = nil
        stopWorkspaceObservers()
    }

    private func stopWorkspaceObservers() {
        let nc = NSWorkspace.shared.notificationCenter
        for obs in workspaceObservers {
            nc.removeObserver(obs)
        }
        workspaceObservers.removeAll()
    }

    // MARK: - 核心执行操作
    public func cleanAll(force: Bool = false, purge: Bool = false) {
        guard !isWorking else { return }
        isWorking = true
        statusMessage = I18n.shared.t(.status_terminating_all)

        Task {
            let success = await Task.detached {
                MTCBridge.shared.executeClean(force: force, purge: purge)
            }.value

            if success {
                self.statusMessage = I18n.shared.t(.status_all_terminated)
            } else {
                self.statusMessage = I18n.shared.t(.status_some_unresponsive)
            }

            self.isWorking = false
            self.refresh(silent: true)

            try? await Task.sleep(nanoseconds: 2_000_000_000)
            self.statusMessage = nil
        }
    }

    public func triggerGlobalShortcutClean() {
        guard !isWorking else { return }
        cleanAll(force: false, purge: false)
    }

    public func terminateTarget(_ app: TargetAppEntry) {
        guard !isWorking else { return }
        isWorking = true
        statusMessage = I18n.shared.format(.status_terminating_app, app.localizedName(in: I18n.shared))

        Task {
            let success = await Task.detached {
                MTCBridge.shared.terminateProcess(pid: app.pid)
            }.value

            if success {
                self.statusMessage = I18n.shared.format(.status_app_terminated, app.localizedName(in: I18n.shared))
            } else {
                self.statusMessage = I18n.shared.format(.status_app_terminate_failed, app.localizedName(in: I18n.shared))
            }

            self.isWorking = false
            self.refresh(silent: true)

            try? await Task.sleep(nanoseconds: 1_500_000_000)
            self.statusMessage = nil
        }
    }

    public func whitelistApp(_ app: TargetAppEntry) {
        guard !isWorking else { return }
        isWorking = true
        statusMessage = I18n.shared.format(.status_added_whitelist, app.localizedName(in: I18n.shared))

        Task {
            let identifier = !app.bundle_id.isEmpty ? app.bundle_id : app.name
            _ = await Task.detached {
                MTCBridge.shared.addToWhitelist(identifier: identifier)
            }.value

            self.isWorking = false
            self.refresh(silent: true)

            try? await Task.sleep(nanoseconds: 2_000_000_000)
            self.statusMessage = nil
        }
    }

    public func unprotectApp(_ app: ProtectedAppEntry) {
        guard !isWorking else { return }
        isWorking = true
        statusMessage = I18n.shared.format(.status_removed_whitelist, app.localizedName(in: I18n.shared))

        Task {
            let identifier = !app.bundle_id.isEmpty ? app.bundle_id : app.name
            _ = await Task.detached {
                MTCBridge.shared.removeFromWhitelist(identifier: identifier)
            }.value

            self.isWorking = false
            self.refresh(silent: true)

            try? await Task.sleep(nanoseconds: 2_000_000_000)
            self.statusMessage = nil
        }
    }

    public func openConfigFile() {
        MTCBridge.shared.openConfigFile()
    }

    public func openConfigDirectory() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let dir = home.appendingPathComponent(".config/taskcleaner")
        if FileManager.default.fileExists(atPath: dir.path) {
            NSWorkspace.shared.open(dir)
        } else {
            let legacy = home.appendingPathComponent(".config/mtc")
            NSWorkspace.shared.open(legacy)
        }
    }

    public func revealInFinder(pid: Int) {
        if let app = NSRunningApplication(processIdentifier: pid_t(pid)),
           let url = app.bundleURL {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }

    public func copyToClipboard(text: String, label: String? = nil) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        if let label = label {
            self.statusMessage = label
            Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                self.statusMessage = nil
            }
        }
    }

    public func showAboutDialog() {
        let alert = NSAlert()
        alert.messageText = "Task Cleaner 0.1.0"
        alert.informativeText = """
        Copyright (c) 2026 DonJone. All rights reserved.

        Dual-Licensed: GNU AGPLv3 / Commercial License

        Free and open source for personal and community use under GNU AGPLv3.
        Commercial bundling, proprietary closed-source integration, SaaS operation, or white-labeling requires a commercial license.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Commercial Policy")
        alert.addButton(withTitle: "GitHub")

        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            if let url = URL(string: "https://github.com/macos-task-cleaner/macos-task-cleaner-gui/blob/main/COMMERCIAL.md") {
                NSWorkspace.shared.open(url)
            }
        } else if response == .alertThirdButtonReturn {
            if let url = URL(string: "https://github.com/macos-task-cleaner/macos-task-cleaner-gui") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
