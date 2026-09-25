import AppKit

func renderTerminalCraftIcon(size: CGFloat) -> NSImage {
    return NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
        guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
        let s = size / 1024.0

        let baseSize: CGFloat = 824.0 * s
        let baseInset: CGFloat = (size - baseSize) / 2.0
        let baseRect = NSRect(x: baseInset, y: baseInset - 10 * s, width: baseSize, height: baseSize)
        let baseRadius: CGFloat = 185.0 * s

        // 1. macOS Dock Shadow
        ctx.saveGState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.48)
        shadow.shadowOffset = NSSize(width: 0, height: -22 * s)
        shadow.shadowBlurRadius = 32 * s
        shadow.set()

        let squirclePath = NSBezierPath(roundedRect: baseRect, xRadius: baseRadius, yRadius: baseRadius)
        NSColor(white: 0.08, alpha: 1.0).setFill()
        squirclePath.fill()
        ctx.restoreGState()

        // 2. Official macOS Utility Monitor Screen Gradient (Terminal / Activity Monitor chassis)
        ctx.saveGState()
        squirclePath.addClip()

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let gradColors = [
            NSColor(red: 0.22, green: 0.22, blue: 0.23, alpha: 1.0).cgColor,
            NSColor(red: 0.14, green: 0.14, blue: 0.15, alpha: 1.0).cgColor,
            NSColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1.0).cgColor
        ] as CFArray
        if let grad = CGGradient(colorsSpace: colorSpace, colors: gradColors, locations: [0.0, 0.50, 1.0]) {
            ctx.drawLinearGradient(
                grad,
                start: CGPoint(x: baseRect.midX, y: baseRect.maxY),
                end: CGPoint(x: baseRect.midX, y: baseRect.minY),
                options: []
            )
        }

        // 3. Subtle Technical Matrix Grid (6x6 cells, soft neutral slate)
        let cols = 6
        let rows = 6
        let stepX = baseRect.width / CGFloat(cols)
        let stepY = baseRect.height / CGFloat(rows)
        NSColor(white: 0.22, alpha: 0.40).setStroke()

        for i in 1..<cols {
            let x = baseRect.minX + CGFloat(i) * stepX
            let p = NSBezierPath()
            p.lineWidth = 1.0 * s
            p.move(to: NSPoint(x: x, y: baseRect.minY))
            p.line(to: NSPoint(x: x, y: baseRect.maxY))
            p.stroke()
        }
        for j in 1..<rows {
            let y = baseRect.minY + CGFloat(j) * stepY
            let p = NSBezierPath()
            p.lineWidth = 1.0 * s
            p.move(to: NSPoint(x: baseRect.minX, y: y))
            p.line(to: NSPoint(x: baseRect.maxX, y: y))
            p.stroke()
        }

        // 4. Specular Top Rim Highlight (Apple Utility Bezel)
        let rimPath = CGPath(roundedRect: baseRect.insetBy(dx: 1.0 * s, dy: 1.0 * s), cornerWidth: baseRadius - 1.0 * s, cornerHeight: baseRadius - 1.0 * s, transform: nil)
        let strokedRim = rimPath.copy(strokingWithWidth: 1.5 * s, lineCap: .round, lineJoin: .round, miterLimit: 10.0)
        ctx.addPath(strokedRim)
        ctx.clip()

        let rimColors = [
            NSColor.white.withAlphaComponent(0.24).cgColor,
            NSColor.white.withAlphaComponent(0.04).cgColor
        ] as CFArray
        if let rimGrad = CGGradient(colorsSpace: colorSpace, colors: rimColors, locations: [0.0, 1.0]) {
            ctx.drawLinearGradient(rimGrad, start: CGPoint(x: baseRect.midX, y: baseRect.maxY), end: CGPoint(x: baseRect.midX, y: baseRect.minY), options: [])
        }
        ctx.restoreGState()

        // 5. Terminal-Craft Embossed Relief X
        let centerX = baseRect.midX
        let centerY = baseRect.midY
        let span: CGFloat = 300.0 * s
        let half = span / 2.0
        let strokeW: CGFloat = 66.0 * s

        let cgPath = CGMutablePath()
        cgPath.move(to: CGPoint(x: centerX - half, y: centerY - half))
        cgPath.addLine(to: CGPoint(x: centerX + half, y: centerY + half))
        cgPath.move(to: CGPoint(x: centerX - half, y: centerY + half))
        cgPath.addLine(to: CGPoint(x: centerX + half, y: centerY - half))

        let strokedGlyph = cgPath.copy(strokingWithWidth: strokeW, lineCap: .round, lineJoin: .round, miterLimit: 10.0)

        // Drop shadow
        ctx.saveGState()
        let glyphShadow = NSShadow()
        glyphShadow.shadowColor = NSColor.black.withAlphaComponent(0.60)
        glyphShadow.shadowOffset = NSSize(width: 0, height: -6 * s)
        glyphShadow.shadowBlurRadius = 14 * s
        glyphShadow.set()
        ctx.addPath(strokedGlyph)
        ctx.setFillColor(NSColor.black.withAlphaComponent(0.6).cgColor)
        ctx.fillPath()
        ctx.restoreGState()

        // 3D Keycap Micro-Relief Bevel
        ctx.saveGState()
        ctx.translateBy(x: 0, y: -2.0 * s)
        ctx.addPath(strokedGlyph)
        ctx.setFillColor(NSColor(red: 0.50, green: 0.51, blue: 0.53, alpha: 1.0).cgColor)
        ctx.fillPath()
        ctx.restoreGState()

        // Crisp White Face
        ctx.saveGState()
        ctx.addPath(strokedGlyph)
        ctx.clip()

        let faceColors = [
            NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0).cgColor,
            NSColor(red: 0.94, green: 0.95, blue: 0.96, alpha: 1.0).cgColor
        ] as CFArray
        if let faceGrad = CGGradient(colorsSpace: colorSpace, colors: faceColors, locations: [0.0, 1.0]) {
            ctx.drawLinearGradient(faceGrad, start: CGPoint(x: centerX, y: centerY + half + strokeW/2), end: CGPoint(x: centerX, y: centerY - half - strokeW/2), options: [])
        }
        ctx.restoreGState()

        return true
    }
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
    let icon = renderTerminalCraftIcon(size: size)
    let rep = NSBitmapImageRep(data: icon.tiffRepresentation!)!
    let png = rep.representation(using: .png, properties: [:])!
    let path = "\(iconsetDir)/\(name)"
    try! png.write(to: URL(fileURLWithPath: path))
}

print("Iconset created at \(iconsetDir)")
