import Foundation
import AppKit
import UniformTypeIdentifiers

public struct DryRunSummary: Codable {
    public let scanned_total: Int
    public let protected_count: Int
    public let target_count: Int
    public let scan_duration_ms: Double
    public let config_source: String
    public let protected_apps: [ProtectedAppEntry]
    public let targets: [TargetAppEntry]
}

public struct TargetAppEntry: Codable, Identifiable {
    public var id: Int { pid }
    public let pid: Int
    public let name: String
    public let bundle_id: String
    public let is_alive: Bool

    public var appIcon: NSImage {
        if let runningApp = NSRunningApplication(processIdentifier: pid_t(pid)),
           let icon = runningApp.icon {
            return icon
        }
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundle_id) {
            return NSWorkspace.shared.icon(forFile: url.path)
        }
        return NSWorkspace.shared.icon(for: .application)
    }
}

public struct ProtectedAppEntry: Codable, Identifiable {
    public var id: Int { pid }
    public let pid: Int
    public let name: String
    public let bundle_id: String
    public let tier: String
    public let rule: String

    public var appIcon: NSImage {
        if let runningApp = NSRunningApplication(processIdentifier: pid_t(pid)),
           let icon = runningApp.icon {
            return icon
        }
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundle_id) {
            return NSWorkspace.shared.icon(forFile: url.path)
        }
        return NSWorkspace.shared.icon(for: .application)
    }
}

extension TargetAppEntry {
    @MainActor
    public func localizedName(in i18n: I18n) -> String {
        AppDisplayNameResolver.shared.resolve(
            bundleId: bundle_id,
            fallback: name,
            language: i18n.currentLanguage
        )
    }
}

extension ProtectedAppEntry {
    @MainActor
    public func localizedName(in i18n: I18n) -> String {
        AppDisplayNameResolver.shared.resolve(
            bundleId: bundle_id,
            fallback: name,
            language: i18n.currentLanguage
        )
    }
}
