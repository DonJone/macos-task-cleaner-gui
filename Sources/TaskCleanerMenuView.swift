import SwiftUI
import AppKit

public struct TaskCleanerMenuView: View {
    @ObservedObject public var viewModel: TaskCleanerViewModel

    public init(viewModel: TaskCleanerViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 顶栏 Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("macOS Task Cleaner")
                        .font(.headline)
                        .fontWeight(.bold)
                    if let summary = viewModel.summary {
                        Text("前台应用: \(summary.scanned_total) | 待清场: \(summary.target_count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("正在扫描...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Button(action: {
                    viewModel.refresh()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(.borderless)
                .disabled(viewModel.isWorking)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 10)

            Divider()

            // 状态提示横幅 (Toast)
            if let msg = viewModel.statusMessage {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 12))
                    Text(msg)
                        .font(.caption)
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                Divider()
            }

            // 核心清场操作区
            HStack(spacing: 10) {
                Button(action: {
                    viewModel.cleanAll(force: false, purge: false)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "broom.fill")
                        Text("一键平滑清场")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(viewModel.isWorking || (viewModel.summary?.target_count ?? 0) == 0)

                Button(action: {
                    viewModel.cleanAll(force: true, purge: false)
                }) {
                    Text("强制秒杀")
                        .font(.caption)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isWorking || (viewModel.summary?.target_count ?? 0) == 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider()

            // 内容列表区域
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // 待清场应用分组
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("待清场前台应用")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            Spacer()
                            if let count = viewModel.summary?.target_count {
                                Text("\(count) 个")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.15))
                                    .foregroundColor(.orange)
                                    .cornerRadius(4)
                            }
                        }

                        if let targets = viewModel.summary?.targets, !targets.isEmpty {
                            VStack(spacing: 4) {
                                ForEach(targets) { app in
                                    TargetAppRowView(app: app) {
                                        viewModel.whitelistApp(app)
                                    }
                                }
                            }
                        } else {
                            HStack {
                                Spacer()
                                Text("当前工作区非常清爽，无待清理应用")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 16)
                                Spacer()
                            }
                        }
                    }

                    Divider()

                    // 已受保护应用分组 (可展开折叠)
                    DisclosureGroup(
                        isExpanded: $viewModel.showProtectedList,
                        content: {
                            if let protected = viewModel.summary?.protected_apps, !protected.isEmpty {
                                VStack(spacing: 4) {
                                    ForEach(protected) { app in
                                        ProtectedAppRowView(app: app)
                                    }
                                }
                                .padding(.top, 4)
                            }
                        },
                        label: {
                            HStack {
                                Text("已保护白名单应用")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                Spacer()
                                if let count = viewModel.summary?.protected_count {
                                    Text("\(count) 个")
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.green.opacity(0.15))
                                        .foregroundColor(.green)
                                        .cornerRadius(4)
                                }
                            }
                        }
                    )
                }
                .padding(14)
            }
            .frame(maxHeight: 340)

            Divider()

            // 底部工具栏
            HStack {
                Button(action: {
                    viewModel.openConfigFile()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "gearshape")
                        Text("配置文件")
                    }
                    .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)

                Spacer()

                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Text("退出")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
        }
        .frame(width: 320)
    }
}

struct TargetAppRowView: View {
    let app: TargetAppEntry
    let onWhitelist: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(nsImage: app.appIcon)
                .resizable()
                .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 1) {
                Text(app.name)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                Text(app.bundle_id.isEmpty ? "PID: \(app.pid)" : app.bundle_id)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: onWhitelist) {
                Text("+ 白名单")
                    .font(.system(size: 10, weight: .medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 6)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
        .cornerRadius(6)
    }
}

struct ProtectedAppRowView: View {
    let app: ProtectedAppEntry

    var body: some View {
        HStack(spacing: 8) {
            Image(nsImage: app.appIcon)
                .resizable()
                .frame(width: 20, height: 20)

            VStack(alignment: .leading, spacing: 1) {
                Text(app.name)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                Text(app.tier)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 11))
                .foregroundColor(.green)
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 6)
    }
}
