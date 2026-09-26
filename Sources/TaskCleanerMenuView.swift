import SwiftUI
import AppKit

public struct TaskCleanerMenuView: View {
    @ObservedObject public var viewModel: TaskCleanerViewModel
    @ObservedObject private var i18n = I18n.shared
    @ObservedObject private var launchManager = LaunchAtLoginManager.shared
    @ObservedObject private var shortcutManager = GlobalShortcutManager.shared

    public init(viewModel: TaskCleanerViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 10) {
            // 1. 顶栏：应用标题、活动数徽标与刷新按钮
            headerSection

            // 2. 开机自启动引导横幅 (首次进入且未开启时提示)
            if launchManager.shouldShowPrompt {
                launchAtLoginBanner
            }

            // 3. 核心操作面板：待清理状态、一键清场与清理模式选项
            heroActionSection

            // 4. 分段选择器：待结束 / 已保护 / 全部活动进程
            segmentedControlSection

            // 5. 应用列表核心区：固定高度稳定滚动卡片
            appListView

            // 6. 底栏工具：配置菜单、语言切换与退出
            footerSection
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .frame(width: 320)
        .environment(\.layoutDirection, i18n.layoutDirection)
        .onAppear {
            viewModel.startLiveMonitoring()
        }
        .onDisappear {
            viewModel.stopLiveMonitoring()
        }
    }

    // MARK: - 1. Header (顶栏)
    private var headerSection: some View {
        HStack(spacing: 8) {
            Image(nsImage: TrayIconHelper.pillXIcon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 12)

            Text("Task Cleaner")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)

            if let summary = viewModel.summary {
                SystemBadge(i18n.format(.header_running, summary.scanned_total), color: .secondary)
            }

            Spacer()

            Button(action: {
                viewModel.refresh()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(viewModel.isWorking ? 360 : 0))
                    .animation(
                        viewModel.isWorking
                            ? .linear(duration: 0.7).repeatForever(autoreverses: false)
                            : .default,
                        value: viewModel.isWorking
                    )
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(i18n.t(.header_refresh_help))
            .disabled(viewModel.isWorking)
        }
        .frame(height: 24)
    }

    // MARK: - 2. Launch At Login Prompt (开机自启横幅)
    private var launchAtLoginBanner: some View {
        SystemCard(cornerRadius: 10) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "macwindow.and.cursor")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(Color(nsColor: .systemBlue))

