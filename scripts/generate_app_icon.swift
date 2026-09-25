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
            NSColor(red: 0.22, green: 0.24, blue: 0.28, alpha: 1.0).cgColor,
            NSColor(red: 0.14, green: 0.15, blue: 0.18, alpha: 1.0).cgColor,
            NSColor(red: 0.08, green: 0.09, blue: 0.11, alpha: 1.0).cgColor
        ] as CFArray
        let locations: [CGFloat] = [0.0, 0.5, 1.0]
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
        NSColor.white.withAlphaComponent(0.15).setStroke()
        innerBorder.lineWidth = 2.0 * s
        innerBorder.stroke()
        ctx.restoreGState()

        // 2. Circular Frosted Acrylic Lens / Backing Disc (590 diameter)
        let circleRadius: CGFloat = 295.0 * s
        let centerX = baseRect.midX
        let centerY = baseRect.midY
        let circleRect = NSRect(x: centerX - circleRadius, y: centerY - circleRadius, width: circleRadius * 2, height: circleRadius * 2)

        // Acrylic Disc Shadow onto base
        ctx.saveGState()
        let discShadow = NSShadow()
        discShadow.shadowColor = NSColor.black.withAlphaComponent(0.48)
        discShadow.shadowOffset = NSSize(width: 0, height: -16 * s)
        discShadow.shadowBlurRadius = 26 * s
        discShadow.set()
        NSColor(white: 0.05, alpha: 0.5).setFill()
        NSBezierPath(ovalIn: circleRect).fill()
        ctx.restoreGState()

        // Acrylic Body (Frosted Translucent Glass Gradient)
        ctx.saveGState()
        let circleClip = NSBezierPath(ovalIn: circleRect)
        circleClip.addClip()

        let glassGradColors = [
            NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.50).cgColor,
            NSColor(red: 0.90, green: 0.93, blue: 0.98, alpha: 0.25).cgColor,
            NSColor(red: 0.20, green: 0.24, blue: 0.32, alpha: 0.20).cgColor,
            NSColor(red: 0.08, green: 0.10, blue: 0.14, alpha: 0.40).cgColor
        ] as CFArray
        let glassLocations: [CGFloat] = [0.0, 0.35, 0.75, 1.0]
        if let glassGrad = CGGradient(colorsSpace: colorSpace, colors: glassGradColors, locations: glassLocations) {
            ctx.drawLinearGradient(
                glassGrad,
                start: CGPoint(x: centerX, y: circleRect.maxY),
                end: CGPoint(x: centerX, y: circleRect.minY),
                options: []
            )
        }

        // Acrylic Specular Chamfer Rim (Top highlight, bottom reflection)
        let rimPath = CGPath(ellipseIn: circleRect.insetBy(dx: 1.5 * s, dy: 1.5 * s), transform: nil)
        let strokedRim = rimPath.copy(strokingWithWidth: 2.5 * s, lineCap: .round, lineJoin: .round, miterLimit: 10.0)
        ctx.addPath(strokedRim)
        ctx.clip()

        let rimGradColors = [
            NSColor(white: 1.0, alpha: 0.70).cgColor,
            NSColor(white: 1.0, alpha: 0.25).cgColor,
            NSColor(white: 1.0, alpha: 0.08).cgColor,
            NSColor(white: 1.0, alpha: 0.30).cgColor
        ] as CFArray
        let rimLocations: [CGFloat] = [0.0, 0.35, 0.75, 1.0]
        if let rimGrad = CGGradient(colorsSpace: colorSpace, colors: rimGradColors, locations: rimLocations) {
            ctx.drawLinearGradient(
                rimGrad,
                start: CGPoint(x: centerX, y: circleRect.maxY),
                end: CGPoint(x: centerX, y: circleRect.minY),
                options: []
            )
        }
        ctx.restoreGState()

        // 3. Crisp Dimensional White 'X' Symbol on top of the acrylic disc
        let xSpan: CGFloat = 310.0 * s
        let xHalf = xSpan / 2.0
        let strokeW: CGFloat = 78.0 * s

        let cgPath = CGMutablePath()
        let p1 = CGPoint(x: centerX - xHalf, y: centerY - xHalf)
        let p2 = CGPoint(x: centerX + xHalf, y: centerY + xHalf)
        let p3 = CGPoint(x: centerX - xHalf, y: centerY + xHalf)
        let p4 = CGPoint(x: centerX + xHalf, y: centerY - xHalf)

        cgPath.move(to: p1)
        cgPath.addLine(to: p2)
        cgPath.move(to: p3)
        cgPath.addLine(to: p4)

        let strokedCGPath = cgPath.copy(strokingWithWidth: strokeW, lineCap: .round, lineJoin: .round, miterLimit: 10.0)

        // Contact shadow onto acrylic surface
        ctx.saveGState()
        let contactShadow = NSShadow()
        contactShadow.shadowColor = NSColor.black.withAlphaComponent(0.42)
        contactShadow.shadowOffset = NSSize(width: 0, height: -3 * s)
        contactShadow.shadowBlurRadius = 6 * s
        contactShadow.set()
        ctx.addPath(strokedCGPath)
        ctx.setFillColor(NSColor.black.withAlphaComponent(0.4).cgColor)
        ctx.fillPath()
        ctx.restoreGState()

        // Soft elevation shadow onto acrylic surface
        ctx.saveGState()
        let elevationShadow = NSShadow()
        elevationShadow.shadowColor = NSColor.black.withAlphaComponent(0.38)
        elevationShadow.shadowOffset = NSSize(width: 0, height: -14 * s)
        elevationShadow.shadowBlurRadius = 22 * s
        elevationShadow.set()
        ctx.addPath(strokedCGPath)
        ctx.setFillColor(NSColor.black.withAlphaComponent(0.3).cgColor)
        ctx.fillPath()
        ctx.restoreGState()

        // Solid White Body with Subtle Top-to-Bottom Lighting
        ctx.saveGState()
        ctx.addPath(strokedCGPath)
        ctx.clip()

        let xGradColors = [
            NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0).cgColor,
            NSColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1.0).cgColor,
            NSColor(red: 0.88, green: 0.90, blue: 0.93, alpha: 1.0).cgColor
        ] as CFArray
        let xLocations: [CGFloat] = [0.0, 0.45, 1.0]
        if let xGrad = CGGradient(colorsSpace: colorSpace, colors: xGradColors, locations: xLocations) {
            ctx.drawLinearGradient(
                xGrad,
                start: CGPoint(x: centerX, y: centerY + xHalf + strokeW/2),
                end: CGPoint(x: centerX, y: centerY - xHalf - strokeW/2),
                options: []
            )
        }

        // Subtle Top Specular Rim on the X
        let highlightGradColors = [
            NSColor.white.withAlphaComponent(0.60).cgColor,
            NSColor.white.withAlphaComponent(0.0).cgColor
        ] as CFArray
        if let hGrad = CGGradient(colorsSpace: colorSpace, colors: highlightGradColors, locations: [0.0, 1.0]) {
            ctx.drawLinearGradient(
                hGrad,
                start: CGPoint(x: centerX, y: centerY + xHalf + strokeW/2),
                end: CGPoint(x: centerX, y: centerY),
                options: []
            )
        }

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
