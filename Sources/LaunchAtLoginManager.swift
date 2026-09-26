import Foundation
import SwiftUI
import ServiceManagement

@MainActor
public final class LaunchAtLoginManager: ObservableObject {
    public static let shared = LaunchAtLoginManager()

    private let promptKey = "TaskCleaner_HasPromptedLaunchAtLogin"

    @Published public var isEnabled: Bool = false
    @Published public var shouldShowPrompt: Bool = false

    private init() {
        let enabled = (SMAppService.mainApp.status == .enabled)
        self.isEnabled = enabled
        let hasPrompted = UserDefaults.standard.bool(forKey: promptKey)
        // 首次打开应用且尚未开启时显示引导卡片
        self.shouldShowPrompt = !hasPrompted && !enabled
    }

    public func enableFromPrompt() {
        setLaunchAtLogin(true)
        dismissPrompt()
    }

    public func dismissPrompt() {
        UserDefaults.standard.set(true, forKey: promptKey)
        self.shouldShowPrompt = false
    }

    public func toggle() {
        setLaunchAtLogin(!isEnabled)
    }

    public func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
            self.isEnabled = (SMAppService.mainApp.status == .enabled)
            UserDefaults.standard.set(true, forKey: promptKey)
        } catch {
            print("LaunchAtLoginManager error: \(error)")
            self.isEnabled = (SMAppService.mainApp.status == .enabled)
        }
    }
}
