import SwiftUI
import AppKit

public struct TaskCleanerMenuView: View {
    @ObservedObject public var viewModel: TaskCleanerViewModel

    public init(viewModel: TaskCleanerViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            // macOS 27 原生系统级毛玻璃背板 (支持底层折射与动态虚化)
            VisualEffectBackground(material: .popover, blendingMode: .behindWindow)
                .ignoresSafeArea()

            VStack(spacing: 10) {
                // 1. 顶栏 (固定 24pt 高度，绝对禁止抖动跳跃)
                headerSection

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
        .frame(width: 340)
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
                SystemBadge("\(summary.scanned_total) 运行中", color: .secondary)
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
            .help("重新扫描前台进程")
        }
        .frame(height: 24)
    }

    // MARK: - Action Section (结构恒定，去除底层命令字样与注释，自然优雅)
    private var actionSection: some View {
        let hasTargets = (viewModel.summary?.target_count ?? 0) > 0
        let targetCount = viewModel.summary?.target_count ?? 0

        return SystemCard(cornerRadius: 10) {
            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    VStack(alignment: .leading, spacing: 1.5) {
                        Text(hasTargets ? "\(targetCount) 个进程待终止" : "所有前台应用均受保护")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.primary)

                        // 状态反馈直接就地显示于副标题槽位
                        if let msg = viewModel.statusMessage {
                            Text(msg)
                                .font(.system(size: 10.5, weight: .medium))
                                .foregroundStyle(Color(nsColor: .systemBlue))
                        } else {
                            Text(hasTargets ? "一键结束未列入受信任白名单的活动应用" : "所有当前活动应用均匹配白名单豁免规则")
                                .font(.system(size: 10.5))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    SystemBadge(
                        hasTargets ? "待处理" : "已清场",
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
                        Text(hasTargets ? "结束全部目标任务" : "无待终止任务")
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
                title: "待结束",
                count: viewModel.summary?.target_count ?? 0,
                tab: .targets
            )

            segmentTabButton(
                title: "已保护",
                count: viewModel.summary?.protected_count ?? 0,
                tab: .protected
            )

            segmentTabButton(
                title: "全部活动",
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

    // MARK: - 加长型应用列表区 (放宽至 380pt 最大高度，确保充足的滚动阅览空间)
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
            .frame(minHeight: 260, maxHeight: 380)
        }
    }

    private var targetAppsList: some View {
        let targets = viewModel.summary?.targets ?? []
        return VStack(spacing: 0) {
            if targets.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color(nsColor: .systemBlue))

                    Text("当前无待结束进程")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text("所有前台图形应用均受白名单保护")
                        .font(.system(size: 10.5))
                        .foregroundStyle(.secondary)

                    Button(action: {
                        withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
                            viewModel.selectedTab = .all
                        }
                    }) {
                        Text("查看全部 \(viewModel.summary?.scanned_total ?? 0) 个活动进程")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(Array(targets.enumerated()), id: \.element.pid) { index, app in
                    NativeTargetRow(app: app, isWorking: viewModel.isWorking) {
                        viewModel.whitelistApp(app)
                    }

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
                Text("暂无匹配的白名单规则")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
                ForEach(Array(protectedList.enumerated()), id: \.element.pid) { index, app in
                    NativeProtectedRow(app: app)

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
                Text("未检测到前台图形进程")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
                // 1. 待结束进程组 (若有)
                if !targets.isEmpty {
                    HStack {
                        Text("待结束进程")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 4)
                    .padding(.bottom, 2)

                    ForEach(Array(targets.enumerated()), id: \.element.pid) { index, app in
                        NativeTargetRow(app: app, isWorking: viewModel.isWorking) {
                            viewModel.whitelistApp(app)
                        }

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
                        Text("受保护进程")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 4)
                    .padding(.bottom, 2)

                    ForEach(Array(protectedList.enumerated()), id: \.element.pid) { index, app in
                        NativeProtectedRow(app: app)

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
                Button(action: {
                    viewModel.openConfigFile()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 11))
                        Text("配置文件")
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Text("退出")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 2)
            .padding(.bottom, 2)
        }
    }
}

// MARK: - 原生待清场应用行组件 (支持 Default / Hover / Active / Disabled 状态)
struct NativeTargetRow: View {
    let app: TargetAppEntry
    let isWorking: Bool
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

            Button(action: onWhitelist) {
                Text("加入白名单")
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)
            .disabled(isWorking)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
    }
}

// MARK: - 原生受保护应用行组件
struct NativeProtectedRow: View {
    let app: ProtectedAppEntry

    var body: some View {
        HStack(spacing: 8) {
            Image(nsImage: app.appIcon)
                .resizable()
                .frame(width: 20, height: 20)
                .clipShape(RoundedRectangle(cornerRadius: 4.5, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 4.5, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
                )

            VStack(alignment: .leading, spacing: 1) {
                Text(app.name)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(app.tier)
                    .font(.system(size: 9.5))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark.shield")
                .font(.system(size: 11))
                .foregroundStyle(Color(nsColor: .systemBlue).opacity(0.85))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4.5)
    }
}
