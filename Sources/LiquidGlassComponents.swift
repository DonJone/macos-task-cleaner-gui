import SwiftUI
import AppKit

// MARK: - macOS 27 原生系统级毛玻璃背板 (System Vibrancy Background)
// 依据 macOS 27 原生渲染规范：承载底层混合模式与透明通道
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
        view.wantsLayer = true
        view.layer?.cornerRadius = 14.0
        view.layer?.masksToBounds = true
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
        nsView.wantsLayer = true
        nsView.layer?.cornerRadius = 14.0
        nsView.layer?.masksToBounds = true
    }
}

// MARK: - macOS 27 官方液态玻璃规范容器 (Liquid Glass Inset Card)
// 依据 macOS 27 规范：
// 1. 采用原生 .thinMaterial 自动激活底层复合渲染机制 (反射 + 折射 + 动态微变形)
// 2. 规范更收敛的转角半径 (10pt 连续曲率)
// 3. 采用 Color.primary.opacity(0.08) 实现深色模式自适应灰调边缘高光
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
                    .fill(.thinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
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
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(tint.opacity(0.22), lineWidth: 0.5)
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

        // 核心修复：确保窗口底色透明，内容层强制 14pt 连续圆角裁剪，杜绝直角黑边与方角崩坏
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true

        contentView.wantsLayer = true
        contentView.layer?.cornerRadius = 14.0
        contentView.layer?.masksToBounds = true

        // 同步 AppKit 原生窗口布局方向以支持 RTL
        let desiredLayoutDirection: NSUserInterfaceLayoutDirection = isRTL ? .rightToLeft : .leftToRight
        if contentView.userInterfaceLayoutDirection != desiredLayoutDirection {
            contentView.userInterfaceLayoutDirection = desiredLayoutDirection
        }

        let fitting = contentView.fittingSize
        guard fitting.height > 60 else { return }

        let currentFrame = window.frame
        // 阈值提升为 8pt，防止微小字号/文本度量波动引起频繁 setFrame
        if abs(currentFrame.height - fitting.height) > 8.0 {
            let heightDiff = currentFrame.height - fitting.height
            let newY = currentFrame.origin.y + heightDiff
            let newFrame = NSRect(
                x: currentFrame.origin.x,
                y: newY,
                width: targetWidth,
                height: fitting.height
            )
            window.setFrame(newFrame, display: true, animate: false)
            contentView.layer?.cornerRadius = 14.0
            contentView.layer?.masksToBounds = true
            window.invalidateShadow()
        }
    }
}
