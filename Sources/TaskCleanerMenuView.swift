import SwiftUI
import AppKit

public struct TaskCleanerMenuView: View {
    @ObservedObject public var viewModel: TaskCleanerViewModel
    @ObservedObject private var i18n = I18n.shared
    @ObservedObject private var launchManager = LaunchAtLoginManager.shared

    public init(viewModel: TaskCleanerViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack(alignment: .top) {
            // macOS 27 原生系统级毛玻璃背板 (支持底层折射与动态虚化)
            VisualEffectBackground(material: .popover, blendingMode: .behindWindow)
                .ignoresSafeArea()

            VStack(spacing: 10) {
                // 1. 顶栏 (固定 24pt 高度，绝对禁止抖动跳跃)
                headerSection

                // 首次开机自启动引导卡片 (仅首次打开且未开启时展示)
                if launchManager.shouldShowPrompt {
                    launchAtLoginPromptCard
                }

                // 2. 核心操作面板 (恒定高度刚性卡片，内嵌动态反馈，绝不产生上下跳跃)
                actionSection

                // 3. 分段选择器 (对齐 macOS 网络托盘当前连接蓝色高亮，支持待结束/已保护/全部活动进程)
                segmentedSection

                // 4. 加长型应用列表区 (支持流畅滚动浏览全部活动进程)
                appListView

                // 5. 底栏工具 (Footer Toolbar)
                footerSection
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 8)
        }
        .frame(width: 310)
        .background(WindowAutoResizer(targetWidth: 310, isRTL: i18n.isRTL))
        .environment(\.layoutDirection, i18n.layoutDirection)
        // 打开即刷新，并保持实时常驻前台进程感知
        .onAppear {
            viewModel.startLiveMonitoring()
        }
        .onDisappear {
            viewModel.stopLiveMonitoring()
        }
    }

    // MARK: - Header (刚性固定尺寸与锚点，彻底解决图标跳动问题)
    private var headerSection: some View {
        HStack(spacing: 8) {
            Text("Task Cleaner")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)

            if let summary = viewModel.summary {
                SystemBadge(i18n.format(.header_running, summary.scanned_total), color: .secondary)
            }

            Spacer()

            // 刚性 24x24 点击锚点，内部居中自旋，杜绝任何位移跳跃
            Button(action: {
                viewModel.refresh()
            }) {
                ZStack {
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
                }
                .frame(width: 24, height: 24, alignment: .center)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(i18n.t(.header_refresh_help))
        }
        .frame(height: 24)
    }