                    Text(i18n.t(.launch_at_login_title))
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    Button(action: {
                        launchManager.dismissPrompt()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 16, height: 16)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                Text(i18n.t(.launch_at_login_desc))
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    Spacer()

                    Button(action: {
                        launchManager.dismissPrompt()
                    }) {
                        Text(i18n.t(.btn_later))
                            .font(.system(size: 10.5))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        launchManager.enableFromPrompt()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            viewModel.statusMessage = i18n.t(.status_launch_enabled)
                            Task {
                                try? await Task.sleep(nanoseconds: 2_000_000_000)
                                viewModel.statusMessage = nil
                            }
                        }
                    }) {
                        Text(i18n.t(.btn_enable))
                            .font(.system(size: 10.5, weight: .semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.mini)
                }
            }
            .padding(9)
        }
    }

    // MARK: - 3. Hero Action Section (核心操作面板)
    private var heroActionSection: some View {
        let hasTargets = (viewModel.summary?.target_count ?? 0) > 0
        let targetCount = viewModel.summary?.target_count ?? 0

        return SystemCard(cornerRadius: 10) {
            VStack(alignment: .leading, spacing: 9) {
                // 上行：状态文本与徽标
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(hasTargets ? i18n.format(.targets_count, targetCount) : i18n.t(.all_protected_title))
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundStyle(.primary)

                        if let msg = viewModel.statusMessage {
                            Text(msg)
                                .font(.system(size: 10.5, weight: .medium))
                                .foregroundStyle(Color(nsColor: .systemBlue))
                                .lineLimit(1)
                        } else {
                            Text(hasTargets ? i18n.t(.targets_desc) : i18n.t(.all_protected_desc))
                                .font(.system(size: 10.5))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    SystemBadge(
                        hasTargets ? i18n.t(.badge_pending) : i18n.t(.badge_protected),
                        color: hasTargets ? .secondary : Color(nsColor: .systemBlue)
                    )
                }

                // 下行：主执行按钮与模式下拉菜单
                HStack(spacing: 5) {
                    Group {
                        if hasTargets {
                            Button(action: {
                                viewModel.cleanAll()
                            }) {
                                HStack(spacing: 6) {
                                    Spacer()
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 12, weight: .medium))
                                    Text(i18n.t(.btn_terminate))
                                        .font(.system(size: 12, weight: .semibold))
                                    Spacer()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            Button(action: {
                                viewModel.cleanAll()
                            }) {
                                HStack(spacing: 6) {
                                    Spacer()
                                    Image(systemName: "checkmark.circle")
                                        .font(.system(size: 12, weight: .medium))
                                    Text(i18n.t(.btn_ready))
                                        .font(.system(size: 12, weight: .semibold))
                                    Spacer()
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .controlSize(.regular)
                    .disabled(!hasTargets || viewModel.isWorking)

                    if hasTargets {
                        Menu {
                            Button(action: { viewModel.cleanAll(force: false, purge: false) }) {
                                Label(i18n.t(.clean_mode_normal), systemImage: "stop.circle")
                            }
                            Button(action: { viewModel.cleanAll(force: true, purge: false) }) {
                                Label(i18n.t(.clean_mode_force), systemImage: "xmark.octagon")
                            }
                            Divider()
                            Button(action: { viewModel.cleanAll(force: false, purge: true) }) {
                                Label(i18n.t(.clean_mode_purge), systemImage: "memorychip")
                            }
                        } label: {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.secondary)
                                .frame(width: 22, height: 26)
                                .background(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(Color.primary.opacity(0.06))
                                )
                        }
                        .menuStyle(.borderlessButton)
                        .menuIndicator(.hidden)
                        .frame(width: 24, height: 26)
                        .disabled(viewModel.isWorking)
                        .help(i18n.t(.clean_mode_options))
                    }
                }
            }
            .padding(11)
        }
    }

    // MARK: - 4. Segmented Control Section (分段选择器)
    private var segmentedControlSection: some View {
        HStack(spacing: 3) {
            segmentTabButton(
                title: i18n.t(.tab_targets),
                count: viewModel.summary?.target_count ?? 0,
                tab: .targets
            )

            segmentTabButton(
                title: i18n.t(.tab_protected),
                count: viewModel.summary?.protected_count ?? 0,
                tab: .protected
            )

            segmentTabButton(
                title: i18n.t(.tab_all),
                count: viewModel.summary?.scanned_total ?? 0,
                tab: .all
            )
        }
        .padding(2.5)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(nsColor: .quaternaryLabelColor))
        )
        .disabled(viewModel.isWorking)
    }

    private func segmentTabButton(title: String, count: Int, tab: CleanerTab) -> some View {
        let isSelected = viewModel.selectedTab == tab
        return Button(action: {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.82)) {
                viewModel.selectedTab = tab
            }
        }) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))

                Text("\(count)")
                    .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                    .padding(.horizontal, 4.5)
                    .padding(.vertical, 1)
                    .background(
                        Capsule()
                            .fill(isSelected ? Color.white.opacity(0.24) : Color.primary.opacity(0.08))
                    )
            }
            .foregroundStyle(isSelected ? Color.white : Color.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4.5)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color(nsColor: .systemBlue))
                            .shadow(color: Color.blue.opacity(0.25), radius: 2, x: 0, y: 1)
                    } else {
                        Color.clear
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 5. App List View (稳定高度列表区，恒定 216pt 保证弹出层绝对无抖动)
    private var appListView: some View {
        SystemCard(cornerRadius: 10) {
            ScrollView(.vertical, showsIndicators: true) {
                switch viewModel.selectedTab {
                case .targets:
                    targetAppsList
                case .protected:
                    protectedAppsList
                case .all:
                    allAppsList
                }
            }
            .frame(height: 216)
        }
    }

    // 待结束应用列表
    private var targetAppsList: some View {
        let targets = viewModel.summary?.targets ?? []
        return VStack(spacing: 0) {
            if targets.isEmpty {
                VStack(spacing: 6) {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color(nsColor: .systemBlue))

                    Text(i18n.t(.empty_targets_title))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text(i18n.t(.empty_targets_subtitle))
                        .font(.system(size: 10.5))
                        .foregroundStyle(.secondary)

                    Button(action: {
                        withAnimation(.spring(response: 0.22, dampingFraction: 0.82)) {
                            viewModel.selectedTab = .all
                        }
                    }) {
                        Text(i18n.format(.btn_view_all, viewModel.summary?.scanned_total ?? 0))
                            .font(.system(size: 10.5, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    .padding(.top, 4)
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                ForEach(Array(targets.enumerated()), id: \.element.pid) { index, app in
                    NativeTargetRow(
                        app: app,
                        isWorking: viewModel.isWorking,
                        onTerminate: {
                            viewModel.terminateTarget(app)
                        },
                        onWhitelist: {
                            viewModel.whitelistApp(app)
                        },
                        onRevealInFinder: {
                            viewModel.revealInFinder(pid: app.pid)
                        },
                        onCopyId: {
                            let identifier = !app.bundle_id.isEmpty ? app.bundle_id : app.name
                            viewModel.copyToClipboard(text: identifier, label: i18n.t(.status_copied))
                        },
                        onCopyPid: {
                            viewModel.copyToClipboard(text: "\(app.pid)", label: i18n.t(.status_copied))
                        }
                    )

                    if index < targets.count - 1 {
                        Divider()
                            .opacity(0.35)
                            .padding(.leading, 40)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    // 已保护应用列表
    private var protectedAppsList: some View {
        let protectedList = viewModel.summary?.protected_apps ?? []
        return VStack(spacing: 0) {
            if protectedList.isEmpty {
                VStack(spacing: 6) {
                    Spacer()
                    Image(systemName: "shield.slash")
                        .font(.system(size: 22))
                        .foregroundStyle(.secondary)

                    Text(i18n.t(.empty_protected))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                ForEach(Array(protectedList.enumerated()), id: \.element.pid) { index, app in
                    NativeProtectedRow(
                        app: app,
                        isWorking: viewModel.isWorking,
                        onRemove: {
                            viewModel.unprotectApp(app)
                        },
                        onRevealInFinder: {
                            viewModel.revealInFinder(pid: app.pid)
                        },
                        onCopyId: {
                            let identifier = !app.bundle_id.isEmpty ? app.bundle_id : app.name
                            viewModel.copyToClipboard(text: identifier, label: i18n.t(.status_copied))
                        },
                        onCopyPid: {
                            viewModel.copyToClipboard(text: "\(app.pid)", label: i18n.t(.status_copied))
                        }
                    )

                    if index < protectedList.count - 1 {
                        Divider()
                            .opacity(0.35)
                            .padding(.leading, 40)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    // 全部活动应用列表 (分组展示)
    private var allAppsList: some View {
        let targets = viewModel.summary?.targets ?? []
        let protectedList = viewModel.summary?.protected_apps ?? []

        return VStack(spacing: 0) {
            if targets.isEmpty && protectedList.isEmpty {
                VStack(spacing: 6) {
                    Spacer()
                    Text(i18n.t(.empty_all))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                // 1. 待结束进程组
                if !targets.isEmpty {
                    HStack {
                        Text(i18n.t(.group_targets))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 4)
                    .padding(.bottom, 2)

                    ForEach(Array(targets.enumerated()), id: \.element.pid) { index, app in
                        NativeTargetRow(
                            app: app,
                            isWorking: viewModel.isWorking,
                            onTerminate: {
                                viewModel.terminateTarget(app)
                            },
                            onWhitelist: {
                                viewModel.whitelistApp(app)
                            },
                            onRevealInFinder: {
                                viewModel.revealInFinder(pid: app.pid)
                            },
                            onCopyId: {
                                let identifier = !app.bundle_id.isEmpty ? app.bundle_id : app.name
                                viewModel.copyToClipboard(text: identifier, label: i18n.t(.status_copied))
                            },
                            onCopyPid: {
                                viewModel.copyToClipboard(text: "\(app.pid)", label: i18n.t(.status_copied))
                            }
                        )

                        if index < targets.count - 1 {
                            Divider()
                                .opacity(0.35)
                                .padding(.leading, 40)
                        }
                    }

                    Divider()
                        .opacity(0.5)
                        .padding(.vertical, 6)
                }

                // 2. 受保护进程组
                if !protectedList.isEmpty {
                    HStack {
                        Text(i18n.t(.group_protected))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 4)
                    .padding(.bottom, 2)

                    ForEach(Array(protectedList.enumerated()), id: \.element.pid) { index, app in
                        NativeProtectedRow(
                            app: app,
                            isWorking: viewModel.isWorking,
                            onRemove: {
                                viewModel.unprotectApp(app)
                            },
                            onRevealInFinder: {
                                viewModel.revealInFinder(pid: app.pid)
                            },
                            onCopyId: {
                                let identifier = !app.bundle_id.isEmpty ? app.bundle_id : app.name
                                viewModel.copyToClipboard(text: identifier, label: i18n.t(.status_copied))
                            },
                            onCopyPid: {
                                viewModel.copyToClipboard(text: "\(app.pid)", label: i18n.t(.status_copied))
                            }
                        )

                        if index < protectedList.count - 1 {
                            Divider()
                                .opacity(0.35)
                                .padding(.leading, 40)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - 6. Footer (底栏工具区)
    private var footerSection: some View {
        VStack(spacing: 6) {
            Divider()
                .opacity(0.35)

            HStack {
                // 配置设置主菜单
                Menu {
                    Button(action: {
                        launchManager.toggle()
                        viewModel.statusMessage = launchManager.isEnabled ? i18n.t(.status_launch_enabled) : i18n.t(.status_launch_disabled)
                        Task {
                            try? await Task.sleep(nanoseconds: 2_000_000_000)
                            viewModel.statusMessage = nil
                        }
                    }) {
                        Label(
                            i18n.t(.launch_at_login_menu),
                            systemImage: launchManager.isEnabled ? "checkmark.circle.fill" : "circle"
                        )
                    }

                    Divider()

                    Menu {
                        ForEach(ShortcutPreset.allCases) { preset in
                            Button(action: {
                                shortcutManager.setPreset(preset)
                            }) {
                                if shortcutManager.isEnabled && shortcutManager.currentPreset == preset {
                                    Text("\(preset.displayString)  [Active]")
                                } else {
                                    Text(preset.displayString)
                                }
                            }
                        }

                        Divider()

                        Button(action: {
                            shortcutManager.openCustomShortcutRecorder()
                        }) {
                            Label(
                                shortcutManager.isEnabled && shortcutManager.currentPreset == nil
                                    ? "\(i18n.t(.menu_custom_shortcut)) (\(shortcutManager.displayString))"
                                    : i18n.t(.menu_custom_shortcut),
                                systemImage: "keyboard"
                            )
                        }

                        if shortcutManager.isEnabled {
                            Divider()

                            Button(action: {
                                shortcutManager.disableShortcut()
                            }) {
                                Label(i18n.t(.menu_disable_shortcut), systemImage: "xmark.circle")
                            }
                        }
                    } label: {
                        Label(
                            shortcutManager.isEnabled ? "\(i18n.t(.menu_global_shortcut)): \(shortcutManager.displayString)" : i18n.t(.menu_global_shortcut),
                            systemImage: "command"
                        )
                    }

                    Divider()

                    Button(action: {
                        viewModel.installCliCommand()
                    }) {
                        Label(i18n.t(.menu_install_cli), systemImage: "terminal")
                    }

                    Divider()

                    Button(action: {
                        viewModel.openConfigFile()
                    }) {
                        Label(i18n.t(.menu_open_config_file), systemImage: "slider.horizontal.3")
                    }

                    Button(action: {
                        viewModel.openConfigDirectory()
                    }) {
                        Label(i18n.t(.menu_open_config_dir), systemImage: "folder.badge.gear")
                    }

                    Divider()

                    Button(action: {
                        if let url = URL(string: "https://github.com/macos-task-cleaner/macos-task-cleaner-gui") {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        Label(i18n.t(.menu_github_repo), systemImage: "arrow.up.right.square")
                    }

                    Button(action: {
                        viewModel.showAboutDialog()
                    }) {
                        Label(i18n.t(.btn_about), systemImage: "info.circle")
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 11))
                        Text(i18n.t(.btn_config))
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(.secondary)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)

                Spacer()

                HStack(spacing: 6) {
                    // 语言切换下拉菜单
                    Menu {
                        ForEach(LanguagePreference.allCases) { pref in
                            Button(action: {
                                i18n.setLanguage(pref)
                            }) {
                                HStack {
                                    Text(pref.localizedTitle(in: i18n))
                                    if i18n.preference == pref {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "globe")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                    .frame(width: 16, height: 16)
                    .help(i18n.t(.btn_language))

                    // 退出按钮
                    Button(action: {
                        NSApplication.shared.terminate(nil)
                    }) {
                        Text(i18n.t(.btn_quit))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
            .padding(.bottom, 2)
        }
    }
}

// MARK: - 辅助绘制原生矢量纵向三点图标
private func makeVerticalEllipsisImage() -> NSImage {
    let img = NSImage(size: NSSize(width: 14, height: 16), flipped: false) { rect in
        let dotRadius: CGFloat = 1.35
        let centerX = rect.midX
        let centerY = rect.midY
        let spacing: CGFloat = 4.2

        let dotsY = [centerY + spacing, centerY, centerY - spacing]
        NSColor.secondaryLabelColor.setFill()

        for y in dotsY {
            let dotRect = NSRect(x: centerX - dotRadius, y: y - dotRadius, width: dotRadius * 2, height: dotRadius * 2)
            let path = NSBezierPath(ovalIn: dotRect)
            path.fill()
        }
        return true
    }
    img.isTemplate = true
    return img
}

// MARK: - 原生待清场应用行组件 (支持快捷结束、右键菜单、悬浮态与对齐)
struct NativeTargetRow: View {
    let app: TargetAppEntry
    let isWorking: Bool
    let onTerminate: () -> Void
    let onWhitelist: () -> Void
    let onRevealInFinder: () -> Void
    let onCopyId: () -> Void
    let onCopyPid: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(nsImage: app.appIcon)
                .resizable()
                .frame(width: 22, height: 22)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
                )

            VStack(alignment: .leading, spacing: 1) {
                Text(app.localizedName(in: I18n.shared))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(app.bundle_id.isEmpty ? "PID: \(app.pid)" : app.bundle_id)
                    .font(.system(size: 9.5, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            HStack(spacing: 0) {
                // 单独结束任务按钮 (垃圾桶)
                Button(action: onTerminate) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .frame(width: 22, height: 22)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(I18n.shared.t(.action_terminate_help))
                .disabled(isWorking)

                // 拓展菜单 (竖三点)
                Menu {
                    Button(action: onWhitelist) {
                        Label(I18n.shared.t(.action_add_whitelist), systemImage: "checkmark.shield")
                    }

                    Divider()

                    Button(action: onRevealInFinder) {
                        Label(I18n.shared.t(.action_reveal_in_finder), systemImage: "folder")
                    }

                    Divider()

                    Button(action: onCopyId) {
                        Label(I18n.shared.t(.action_copy_id), systemImage: "doc.on.doc")
                    }
                    Button(action: onCopyPid) {
                        Label(I18n.shared.t(.action_copy_pid), systemImage: "number")
                    }
                } label: {
                    Image(nsImage: makeVerticalEllipsisImage())
                        .frame(width: 14, height: 22)
                        .contentShape(Rectangle())
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .help(I18n.shared.t(.action_more_help))
                .frame(width: 18, height: 22)
                .offset(x: I18n.shared.isRTL ? -3 : 3)
                .disabled(isWorking)
            }
            .frame(width: 44, alignment: .trailing)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .contentShape(Rectangle())
        .contextMenu {
            Button(action: onTerminate) {
                Label(I18n.shared.t(.action_terminate_app), systemImage: "trash")
            }
            Button(action: onWhitelist) {
                Label(I18n.shared.t(.action_add_whitelist), systemImage: "checkmark.shield")
            }

            Divider()

            Button(action: onRevealInFinder) {
                Label(I18n.shared.t(.action_reveal_in_finder), systemImage: "folder")
            }

            Divider()

            Button(action: onCopyId) {
                Label(I18n.shared.t(.action_copy_id), systemImage: "doc.on.doc")
            }
            Button(action: onCopyPid) {
                Label(I18n.shared.t(.action_copy_pid), systemImage: "number")
            }
        }
    }
}

// MARK: - 原生受保护应用行组件 (统一右对齐基线、右键菜单与悬浮态)
struct NativeProtectedRow: View {
    let app: ProtectedAppEntry
    let isWorking: Bool
    let onRemove: () -> Void
    let onRevealInFinder: () -> Void
    let onCopyId: () -> Void
    let onCopyPid: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(nsImage: app.appIcon)
                .resizable()
                .frame(width: 22, height: 22)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
                )

            VStack(alignment: .leading, spacing: 1) {
                Text(app.localizedName(in: I18n.shared))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(I18n.shared.localizeTier(app.tier, id: app.tier_id))
                    .font(.system(size: 9.5))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            HStack(spacing: 0) {
                // 快捷移出受保护按钮 (盾牌划线)
                Button(action: onRemove) {
                    Image(systemName: "shield.slash")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .frame(width: 22, height: 22)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(I18n.shared.t(.action_remove_whitelist))
                .disabled(isWorking)

                // 拓展菜单 (竖三点)
                Menu {
                    Button(action: onRemove) {
                        Label(I18n.shared.t(.action_remove_whitelist), systemImage: "shield.slash")
                    }

                    Divider()

                    Button(action: onRevealInFinder) {
                        Label(I18n.shared.t(.action_reveal_in_finder), systemImage: "folder")
                    }

                    Divider()

                    Button(action: onCopyId) {
                        Label(I18n.shared.t(.action_copy_id), systemImage: "doc.on.doc")
                    }
                    Button(action: onCopyPid) {
                        Label(I18n.shared.t(.action_copy_pid), systemImage: "number")
                    }
                } label: {
                    Image(nsImage: makeVerticalEllipsisImage())
                        .frame(width: 14, height: 22)
                        .contentShape(Rectangle())
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .help(I18n.shared.t(.action_more_help))
                .frame(width: 18, height: 22)
                .offset(x: I18n.shared.isRTL ? -3 : 3)
                .disabled(isWorking)
            }
            .frame(width: 44, alignment: .trailing)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .contentShape(Rectangle())
        .contextMenu {
            Button(action: onRemove) {
                Label(I18n.shared.t(.action_remove_whitelist), systemImage: "shield.slash")
            }

            Divider()

            Button(action: onRevealInFinder) {
                Label(I18n.shared.t(.action_reveal_in_finder), systemImage: "folder")
            }

            Divider()

            Button(action: onCopyId) {
                Label(I18n.shared.t(.action_copy_id), systemImage: "doc.on.doc")
            }
            Button(action: onCopyPid) {
                Label(I18n.shared.t(.action_copy_pid), systemImage: "number")
            }
        }
    }
}
