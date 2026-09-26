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
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
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

// MARK: - 原生窗口布局方向适配器 (Window RTL Layout Adapter)
// 仅同步 AppKit 原生窗口布局方向以支持 RTL 语言，严禁调用 window.setFrame 避免破坏系统原生 popover 连续圆角
public struct WindowAutoResizer: NSViewRepresentable {
    public let targetWidth: CGFloat
    public let isRTL: Bool

    public init(targetWidth: CGFloat = 310, isRTL: Bool = false) {
        self.targetWidth = targetWidth
        self.isRTL = isRTL
    }

    public func makeNSView(context: Context) -> NSView {
        let view = NSView()
        return view
    }

    public func updateNSView(_ nsView: NSView, context: Context) {
        guard let window = nsView.window, let contentView = window.contentView else { return }
        let desiredLayoutDirection: NSUserInterfaceLayoutDirection = isRTL ? .rightToLeft : .leftToRight
        if contentView.userInterfaceLayoutDirection != desiredLayoutDirection {
            contentView.userInterfaceLayoutDirection = desiredLayoutDirection
        }
    }
}
