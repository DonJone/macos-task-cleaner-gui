import AppKit

let pointsWidth: CGFloat = 600
let pointsHeight: CGFloat = 380
let scale: CGFloat = 2.0 // Retina 2x

let pixelWidth = Int(pointsWidth * scale)
let pixelHeight = Int(pointsHeight * scale)

guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: pixelWidth,
    pixelsHigh: pixelHeight,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fatalError("Failed to create bitmap representation")
}

rep.size = NSSize(width: pointsWidth, height: pointsHeight)

NSGraphicsContext.saveGraphicsState()
guard let context = NSGraphicsContext(bitmapImageRep: rep) else {
    fatalError("Failed to create graphics context")
}
NSGraphicsContext.current = context

let bounds = NSRect(x: 0, y: 0, width: pointsWidth, height: pointsHeight)

// 背景柔和现代渐变 (浅色质感)
let bgGradient = NSGradient(
    starting: NSColor(red: 0.96, green: 0.97, blue: 0.99, alpha: 1.0),
    ending: NSColor(red: 0.90, green: 0.92, blue: 0.95, alpha: 1.0)
)
bgGradient?.draw(in: bounds, angle: -45)

// 中部拖拽指引区域
let midY: CGFloat = 190
let startX: CGFloat = 270
let endX: CGFloat = 330

// 绘制导向箭头主干
let arrowPath = NSBezierPath()
arrowPath.move(to: NSPoint(x: startX, y: midY))
arrowPath.line(to: NSPoint(x: endX - 10, y: midY))
arrowPath.lineWidth = 4
arrowPath.lineCapStyle = .round
NSColor(red: 0.50, green: 0.55, blue: 0.65, alpha: 0.75).setStroke()
arrowPath.stroke()

// 绘制箭头头部
let headPath = NSBezierPath()
headPath.move(to: NSPoint(x: endX - 16, y: midY + 9))
headPath.line(to: NSPoint(x: endX, y: midY))
headPath.line(to: NSPoint(x: endX - 16, y: midY - 9))
headPath.lineWidth = 4
headPath.lineCapStyle = .round
headPath.lineJoinStyle = .round
NSColor(red: 0.50, green: 0.55, blue: 0.65, alpha: 0.75).setStroke()
headPath.stroke()

// 指引文字
let tipText = "Drag to Applications to Install"
let textFont = NSFont.systemFont(ofSize: 13, weight: .medium)
let textAttrs: [NSAttributedString.Key: Any] = [
    .font: textFont,
    .foregroundColor: NSColor(red: 0.40, green: 0.45, blue: 0.55, alpha: 0.90)
]
let textSize = (tipText as NSString).size(withAttributes: textAttrs)
let textRect = NSRect(
    x: (pointsWidth - textSize.width) / 2,
    y: midY - 50,
    width: textSize.width,
    height: textSize.height
)
(tipText as NSString).draw(in: textRect, withAttributes: textAttrs)

// 顶部标题
let titleText = "Task Cleaner"
let titleFont = NSFont.systemFont(ofSize: 16, weight: .bold)
let titleAttrs: [NSAttributedString.Key: Any] = [
    .font: titleFont,
    .foregroundColor: NSColor(red: 0.25, green: 0.30, blue: 0.38, alpha: 0.95)
]
let titleSize = (titleText as NSString).size(withAttributes: titleAttrs)
let titleRect = NSRect(
    x: (pointsWidth - titleSize.width) / 2,
    y: pointsHeight - 55,
    width: titleSize.width,
    height: titleSize.height
)
(titleText as NSString).draw(in: titleRect, withAttributes: titleAttrs)

NSGraphicsContext.restoreGraphicsState()

let outputDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Resources/dmg_background.png"
guard let pngData = rep.representation(using: .png, properties: [:]) else {
    fatalError("Failed to convert image to PNG")
}

let url = URL(fileURLWithPath: outputDir)
try pngData.write(to: url)
print("[完成] DMG 背景图已生成: \(outputDir)")