    // MARK: - 首次开机自启动引导卡片 (Apple 原生质感，支持立即启用与稍后忽略)
    private var launchAtLoginPromptCard: some View {
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

    // MARK: - Action Section (结构恒定，去除底层命令字样与注释，自然优雅)
    private var actionSection: some View {
        let hasTargets = (viewModel.summary?.target_count ?? 0) > 0
        let targetCount = viewModel.summary?.target_count ?? 0

        return SystemCard(cornerRadius: 10) {
            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    VStack(alignment: .leading, spacing: 1.5) {
                        Text(hasTargets ? i18n.format(.targets_count, targetCount) : i18n.t(.all_protected_title))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.primary)

                        // 状态反馈直接就地显示于副标题槽位
                        if let msg = viewModel.statusMessage {
                            Text(msg)
                                .font(.system(size: 10.5, weight: .medium))
                                .foregroundStyle(Color(nsColor: .systemBlue))
                        } else {
                            Text(hasTargets ? i18n.t(.targets_desc) : i18n.t(.all_protected_desc))
                                .font(.system(size: 10.5))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    SystemBadge(
                        hasTargets ? i18n.t(.badge_pending) : i18n.t(.badge_protected),
                        color: hasTargets ? .secondary : Color(nsColor: .systemBlue)
                    )
                }

                Button(action: {
                    viewModel.cleanAll()
                }) {
                    HStack(spacing: 6) {
                        Spacer()
                        Image(systemName: hasTargets ? "xmark.circle" : "checkmark.circle")
                            .font(.system(size: 11.5, weight: .medium))
                        Text(hasTargets ? i18n.t(.btn_terminate) : i18n.t(.btn_ready))
                            .font(.system(size: 12, weight: .semibold))
                        Spacer()
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .disabled(!hasTargets || viewModel.isWorking)
            }
            .padding(11)
        }
    }

    // MARK: - Segmented Switcher (对齐 macOS 网络托盘当前连接高亮：支持 待结束 / 已保护 / 全部活动)
    private var segmentedSection: some View {
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
            withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
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

    // MARK: - 动态自适应应用列表区 (最少容纳 3 个，最多容纳 6 个，高度由首次打开时的待结束进程数量锁定)
    private var appListView: some View {
        let capacity = viewModel.initialTargetCapacity
        let listHeight = CGFloat(capacity) * 38.0 + CGFloat(capacity - 1) * 1.0 + 8.0

        return SystemCard(cornerRadius: 10) {
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
            .frame(height: listHeight)
        }
    }

    private var targetAppsList: some View {
        let targets = viewModel.summary?.targets ?? []
        return VStack(spacing: 0) {
            if targets.isEmpty {
                VStack(spacing: 5) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color(nsColor: .systemBlue))

                    Text(i18n.t(.empty_targets_title))
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text(i18n.t(.empty_targets_subtitle))
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)

                    Button(action: {
                        withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
                            viewModel.selectedTab = .all
                        }
                    }) {
                        Text(i18n.format(.btn_view_all, viewModel.summary?.scanned_total ?? 0))
                            .font(.system(size: 10, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    .padding(.top, 2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 8)
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

    private var protectedAppsList: some View {
        let protectedList = viewModel.summary?.protected_apps ?? []
        return VStack(spacing: 0) {
            if protectedList.isEmpty {
                Text(i18n.t(.empty_protected))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.vertical, 16)
            } else {
                ForEach(Array(protectedList.enumerated()), id: \.element.pid) { index, app in
                    NativeProtectedRow(app: app, isWorking: viewModel.isWorking) {
                        viewModel.unprotectApp(app)
                    }

                    if index < protectedList.count - 1 {
                        Divider()
                            .opacity(0.35)
                            .padding(.leading, 38)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    // 全部活动进程浏览视图
    private var allAppsList: some View {
        let targets = viewModel.summary?.targets ?? []
        let protectedList = viewModel.summary?.protected_apps ?? []

        return VStack(spacing: 0) {
            if targets.isEmpty && protectedList.isEmpty {
                Text(i18n.t(.empty_all))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.vertical, 16)
            } else {
                // 1. 待结束进程组 (若有)
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
                            }
                        )

                        if index < targets.count - 1 {
                            Divider()
                                .opacity(0.35)
                                .padding(.leading, 40)
                        }
                    }

                    Divider()
                        .opacity(0.6)
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
                        NativeProtectedRow(app: app, isWorking: viewModel.isWorking) {
                            viewModel.unprotectApp(app)
                        }

                        if index < protectedList.count - 1 {
                            Divider()
                                .opacity(0.35)
                                .padding(.leading, 38)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Footer
    private var footerSection: some View {
        VStack(spacing: 6) {
            Divider()
                .opacity(0.4)

            HStack {
                Menu {
                    Button(action: {
                        launchManager.toggle()
                        viewModel.statusMessage = launchManager.isEnabled ? i18n.t(.status_launch_enabled) : i18n.t(.status_launch_disabled)
                        Task {
                            try? await Task.sleep(nanoseconds: 2_000_000_000)
                            viewModel.statusMessage = nil
                        }
                    }) {
                        HStack {
                            Text(i18n.t(.launch_at_login_menu))
                            if launchManager.isEnabled {
                                Image(systemName: "checkmark")
                            }
                        }
                    }

                    Divider()

                    Button(action: {
                        viewModel.openConfigFile()
                    }) {
                        Text(i18n.t(.btn_config))
                    }

                    Divider()

                    Button(action: {
                        viewModel.showAboutDialog()
                    }) {
                        Text(i18n.t(.btn_about))
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

// MARK: - 辅助绘制原生矢量纵向三点图标 (避免 AppKit 丢弃旋转 modifier)
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

// MARK: - 原生待清场应用行组件 (支持单独结束任务与拓展选项，统一右对齐)
struct NativeTargetRow: View {
    let app: TargetAppEntry
    let isWorking: Bool
    let onTerminate: () -> Void
    let onWhitelist: () -> Void

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
                Text(app.name)
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
                // 1. 单独结束任务按钮 (小垃圾桶图标)
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

                // 2. 拓展项 (竖三点)：加入白名单位于拓展菜单，严格右对齐
                Menu {
                    Button(action: onWhitelist) {
                        Label(I18n.shared.t(.action_add_whitelist), systemImage: "checkmark.shield")
                    }

                    Divider()

                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(
                            !app.bundle_id.isEmpty ? app.bundle_id : app.name,
                            forType: .string
                        )
                    }) {
                        Label(I18n.shared.t(.action_copy_id), systemImage: "doc.on.doc")
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
    }
}

// MARK: - 原生受保护应用行组件 (统一右对齐基线)
struct NativeProtectedRow: View {
    let app: ProtectedAppEntry
    let isWorking: Bool
    let onRemove: () -> Void

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
                Text(app.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(I18n.shared.localizeTier(app.tier))
                    .font(.system(size: 9.5))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: onRemove) {
                Text(I18n.shared.t(.btn_remove_protected))
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)
            .frame(width: 44, alignment: .trailing)
            .disabled(isWorking)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
    }
}
