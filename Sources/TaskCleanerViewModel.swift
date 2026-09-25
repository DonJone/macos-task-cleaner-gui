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

    private var timerCancellable: AnyCancellable?
    private var workspaceObservers: [NSObjectProtocol] = []

    public init() {
        refresh(silent: true)
    }

    deinit {
        timerCancellable?.cancel()
        let nc = NSWorkspace.shared.notificationCenter
        for obs in workspaceObservers {
            nc.removeObserver(obs)
        }
    }

    public func refresh(silent: Bool = false) {
        Task {
            if !silent {
                isWorking = true
            }

            let result = await Task.detached {
                MTCBridge.shared.fetchSummary()
            }.value

            self.summary = result

            if !silent {
                self.isWorking = false
            }
        }
    }

    // MARK: - 实时前台进程监听系统 (Live Monitoring)
    public func startLiveMonitoring() {
        // 1. 弹出瞬间立即执行一次静默刷新
        refresh(silent: true)

        // 2. 开启高频心跳 (每 1.5 秒自动同步一次进程表)
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 1.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, !self.isWorking else { return }
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
                self?.refresh(silent: true)
            }
        }

        let termObs = nc.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refresh(silent: true)
            }
        }

        let actObs = nc.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refresh(silent: true)
            }
        }

        workspaceObservers = [launchObs, termObs, actObs]
    }

    public func stopLiveMonitoring() {
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
        statusMessage = "正在结束进程..."

        Task {
            let success = await Task.detached {
                MTCBridge.shared.executeClean(force: force, purge: purge)
            }.value

            if success {
                self.statusMessage = "进程已结束"
            } else {
                self.statusMessage = "部分进程未响应"
            }

            self.isWorking = false
            self.refresh(silent: true)

            try? await Task.sleep(nanoseconds: 2_000_000_000)
            self.statusMessage = nil
        }
    }

    public func whitelistApp(_ app: TargetAppEntry) {
        guard !isWorking else { return }
        isWorking = true
        statusMessage = "已将 \(app.name) 加入白名单"

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

    public func openConfigFile() {
        MTCBridge.shared.openConfigFile()
    }
}
