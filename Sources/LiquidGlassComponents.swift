import SwiftUI
import AppKit

// MARK: - macOS 原生系统级毛玻璃背板 (System Menu Vibrancy Background)
// 依据 macOS 原生渲染规范：采用与 NSMenu 相同的原生 .menu 材质，呈现纯净深邃的动态折射
public struct VisualEffectBackground: NSViewRepresentable {
    public var material: NSVisualEffectView.Material
    public var blendingMode: NSVisualEffectView.BlendingMode
    public var state: NSVisualEffectView.State

    public init(
        material: NSVisualEffectView.Material = .menu,
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

// MARK: - macOS 晶体悬浮卡片容器 (Crystal Inset Card)
// 彻底解决毛玻璃嵌套叠加变灰发暗问题：
// 内部区块不重复叠加第二层 Material 模糊通道，而是采用半透明微透层与上边缘光泽描边，与底板 .menu 材质浑然天成
public struct SystemCard<Content: View>: View {
    public let cornerRadius: CGFloat
    public let content: Content

    public init(cornerRadius: CGFloat = 10, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    public var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.38))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.18),
                                Color.white.opacity(0.06),
                                Color.primary.opacity(0.04)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5
                    )
            )
    }
}

// MARK: - macOS 27 鲜艳文本液态玻璃徽标 (Vibrant Text Badge)
// 依据规范：结合 .foregroundStyle 鲜艳文本与 .ultraThinMaterial 液态灰阶底衬
public struct SystemBadge: View {
    public let text: String
    public let tint: Color

    public init(_ text: String, color: Color = .secondary) {
        self.text = text
        self.tint = color
    }

    public var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .medium, design: .default))
            .foregroundStyle(tint)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule(style: .continuous)
                    .fill(tint.opacity(0.12))
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(tint.opacity(0.24), lineWidth: 0.5)
            )
    }
}

// MARK: - 原生窗口尺寸自适应适配器 (Window Auto Resizer)
// 依据 macOS AppKit 原生渲染机制：
// MenuBarExtraWindow 在动态内容展开/折叠时无法自动缩减窗口高度，易导致空白或残影。
// 本适配器监听内容尺寸变化，锚定菜单栏顶部原点 (MaxY)，平滑同步调整 NSWindow 尺寸。
public struct WindowAutoResizer: NSViewRepresentable {
    public let targetWidth: CGFloat
    public let isRTL: Bool

    public init(targetWidth: CGFloat = 310, isRTL: Bool = false) {
        self.targetWidth = targetWidth
        self.isRTL = isRTL
    }

    public func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.adjustWindow(view)
        }
        return view
    }

    public func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            self.adjustWindow(nsView)
        }
    }

    private func adjustWindow(_ view: NSView) {
        guard let window = view.window else { return }
        guard let contentView = window.contentView else { return }

        // 确保窗口背景完全透明，由 VisualEffectBackground 承载原生 .menu 毛玻璃折射与圆角
        if window.isOpaque {
            window.isOpaque = false
        }
        if window.backgroundColor != .clear {
            window.backgroundColor = .clear
        }

        // 同步 AppKit 原生窗口布局方向以支持 RTL
        let desiredLayoutDirection: NSUserInterfaceLayoutDirection = isRTL ? .rightToLeft : .leftToRight
        if contentView.userInterfaceLayoutDirection != desiredLayoutDirection {
            contentView.userInterfaceLayoutDirection = desiredLayoutDirection
        }

        let fitting = contentView.fittingSize
        guard fitting.height > 60 else { return }

        let currentFrame = window.frame
        if abs(currentFrame.height - fitting.height) > 1.0 {
            let heightDiff = currentFrame.height - fitting.height
            let newY = currentFrame.origin.y + heightDiff
            let newFrame = NSRect(
                x: currentFrame.origin.x,
                y: newY,
                width: targetWidth,
                height: fitting.height
            )
            window.setFrame(newFrame, display: true, animate: false)
        }
    }
}
