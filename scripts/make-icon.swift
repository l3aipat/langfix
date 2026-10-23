// Draws the app icon and writes Resources/AppIcon.icns.
// usage: swift scripts/make-icon.swift
import AppKit

/// Draws into a bitmap of exactly `size` pixels; an NSImage would double it on a Retina screen.
func render(size: CGFloat) -> Data {
    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size), bitsPerSample: 8,
        samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    do {  // scopes the drawing between save and restore
        let scale = size / 1024
        let tile = NSRect(x: 100, y: 100, width: 824, height: 824)
        let path = NSBezierPath(roundedRect: tile.applying(scale), xRadius: 185 * scale, yRadius: 185 * scale)
        NSGradient(colors: [
            NSColor(red: 0.13, green: 0.55, blue: 0.62, alpha: 1),
            NSColor(red: 0.20, green: 0.25, blue: 0.62, alpha: 1),
        ])!.draw(in: path, angle: -60)

        func glyph(_ text: String, _ fontSize: CGFloat, _ weight: NSFont.Weight, _ alpha: CGFloat, center: CGPoint) {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: fontSize * scale, weight: weight),
                .foregroundColor: NSColor.white.withAlphaComponent(alpha),
            ]
            let string = NSAttributedString(string: text, attributes: attributes)
            let bounds = string.size()
            string.draw(at: CGPoint(x: center.x * scale - bounds.width / 2, y: center.y * scale - bounds.height / 2))
        }
        glyph("ก", 400, .bold, 1, center: CGPoint(x: 370, y: 610))
        glyph("a", 380, .bold, 0.92, center: CGPoint(x: 660, y: 380))
        let arrows = NSImage(systemSymbolName: "arrow.left.arrow.right", accessibilityDescription: nil)!
            .withSymbolConfiguration(.init(pointSize: 150 * scale, weight: .heavy).applying(.init(paletteColors: [.white])))!
        let arrowSize = arrows.size
        arrows.draw(in: NSRect(x: 330 * scale - arrowSize.width / 2, y: 300 * scale - arrowSize.height / 2,
                               width: arrowSize.width, height: arrowSize.height),
                    from: .zero, operation: .sourceOver, fraction: 0.8)
    }
    NSGraphicsContext.restoreGraphicsState()
    return bitmap.representation(using: .png, properties: [:])!
}

extension NSRect {
    func applying(_ scale: CGFloat) -> NSRect {
        NSRect(x: minX * scale, y: minY * scale, width: width * scale, height: height * scale)
    }
}

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let iconset = FileManager.default.temporaryDirectory.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for points in [16, 32, 128, 256, 512] {
    for factor in [1, 2] {
        let name = factor == 1 ? "icon_\(points)x\(points).png" : "icon_\(points)x\(points)@2x.png"
        try render(size: CGFloat(points * factor)).write(to: iconset.appendingPathComponent(name))
    }
}
try render(size: 1024).write(to: root.appendingPathComponent("build/AppIcon-preview.png"))
let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset.path, "-o", root.appendingPathComponent("Resources/AppIcon.icns").path]
try iconutil.run()
iconutil.waitUntilExit()
print(iconutil.terminationStatus == 0 ? "wrote Resources/AppIcon.icns" : "iconutil failed")
