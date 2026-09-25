import SwiftUI
import AppKit

public enum TrayIconHelper {
    /// 绘制 macOS 系统级原生托盘图标：白色药丸形状，正中央镂空透明 X 符号
    public static let pillXIcon: NSImage = {
        let width: CGFloat = 20.0
        let height: CGFloat = 12.0
        let canvasHeight: CGFloat = 18.0

        let img = NSImage(size: NSSize(width: width, height: canvasHeight), flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }

            let pillY = (canvasHeight - height) / 2.0
            let pillRect = NSRect(x: 0, y: pillY, width: width, height: height)
            let radius = height / 2.0

            // 1. 绘制实心药丸形状 (系统菜单栏标准模板底色)
            let pillPath = NSBezierPath(roundedRect: pillRect, xRadius: radius, yRadius: radius)
            NSColor.black.setFill()
            pillPath.fill()

            // 2. 居中镂空透明 X 字符 (通过 Clear 混合模式直接擦除像素)
            ctx.setBlendMode(.clear)
            let centerX = pillRect.midX
            let centerY = pillRect.midY
            let half: CGFloat = 3.0
            let stroke: CGFloat = 1.85

            let xPath = NSBezierPath()
            xPath.lineWidth = stroke
            xPath.lineCapStyle = .round

            xPath.move(to: NSPoint(x: centerX - half, y: centerY - half))
            xPath.line(to: NSPoint(x: centerX + half, y: centerY + half))

            xPath.move(to: NSPoint(x: centerX - half, y: centerY + half))
            xPath.line(to: NSPoint(x: centerX + half, y: centerY - half))

            NSColor.clear.setStroke()
            xPath.stroke()

            return true
        }

        img.isTemplate = true
        return img
    }()
}

@main
struct TaskCleanerApp: App {
    @StateObject private var viewModel = TaskCleanerViewModel()

    var body: some Scene {
        MenuBarExtra {
            TaskCleanerMenuView(viewModel: viewModel)
        } label: {
            Image(nsImage: TrayIconHelper.pillXIcon)
        }
        .menuBarExtraStyle(.window)
    }
}
