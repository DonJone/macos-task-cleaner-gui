import AppKit

func renderAppIcon(size: CGFloat) -> NSImage {
    let img = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
        guard let ctx = NSGraphicsContext.current?.cgContext else { return false }

        let s = size / 1024.0 // Scale factor

        // 1. Standard macOS Squircle Base (824x824 centered in 1024x1024)
        let baseSize: CGFloat = 824.0 * s
        let baseInset: CGFloat = (size - baseSize) / 2.0
        let baseRect = NSRect(x: baseInset, y: baseInset - 10 * s, width: baseSize, height: baseSize)
        let baseRadius: CGFloat = 185.0 * s

        // Shadow behind the squircle
        ctx.saveGState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.38)
        shadow.shadowOffset = NSSize(width: 0, height: -22 * s)
        shadow.shadowBlurRadius = 32 * s
        shadow.set()

        let squirclePath = NSBezierPath(roundedRect: baseRect, xRadius: baseRadius, yRadius: baseRadius)
        NSColor(white: 0.12, alpha: 1.0).setFill()
        squirclePath.fill()
        ctx.restoreGState()

        // Squircle Gradient Fill (Deep Slate/Carbon Gradient)
        ctx.saveGState()
        squirclePath.addClip()

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let gradColors = [
            NSColor(red: 0.18, green: 0.20, blue: 0.24, alpha: 1.0).cgColor,
            NSColor(red: 0.11, green: 0.12, blue: 0.15, alpha: 1.0).cgColor
        ] as CFArray
        let locations: [CGFloat] = [0.0, 1.0]
        if let grad = CGGradient(colorsSpace: colorSpace, colors: gradColors, locations: locations) {
            ctx.drawLinearGradient(
                grad,
                start: CGPoint(x: baseRect.midX, y: baseRect.maxY),
                end: CGPoint(x: baseRect.midX, y: baseRect.minY),
                options: []
            )
        }

        // Inner rim highlight border
        let innerBorder = NSBezierPath(roundedRect: baseRect.insetBy(dx: 1.5 * s, dy: 1.5 * s), xRadius: baseRadius - 1.5 * s, yRadius: baseRadius - 1.5 * s)
        NSColor.white.withAlphaComponent(0.12).setStroke()
        innerBorder.lineWidth = 2.0 * s
        innerBorder.stroke()
        ctx.restoreGState()

        // 2. White Pill Shape in the Center
        let pillW: CGFloat = 520.0 * s
        let pillH: CGFloat = 310.0 * s
        let pillX = (size - pillW) / 2.0
        let pillY = (size - pillH) / 2.0 - 10 * s
        let pillRect = NSRect(x: pillX, y: pillY, width: pillW, height: pillH)
        let pillRadius = pillH / 2.0

        // Pill Drop Shadow
        ctx.saveGState()
        let pillShadow = NSShadow()
        pillShadow.shadowColor = NSColor.black.withAlphaComponent(0.28)
        pillShadow.shadowOffset = NSSize(width: 0, height: -12 * s)
        pillShadow.shadowBlurRadius = 18 * s
        pillShadow.set()

        let pillPath = NSBezierPath(roundedRect: pillRect, xRadius: pillRadius, yRadius: pillRadius)
        NSColor.white.setFill()
        pillPath.fill()
        ctx.restoreGState()

        // Pill Surface Gradient (Pure Crisp White to Very Subtle Ice White)
        ctx.saveGState()
        pillPath.addClip()

        let pillGradColors = [
            NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0).cgColor,
            NSColor(red: 0.94, green: 0.95, blue: 0.97, alpha: 1.0).cgColor
        ] as CFArray
        if let pillGrad = CGGradient(colorsSpace: colorSpace, colors: pillGradColors, locations: locations) {
            ctx.drawLinearGradient(
                pillGrad,
                start: CGPoint(x: pillRect.midX, y: pillRect.maxY),
                end: CGPoint(x: pillRect.midX, y: pillRect.minY),
                options: []
            )
        }

        // 3. Cutout / Recessed Transparent 'X' in the Center of the Pill
        let xSpan: CGFloat = 138.0 * s
        let xHalf = xSpan / 2.0
        let xCenterX = pillRect.midX
        let xCenterY = pillRect.midY
        let strokeW: CGFloat = 46.0 * s

        let xPath = NSBezierPath()
        xPath.lineWidth = strokeW
        xPath.lineCapStyle = .round

        xPath.move(to: NSPoint(x: xCenterX - xHalf, y: xCenterY - xHalf))
        xPath.line(to: NSPoint(x: xCenterX + xHalf, y: xCenterY + xHalf))

        xPath.move(to: NSPoint(x: xCenterX - xHalf, y: xCenterY + xHalf))
        xPath.line(to: NSPoint(x: xCenterX + xHalf, y: xCenterY - xHalf))

        NSColor(red: 0.12, green: 0.13, blue: 0.16, alpha: 1.0).setStroke()
        xPath.stroke()

        let xInnerShadowPath = NSBezierPath()
        xInnerShadowPath.lineWidth = strokeW
        xInnerShadowPath.lineCapStyle = .round
        xInnerShadowPath.move(to: NSPoint(x: xCenterX - xHalf, y: xCenterY + xHalf))
        xInnerShadowPath.line(to: NSPoint(x: xCenterX + xHalf, y: xCenterY - xHalf))
        xInnerShadowPath.move(to: NSPoint(x: xCenterX - xHalf, y: xCenterY - xHalf))
        xInnerShadowPath.line(to: NSPoint(x: xCenterX + xHalf, y: xCenterY + xHalf))

        NSColor.black.withAlphaComponent(0.25).setStroke()
        xInnerShadowPath.lineWidth = 10.0 * s
        xInnerShadowPath.stroke()

        ctx.restoreGState()

        return true
    }
    return img
}

let iconsetDir = "/tmp/AppIcon.iconset"
try? FileManager.default.removeItem(atPath: iconsetDir)
try? FileManager.default.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

let iconSizes: [(String, CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for (name, size) in iconSizes {
    let icon = renderAppIcon(size: size)
    let rep = NSBitmapImageRep(data: icon.tiffRepresentation!)!
    let png = rep.representation(using: .png, properties: [:])!
    let path = "\(iconsetDir)/\(name)"
    try! png.write(to: URL(fileURLWithPath: path))
}

print("Iconset created at \(iconsetDir)")
