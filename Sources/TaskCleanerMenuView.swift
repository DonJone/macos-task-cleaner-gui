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
                // 1. 顶栏 (Header Bar - 极简排版，参考 macOS 网络托盘，去除芯片图示)
                headerSection

                // 2. 状态提示 (Status Toast - 液态玻璃浮层)
                if let msg = viewModel.statusMessage {
                    statusToastView(message: msg)
                }

                // 3. 核心操作面板 (Hero Action Card - 结束任务采用暖调琥珀橙，避免与蓝色选中冲突)
                actionSection

                // 4. 分段选择器 (Segmented Switcher - 参考 macOS 网络托盘活跃网络蓝色 Pill 呈现)
                segmentedSection

                // 5. 应用列表区 (Inset Grouped App List)
                appListView

                // 6. 底栏工具 (Footer Toolbar)
                footerSection
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 8)
        }
        .frame(width: 320)
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: viewModel.selectedTab)
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: viewModel.statusMessage)
    }

    // MARK: - Header (无多余廉价芯片图标，对齐网络托盘简洁标题栏)
    private var headerSection: some View {
        HStack(spacing: 8) {
            Text("Task Cleaner")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)

            if let summary = viewModel.summary {
                SystemBadge("\(summary.scanned_total) 活跃进程", color: .secondary)
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
                            ? .linear(duration: 0.8).repeatForever(autoreverses: false)
                            : .default,
                        value: viewModel.isWorking
                    )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isWorking)
            .help("重新扫描前台进程")
        }
    }

    // MARK: - Status Toast
    private func statusToastView(message: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 11))
                .foregroundStyle(Color.accentColor)

            Text(message)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.primary)

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
    }

    // MARK: - Action Section (结束全部任务采用橙色/琥珀调，与蓝色选中状态清晰分离)
    private var actionSection: some View {
        SystemCard(cornerRadius: 10) {
            if let summary = viewModel.summary, summary.target_count > 0 {
                VStack(alignment: .leading, spacing: 9) {
                    HStack {
                        VStack(alignment: .leading, spacing: 1.5) {
                            Text("\(summary.target_count) 个进程待终止")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.primary)

                            Text("终止未列入受信任白名单的前台应用进程")
                                .font(.system(size: 10.5))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        SystemBadge("待执行", color: .secondary)
                    }

                    Button(action: {
                        viewModel.cleanAll()
                    }) {
                        HStack(spacing: 6) {
                            Spacer()
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 11.5, weight: .medium))
                            Text("结束全部目标任务")
                                .font(.system(size: 12, weight: .semibold))
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .controlSize(.regular)
                    .disabled(viewModel.isWorking)
                }
                .padding(11)
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color(nsColor: .systemBlue))

                    VStack(alignment: .leading, spacing: 1.5) {
                        Text("无待终止的前台进程")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.primary)

                        Text("所有当前活动应用均匹配白名单豁免规则")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(11)
            }
        }
    }

    // MARK: - Segmented Switcher (参考 macOS 网络托盘当前连接高亮样式：激活项采用 System Blue)
    private var segmentedSection: some View {
        HStack(spacing: 3) {
            segmentTabButton(
                title: "目标进程",
                count: viewModel.summary?.target_count ?? 0,
                tab: .targets
            )

            segmentTabButton(
                title: "受保护进程",
                count: viewModel.summary?.protected_count ?? 0,
                tab: .protected
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
            HStack(spacing: 5) {
                Text(title)
                    .font(.system(size: 11.5, weight: isSelected ? .semibold : .regular))

                Text("\(count)")
                    .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                    .padding(.horizontal, 5)
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

    // MARK: - App List View
    private var appListView: some View {
        SystemCard(cornerRadius: 10) {
            ScrollView(.vertical, showsIndicators: true) {
                if viewModel.selectedTab == .targets {
                    targetAppsList
                } else {
                    protectedAppsList
                }
            }
            .frame(maxHeight: 230)
        }
    }

    private var targetAppsList: some View {
        let targets = viewModel.summary?.targets ?? []
        return VStack(spacing: 0) {
            if targets.isEmpty {
                VStack(spacing: 4) {
                    Text("当前无待终止进程")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
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
                    .padding(.vertical, 30)
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
