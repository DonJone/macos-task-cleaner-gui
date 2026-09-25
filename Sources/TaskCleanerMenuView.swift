import SwiftUI
import AppKit

public struct TaskCleanerMenuView: View {
    @ObservedObject public var viewModel: TaskCleanerViewModel

    public init(viewModel: TaskCleanerViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            // 原生层级背板：全尺寸超透流体毛玻璃基质
            VisualEffectBackground(material: .popover, blendingMode: .behindWindow)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 1. 顶栏：流体玻璃标题区 (Header)
                headerSection
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 12)

                // 2. 状态提示气泡 (Toast)
                if let msg = viewModel.statusMessage {
                    statusToastView(message: msg)
                        .padding(.horizontal, 14)
                        .padding(.bottom, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // 3. 核心操作面板 (Hero Action Card)
                actionSection
                    .padding(.horizontal, 14)
                    .padding(.bottom, 12)

                // 4. 应用列表核心区 (Scrollable Cards)
                appListView
                    .padding(.horizontal, 14)

                // 5. 底栏玻璃坞 (Footer Dock)
                footerSection
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            }
        }
        .frame(width: 340)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: viewModel.summary?.target_count)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: viewModel.statusMessage)
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack(spacing: 10) {
            // 图标徽记 (Liquid Glass Icon Capsule)
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.white.opacity(0.6), .white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.8
                            )
                    )
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                Image(systemName: "broom.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.orange, Color.red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Task Cleaner")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                if let summary = viewModel.summary {
                    Text("共 \(summary.scanned_total) 应用 | 待清场 \(summary.target_count) 个")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(.secondary)
                } else {
                    Text("正在扫描系统前台进程...")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // 刷新按钮 (联动 viewModel.isWorking 动态流体旋转反馈)
            Button(action: {
                viewModel.refresh()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(viewModel.isWorking ? 360 : 0))
                    .animation(viewModel.isWorking ? .linear(duration: 0.8).repeatForever(autoreverses: false) : .default, value: viewModel.isWorking)
                    .padding(6)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial.opacity(0.7))
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
                    )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isWorking)
        }
    }

    // MARK: - Action Section
    private var actionSection: some View {
        LiquidGlassCard(cornerRadius: 14) {
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    // 主动作：流体平滑清场按钮
                    Button(action: {
                        viewModel.cleanAll(force: false, purge: false)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 12, weight: .bold))
                            Text("一键平滑清场")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(LiquidGlassButtonStyle(isDangerous: true))
                    .disabled(viewModel.isWorking || (viewModel.summary?.target_count ?? 0) == 0)

                    // 辅助动作：秒杀按钮
                    Button(action: {
                        viewModel.cleanAll(force: true, purge: false)
                    }) {
                        Text("秒杀")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(.ultraThinMaterial.opacity(0.8))
                            )
                            .overlay(
                                Capsule(style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.6)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isWorking || (viewModel.summary?.target_count ?? 0) == 0)
                }
            }
            .padding(10)
        }
    }

    // MARK: - Status Toast
    private func statusToastView(message: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "bell.badge.fill")
                .foregroundColor(.cyan)
                .font(.system(size: 11))
            Text(message)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.cyan.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(.cyan.opacity(0.25), lineWidth: 0.6)
        )
    }

    // MARK: - App List View
    private var appListView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // 1. 待清场前台应用卡片流
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("待清场目标")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)

                        Spacer()

                        if let count = viewModel.summary?.target_count {
                            LiquidGlassBadge(title: "\(count) 个待清理", tint: .orange)
                        }
                    }

                    if let targets = viewModel.summary?.targets, !targets.isEmpty {
                        VStack(spacing: 5) {
                            ForEach(targets) { app in
                                LiquidGlassTargetRow(app: app) {
                                    viewModel.whitelistApp(app)
                                }
                            }
                        }
                    } else {
                        emptyStateView
                    }
                }

                // 2. 白名单折叠卡片
                VStack(alignment: .leading, spacing: 6) {
                    DisclosureGroup(
                        isExpanded: $viewModel.showProtectedList,
                        content: {
                            if let protected = viewModel.summary?.protected_apps, !protected.isEmpty {
                                VStack(spacing: 4) {
                                    ForEach(protected) { app in
                                        LiquidGlassProtectedRow(app: app)
                                    }
                                }
                                .padding(.top, 4)
                            }
                        },
                        label: {
                            HStack {
                                Text("白名单已受保护")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(.secondary)

                                Spacer()

                                if let count = viewModel.summary?.protected_count {
                                    LiquidGlassBadge(title: "\(count) 个受保护", tint: .green)
                                }
                            }
                        }
                    )
                }
            }
            .padding(.vertical, 4)
        }
        .frame(maxHeight: 330)
    }

    private var emptyStateView: some View {
        VStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.green.opacity(0.8))
            Text("当前工作区已完全清场")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.4))
        )
    }

    // MARK: - Footer Dock
    private var footerSection: some View {
        HStack {
            Button(action: {
                viewModel.openConfigFile()
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 11))
                    Text("配置文件")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                }
                .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Text("退出")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - 流体玻璃行组件：待清场应用
struct LiquidGlassTargetRow: View {
    let app: TargetAppEntry
    let onWhitelist: () -> Void

    var body: some View {
        HStack(spacing: 9) {
            Image(nsImage: app.appIcon)
                .resizable()
                .frame(width: 24, height: 24)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .shadow(color: .black.opacity(0.12), radius: 2, x: 0, y: 1)

            VStack(alignment: .leading, spacing: 1.5) {
                Text(app.name)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(app.bundle_id.isEmpty ? "PID: \(app.pid)" : app.bundle_id)
                    .font(.system(size: 9.5, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.85))
                    .lineLimit(1)
            }

            Spacer()

            Button(action: onWhitelist) {
                HStack(spacing: 3) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 9))
                    Text("白名单")
                }
            }
            .buttonStyle(LiquidGlassMiniButtonStyle())
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 9)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.60))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.30),
                            .white.opacity(0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.6
                )
        )
    }
}

// MARK: - 流体玻璃行组件：受保护应用
struct LiquidGlassProtectedRow: View {
    let app: ProtectedAppEntry

    var body: some View {
        HStack(spacing: 8) {
            Image(nsImage: app.appIcon)
                .resizable()
                .frame(width: 18, height: 18)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text(app.name)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(app.tier)
                    .font(.system(size: 9, design: .rounded))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "shield.checkerboard")
                .font(.system(size: 11))
                .foregroundColor(.green.opacity(0.85))
        }
        .padding(.vertical, 3.5)
        .padding(.horizontal, 8)
    }
}
