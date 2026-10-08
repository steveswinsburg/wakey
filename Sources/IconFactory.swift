import Cocoa

/// Draws the full-colour glowing-lightbulb artwork used to build the
/// app's .icns icon. The menu bar glyph uses the system's built-in SF
/// Symbol lightbulb icons instead (see `main.swift`), since those render
/// crisply at small sizes and adapt automatically to light/dark mode.
enum IconFactory {

    /// Full colour glowing lightbulb artwork used for the application icon.
    static func makeAppIcon(size: CGFloat) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()

        // Background: rounded square, deep night-sky gradient so the
        // glowing bulb reads clearly.
        let bgRect = NSRect(x: 0, y: 0, width: size, height: size)
        let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: size * 0.22, yRadius: size * 0.22)
        let bgGradient = NSGradient(colors: [
            NSColor(calibratedRed: 0.20, green: 0.22, blue: 0.36, alpha: 1.0),
            NSColor(calibratedRed: 0.11, green: 0.12, blue: 0.22, alpha: 1.0)
        ])
        bgGradient?.draw(in: bgPath, angle: -90)

        let globeRadius = size * 0.21
        let globeCenter = NSPoint(x: size * 0.5, y: size * 0.60)

        // Soft glow halo behind the bulb.
        let glowRadius = globeRadius * 2.1
        if let glowGradient = NSGradient(colors: [
            NSColor(calibratedRed: 1.0, green: 0.92, blue: 0.55, alpha: 0.55),
            NSColor(calibratedRed: 1.0, green: 0.92, blue: 0.55, alpha: 0.0)
        ]) {
            let glowRect = NSRect(
                x: globeCenter.x - glowRadius, y: globeCenter.y - glowRadius,
                width: glowRadius * 2, height: glowRadius * 2)
            glowGradient.draw(in: NSBezierPath(ovalIn: glowRect), relativeCenterPosition: .zero)
        }

        let glassGold = NSColor(calibratedRed: 0.72, green: 0.56, blue: 0.16, alpha: 1.0)
        let metalLight = NSColor(calibratedRed: 0.82, green: 0.84, blue: 0.88, alpha: 1.0)
        let metalDark = NSColor(calibratedRed: 0.55, green: 0.57, blue: 0.61, alpha: 1.0)

        // Screw base (ferrule), drawn first so the glass neck overlaps its top.
        let baseWidth = globeRadius * 1.05
        let baseRect = NSRect(x: globeCenter.x - baseWidth / 2, y: size * 0.17, width: baseWidth, height: globeRadius * 0.62)
        let basePath = NSBezierPath(roundedRect: baseRect, xRadius: baseWidth * 0.12, yRadius: baseWidth * 0.12)
        let metalGradient = NSGradient(colors: [metalLight, metalDark])
        metalGradient?.draw(in: basePath, angle: -90)
        // Screw-thread ridge lines.
        NSColor(calibratedWhite: 0.3, alpha: 0.6).setStroke()
        for i in 1...2 {
            let y = baseRect.minY + baseRect.height * (CGFloat(i) / 3.0)
            let ridge = NSBezierPath()
            ridge.move(to: NSPoint(x: baseRect.minX + baseRect.width * 0.1, y: y))
            ridge.line(to: NSPoint(x: baseRect.maxX - baseRect.width * 0.1, y: y))
            ridge.lineWidth = size * 0.01
            ridge.stroke()
        }

        // Neck tapering from the base up into the glass globe.
        let neckTopWidth = globeRadius * 1.15
        let neckBottomWidth = baseWidth * 0.9
        let neckPath = NSBezierPath()
        neckPath.move(to: NSPoint(x: globeCenter.x - neckBottomWidth / 2, y: baseRect.maxY - size * 0.01))
        neckPath.line(to: NSPoint(x: globeCenter.x - neckTopWidth / 2, y: globeCenter.y - globeRadius * 0.55))
        neckPath.line(to: NSPoint(x: globeCenter.x + neckTopWidth / 2, y: globeCenter.y - globeRadius * 0.55))
        neckPath.line(to: NSPoint(x: globeCenter.x + neckBottomWidth / 2, y: baseRect.maxY - size * 0.01))
        neckPath.close()
        let glassGradientPale = NSColor(calibratedRed: 1.00, green: 0.97, blue: 0.85, alpha: 1.0)
        glassGradientPale.setFill()
        neckPath.fill()
        glassGold.setStroke()
        neckPath.lineWidth = size * 0.012
        neckPath.stroke()

        // Glass globe: fatter near the top, narrowing down to the neck —
        // a classic bulb silhouette rather than a plain circle.
        let bottomHalfWidth = globeRadius * 0.6
        let topHalfWidth = globeRadius * 1.22
        let globeBottomY = globeCenter.y - globeRadius * 0.85
        let globeTopY = globeCenter.y + globeRadius * 1.08
        let widestY = globeCenter.y + globeRadius * 0.18

        let globePath = NSBezierPath()
        globePath.move(to: NSPoint(x: globeCenter.x - bottomHalfWidth, y: globeBottomY))
        globePath.curve(
            to: NSPoint(x: globeCenter.x - topHalfWidth, y: widestY),
            controlPoint1: NSPoint(x: globeCenter.x - bottomHalfWidth, y: globeBottomY + (widestY - globeBottomY) * 0.6),
            controlPoint2: NSPoint(x: globeCenter.x - topHalfWidth, y: widestY - (widestY - globeBottomY) * 0.35))
        globePath.curve(
            to: NSPoint(x: globeCenter.x, y: globeTopY),
            controlPoint1: NSPoint(x: globeCenter.x - topHalfWidth, y: widestY + (globeTopY - widestY) * 0.7),
            controlPoint2: NSPoint(x: globeCenter.x - topHalfWidth * 0.5, y: globeTopY))
        globePath.curve(
            to: NSPoint(x: globeCenter.x + topHalfWidth, y: widestY),
            controlPoint1: NSPoint(x: globeCenter.x + topHalfWidth * 0.5, y: globeTopY),
            controlPoint2: NSPoint(x: globeCenter.x + topHalfWidth, y: widestY + (globeTopY - widestY) * 0.7))
        globePath.curve(
            to: NSPoint(x: globeCenter.x + bottomHalfWidth, y: globeBottomY),
            controlPoint1: NSPoint(x: globeCenter.x + topHalfWidth, y: widestY - (widestY - globeBottomY) * 0.35),
            controlPoint2: NSPoint(x: globeCenter.x + bottomHalfWidth, y: globeBottomY + (widestY - globeBottomY) * 0.6))
        globePath.close()

        let globeGradient = NSGradient(colors: [
            NSColor(calibratedRed: 1.00, green: 0.98, blue: 0.88, alpha: 1.0),
            NSColor(calibratedRed: 1.00, green: 0.84, blue: 0.40, alpha: 1.0)
        ])
        globeGradient?.draw(in: globePath, angle: 90)
        glassGold.setStroke()
        globePath.lineWidth = size * 0.014
        globePath.stroke()

        // Filament: a simple zigzag suggesting glowing wire inside the bulb.
        let filament = NSBezierPath()
        let fTop = globeCenter.y + globeRadius * 0.28
        let fBottom = globeCenter.y - globeRadius * 0.32
        let fHalfWidth = globeRadius * 0.28
        filament.move(to: NSPoint(x: globeCenter.x - fHalfWidth * 0.6, y: fTop))
        filament.line(to: NSPoint(x: globeCenter.x - fHalfWidth, y: fBottom + (fTop - fBottom) * 0.5))
        filament.line(to: NSPoint(x: globeCenter.x, y: fTop))
        filament.line(to: NSPoint(x: globeCenter.x + fHalfWidth, y: fBottom + (fTop - fBottom) * 0.5))
        filament.line(to: NSPoint(x: globeCenter.x + fHalfWidth * 0.6, y: fBottom))
        NSColor(calibratedRed: 0.55, green: 0.38, blue: 0.08, alpha: 1.0).setStroke()
        filament.lineWidth = size * 0.014
        filament.lineCapStyle = .round
        filament.lineJoinStyle = .round
        filament.stroke()

        image.unlockFocus()
        return image
    }
}

