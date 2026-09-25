import Foundation
import SwiftUI
import Combine

public enum CleanerTab: Int, CaseIterable, Identifiable {
    case targets = 0
    case protected = 1

    public var id: Int { rawValue }
}

@MainActor
public class TaskCleanerViewModel: ObservableObject {
    @Published public var summary: DryRunSummary?
    @Published public var isWorking: Bool = false
    @Published public var statusMessage: String?
    @Published public var selectedTab: CleanerTab = .targets

    public init() {
        refresh()
    }

    public func refresh() {
        Task {
            isWorking = true
            let result = await Task.detached {
                MTCBridge.shared.fetchSummary()
            }.value

            self.summary = result
            self.isWorking = false
        }
    }

    public func cleanAll(force: Bool = false, purge: Bool = false) {
        guard !isWorking else { return }
        isWorking = true
        statusMessage = "正在终止目标进程..."

        Task {
            let success = await Task.detached {
                MTCBridge.shared.executeClean(force: force, purge: purge)
            }.value

            if success {
                self.statusMessage = "目标进程已全部终止"
            } else {
                self.statusMessage = "部分进程受系统保护或未正常响应"
            }

            // Refresh state after cleaning
            try? await Task.sleep(nanoseconds: 300_000_000)
            self.refresh()

            try? await Task.sleep(nanoseconds: 2_000_000_000)
            self.statusMessage = nil
        }
    }

    public func whitelistApp(_ app: TargetAppEntry) {
        guard !isWorking else { return }
        isWorking = true
        statusMessage = "已将 \(app.name) 添加至受信任白名单"

        Task {
            let identifier = !app.bundle_id.isEmpty ? app.bundle_id : app.name
            _ = await Task.detached {
                MTCBridge.shared.addToWhitelist(identifier: identifier)
            }.value

            self.refresh()

            try? await Task.sleep(nanoseconds: 2_000_000_000)
            self.statusMessage = nil
        }
    }

    public func openConfigFile() {
        MTCBridge.shared.openConfigFile()
    }
}
