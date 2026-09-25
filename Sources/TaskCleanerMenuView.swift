import SwiftUI
import AppKit

public struct TaskCleanerMenuView: View {
    @ObservedObject public var viewModel: TaskCleanerViewModel

    public init(viewModel: TaskCleanerViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            // macOS 原生系统级毛玻璃基质
            VisualEffectBackground(material: .popover, blendingMode: .behindWindow)
                .ignoresSafeArea()

            VStack(spacing: 10) {
                // 1. 顶栏 (Header)
                headerSection

                // 2. 状态提示 (Status Toast)
                if let msg = viewModel.statusMessage {
                    statusToastView(message: msg)
                }

                // 3. 核心操作面板 (Hero Action Card)
                actionSection

                // 4. 分段选择器 (Segmented Switcher)
                segmentedSection

                // 5. 应用列表区 (Inset Grouped App List)
                appListView

                // 6. 底栏工具 (Footer Dock)
                footerSection
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 8)
        }
        .frame(width: 320)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.selectedTab)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.statusMessage)
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "broom.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.accentColor)

            Text("Task Cleaner")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)

            if let summary = viewModel.summary {
                SystemBadge("\(summary.scanned_total) 运行中", color: .secondary)
            }

            Spacer()

            Button(action: {
                viewModel.refresh()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(viewModel.isWorking ? 360 : 0))
                    .animation(
                        viewModel.isWorking
                            ? .linear(duration: 0.8).repeatForever(autoreverses: false)
                            : .default,
                        value: viewModel.isWorking
                    )
            }
            .buttonStyle(.plain)
            .help("刷新扫描前台应用")
        }
    }

    // MARK: - Status Toast
    private func statusToastView(message: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 11))
                .foregroundColor(.accentColor)

            Text(message)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(nsColor: .quaternaryLabelColor))
        )
    }

    // MARK: - Action Section
    private var actionSection: some View {
        SystemCard(cornerRadius: 10) {
            if let summary = viewModel.summary, summary.target_count > 0 {
                VStack(alignment: .leading, spacing: 9) {
                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("\(summary.target_count) 个应用待清场")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.primary)

                            Text("关闭所有未加白名单的活动应用")
                                .font(.system(size: 10.5))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        SystemBadge("就绪", color: .orange)
                    }

                    Button(action: {
                        viewModel.cleanAll()
                    }) {
                        HStack(spacing: 5) {
                            Spacer()
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 11, weight: .bold))
                            Text("一键清场退出")
                                .font(.system(size: 12, weight: .semibold))
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .controlSize(.regular)
                }
                .padding(11)
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("当前工作区已完全清场")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.primary)

                        Text("所有前台图形应用均在受保护白名单中")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(11)
            }
        }
    }

    // MARK: - Segmented Switcher
    private var segmentedSection: some View {
        Picker("", selection: $viewModel.selectedTab) {
            Text("待清场 (\(viewModel.summary?.target_count ?? 0))")
                .tag(CleanerTab.targets)

            Text("受保护 (\(viewModel.summary?.protected_count ?? 0))")
                .tag(CleanerTab.protected)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
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
                    Text("暂无待清场前台应用")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                ForEach(Array(targets.enumerated()), id: \.element.pid) { index, app in
                    NativeTargetRow(app: app) {
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
                Text("暂无白名单匹配记录")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
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
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Text("退出")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 2)
            .padding(.bottom, 2)
        }
    }
}

// MARK: - 原生待清场应用行组件
struct NativeTargetRow: View {
    let app: TargetAppEntry
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
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(app.bundle_id.isEmpty ? "PID: \(app.pid)" : app.bundle_id)
                    .font(.system(size: 9.5, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: onWhitelist) {
                Text("+ 白名单")
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)
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
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(app.tier)
                    .font(.system(size: 9.5))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 11))
                .foregroundColor(.secondary.opacity(0.75))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4.5)
    }
}
