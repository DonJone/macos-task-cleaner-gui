import SwiftUI
import AppKit
import Carbon

public class KeyCodeHelper {
    public static func keyString(for keyCode: UInt16) -> String {
        switch Int(keyCode) {
        case kVK_ANSI_A: return "A"
        case kVK_ANSI_B: return "B"
        case kVK_ANSI_C: return "C"
        case kVK_ANSI_D: return "D"
        case kVK_ANSI_E: return "E"
        case kVK_ANSI_F: return "F"
        case kVK_ANSI_G: return "G"
        case kVK_ANSI_H: return "H"
        case kVK_ANSI_I: return "I"
        case kVK_ANSI_J: return "J"
        case kVK_ANSI_K: return "K"
        case kVK_ANSI_L: return "L"
        case kVK_ANSI_M: return "M"
        case kVK_ANSI_N: return "N"
        case kVK_ANSI_O: return "O"
        case kVK_ANSI_P: return "P"
        case kVK_ANSI_Q: return "Q"
        case kVK_ANSI_R: return "R"
        case kVK_ANSI_S: return "S"
        case kVK_ANSI_T: return "T"
        case kVK_ANSI_U: return "U"
        case kVK_ANSI_V: return "V"
        case kVK_ANSI_W: return "W"
        case kVK_ANSI_X: return "X"
        case kVK_ANSI_Y: return "Y"
        case kVK_ANSI_Z: return "Z"
        case kVK_ANSI_0: return "0"
        case kVK_ANSI_1: return "1"
        case kVK_ANSI_2: return "2"
        case kVK_ANSI_3: return "3"
        case kVK_ANSI_4: return "4"
        case kVK_ANSI_5: return "5"
        case kVK_ANSI_6: return "6"
        case kVK_ANSI_7: return "7"
        case kVK_ANSI_8: return "8"
        case kVK_ANSI_9: return "9"
        case kVK_Space: return "Space"
        case kVK_Return: return "↩"
        case kVK_Tab: return "⇥"
        case kVK_Delete: return "⌫"
        case kVK_ForwardDelete: return "⌦"
        case kVK_F1: return "F1"
        case kVK_F2: return "F2"
        case kVK_F3: return "F3"
        case kVK_F4: return "F4"
        case kVK_F5: return "F5"
        case kVK_F6: return "F6"
        case kVK_F7: return "F7"
        case kVK_F8: return "F8"
        case kVK_F9: return "F9"
        case kVK_F10: return "F10"
        case kVK_F11: return "F11"
        case kVK_F12: return "F12"
        default: return ""
        }
    }

    public static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var mods: UInt32 = 0
        if flags.contains(.control) { mods |= UInt32(controlKey) }
        if flags.contains(.option) { mods |= UInt32(optionKey) }
        if flags.contains(.shift) { mods |= UInt32(shiftKey) }
        if flags.contains(.command) { mods |= UInt32(cmdKey) }
        return mods
    }

    public static func modifierDisplay(from flags: NSEvent.ModifierFlags) -> String {
        var res = ""
        if flags.contains(.control) { res += "⌃" }
        if flags.contains(.option) { res += "⌥" }
        if flags.contains(.shift) { res += "⇧" }
        if flags.contains(.command) { res += "⌘" }
        return res
    }
}

@MainActor
public class ShortcutRecorderViewModel: ObservableObject {
    @Published public var capturedKeyCode: UInt16?
    @Published public var capturedFlags: NSEvent.ModifierFlags = []
    private var eventMonitor: Any?

    public init() {}

    public func startMonitoring(onClose: @escaping () -> Void, onSave: @escaping () -> Void) {
        stopMonitoring()
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            guard let self = self else { return event }

            if event.type == .flagsChanged {
                let flags = event.modifierFlags.intersection([.command, .option, .control, .shift])
                self.capturedFlags = flags
                return nil
            } else if event.type == .keyDown {
                if event.keyCode == 53 { // Escape
                    self.stopMonitoring()
                    onClose()
                    return nil
                }

                if event.keyCode == 36 && self.capturedKeyCode != nil { // Return
                    onSave()
                    return nil
                }

                let flags = event.modifierFlags.intersection([.command, .option, .control, .shift])
                let keyStr = KeyCodeHelper.keyString(for: event.keyCode)
                if !keyStr.isEmpty && !flags.isEmpty {
                    self.capturedFlags = flags
                    self.capturedKeyCode = event.keyCode
                }
                return nil
            }
            return event
        }
    }

    public func stopMonitoring() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    public func reset() {
        capturedKeyCode = nil
        capturedFlags = []
    }
}

