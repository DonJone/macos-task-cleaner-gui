import SwiftUI
import AppKit

// MARK: - 原生 NSVisualEffectView 毛玻璃包装
public struct VisualEffectBackground: NSViewRepresentable {
    public var material: NSVisualEffectView.Material
    public var blendingMode: NSVisualEffectView.BlendingMode
    public var state: NSVisualEffectView.State

    public init(
        material: NSVisualEffectView.Material = .popover,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        state: NSVisualEffectView.State = .active
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.state = state
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}

// MARK: - 流体玻璃卡片容器 (Liquid Glass Container)
public struct LiquidGlassCard<Content: View>: View {
    public let cornerRadius: CGFloat
    public let content: Content

    public init(cornerRadius: CGFloat = 12, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    public var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(0.85))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: .white.opacity(0.35), location: 0.0),
                                .init(color: .white.opacity(0.12), location: 0.4),
                                .init(color: .black.opacity(0.15), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.75
                    )
            )
            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
    }
}

// MARK: - 流体玻璃高光按钮样式 (Liquid Glass Button Style)
public struct LiquidGlassButtonStyle: ButtonStyle {
    public var tintColor: Color
    public var isDangerous: Bool

    public init(tintColor: Color = .blue, isDangerous: Bool = false) {
        self.tintColor = tintColor
        self.isDangerous = isDangerous
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                ZStack {
                    // 底层流体渐变
                    LinearGradient(
                        colors: isDangerous
                            ? [Color(nsColor: .systemRed).opacity(configuration.isPressed ? 0.75 : 0.88), Color(nsColor: .systemOrange).opacity(0.80)]
                            : [tintColor.opacity(configuration.isPressed ? 0.80 : 0.95), tintColor.opacity(0.70)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    // 顶半部玻璃折射光泽 (Specular Glass Shine)
                    VStack {
                        LinearGradient(
                            colors: [.white.opacity(configuration.isPressed ? 0.25 : 0.42), .white.opacity(0.04)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 14)
                        Spacer()
                    }
                }
            )
            .clipShape(Capsule(style: .continuous))
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: .white.opacity(0.65), location: 0.0),
                                .init(color: .white.opacity(0.20), location: 0.6),
                                .init(color: .clear, location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.8
                    )
            )
            .shadow(
                color: isDangerous ? Color.red.opacity(configuration.isPressed ? 0.15 : 0.28) : tintColor.opacity(configuration.isPressed ? 0.15 : 0.28),
                radius: configuration.isPressed ? 3 : 6,
                x: 0,
                y: configuration.isPressed ? 1 : 2.5
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

// MARK: - 流体玻璃微型按钮样式 (用于 "+ 白名单")
public struct LiquidGlassMiniButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundColor(.primary)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(configuration.isPressed ? 0.95 : 0.65))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(configuration.isPressed ? 0.60 : 0.30),
                                .white.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.6
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.18, dampingFraction: 0.70), value: configuration.isPressed)
    }
}

// MARK: - 玻璃质感状态胶囊徽标 (Liquid Glass Badge)
public struct LiquidGlassBadge: View {
    public let title: String
    public let tint: Color

    public init(title: String, tint: Color) {
        self.title = title
        self.tint = tint
    }

    public var body: some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundColor(tint)
            .padding(.horizontal, 7)
            .padding(.vertical, 2.5)
            .background(
                Capsule(style: .continuous)
                    .fill(tint.opacity(0.14))
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [tint.opacity(0.45), tint.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.6
                    )
            )
    }
}