public struct ShortcutRecorderView: View {
    @ObservedObject private var i18n = I18n.shared
    @StateObject private var vm = ShortcutRecorderViewModel()

    var onClose: () -> Void

    public var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "keyboard")
                    .font(.system(size: 24))
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text(i18n.t(.shortcut_recorder_title))
                        .font(.headline)
                    Text(i18n.t(.shortcut_recorder_desc))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            // Key Display Area
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                vm.capturedKeyCode != nil ? Color.accentColor : Color.secondary.opacity(0.3),
                                lineWidth: vm.capturedKeyCode != nil ? 2 : 1
                            )
                    )

                if let keyCode = vm.capturedKeyCode, !vm.capturedFlags.isEmpty {
                    HStack(spacing: 8) {
                        if vm.capturedFlags.contains(.control) {
                            keyBadge("⌃ Control")
                        }
                        if vm.capturedFlags.contains(.option) {
                            keyBadge("⌥ Option")
                        }
                        if vm.capturedFlags.contains(.shift) {
                            keyBadge("⇧ Shift")
                        }
                        if vm.capturedFlags.contains(.command) {
                            keyBadge("⌘ Command")
                        }
                        let keyStr = KeyCodeHelper.keyString(for: keyCode)
                        if !keyStr.isEmpty {
                            keyBadge(keyStr, isPrimary: true)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                } else if !vm.capturedFlags.isEmpty {
                    HStack(spacing: 8) {
                        if vm.capturedFlags.contains(.control) {
                            keyBadge("⌃")
                        }
                        if vm.capturedFlags.contains(.option) {
                            keyBadge("⌥")
                        }
                        if vm.capturedFlags.contains(.shift) {
                            keyBadge("⇧")
                        }
                        if vm.capturedFlags.contains(.command) {
                            keyBadge("⌘")
                        }
                        Text("...")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "hand.tap")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        Text(i18n.t(.shortcut_recorder_prompt))
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                }
            }
            .frame(height: 64)

            // Hint Text
            Text(i18n.t(.shortcut_recorder_hint))
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            // Action Buttons
            HStack(spacing: 12) {
                Button(action: {
                    vm.stopMonitoring()
                    onClose()
                }) {
                    Text(i18n.t(.btn_cancel))
                        .frame(maxWidth: .infinity)
                }
                .keyboardShortcut(.cancelAction)

                Button(action: {
                    saveShortcut()
                }) {
                    Text(i18n.t(.btn_save_shortcut))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(vm.capturedKeyCode == nil || KeyCodeHelper.carbonModifiers(from: vm.capturedFlags) == 0)
            }
        }
        .padding(22)
        .frame(width: 380)
        .onAppear {
            vm.startMonitoring(
                onClose: onClose,
                onSave: { saveShortcut() }
            )
        }
        .onDisappear {
            vm.stopMonitoring()
        }
    }

    @ViewBuilder
    private func keyBadge(_ text: String, isPrimary: Bool = false) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isPrimary ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isPrimary ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: 1)
            )
    }

    private func saveShortcut() {
        guard let keyCode = vm.capturedKeyCode else { return }
        let mods = KeyCodeHelper.carbonModifiers(from: vm.capturedFlags)
        guard mods != 0 else { return }

        let displayMod = KeyCodeHelper.modifierDisplay(from: vm.capturedFlags)
        let keyChar = KeyCodeHelper.keyString(for: keyCode)
        let fullDisplay = "\(displayMod)\(keyChar)"

        GlobalShortcutManager.shared.setCustomShortcut(
            keyCode: UInt32(keyCode),
            modifiers: mods,
            display: fullDisplay
        )

        vm.stopMonitoring()
        onClose()
    }
}

public class ShortcutRecorderWindowController: NSWindowController {
    public static let shared = ShortcutRecorderWindowController()

    private init() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 220),
            styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.isReleasedWhenClosed = false
        super.init(window: panel)

        let contentView = ShortcutRecorderView { [weak self] in
            self?.close()
        }
        panel.contentView = NSHostingView(rootView: contentView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func showWindow() {
        guard let window = self.window else { return }
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
