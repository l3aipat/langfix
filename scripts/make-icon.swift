// Draws the app icon and writes Resources/AppIcon.icns.
// usage: ICON_FONT=K2D swift scripts/make-icon.swift split   rebuild the shipped icon
//        swift scripts/make-icon.swift <style>              build the icon in one style
//        swift scripts/make-icon.swift previews             write every style side by side to build/icon-styles.png
//        swift scripts/make-icon.swift png <style> <out>    write one 1024 px PNG without touching the app icon
// ICON_FONT picks the typeface, such as "K2D"; the system font otherwise. Prefer an OFL font for
// anything distributed, since Apple's fonts are licensed for displaying content on macOS.
import AppKit

enum Style: String, CaseIterable {
    case gradient, keycap, split, minimal, cards
}

let tile = NSRect(x: 100, y: 100, width: 824, height: 824)
let radius: CGFloat = 185

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(red: CGFloat(hex >> 16 & 0xFF) / 255, green: CGFloat(hex >> 8 & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}

let family = ProcessInfo.processInfo.environment["ICON_FONT"]

func font(size: CGFloat, weight: NSFont.Weight, monospaced: Bool) -> NSFont {
    if let family, let font = NSFontManager.shared.font(withFamily: family, traits: weight >= .semibold ? .boldFontMask : [],
                                                         weight: weight >= .semibold ? 9 : 5, size: size) {
        return font
    }
    return monospaced ? .monospacedSystemFont(ofSize: size, weight: weight) : .systemFont(ofSize: size, weight: weight)
}

func text(_ string: String, size: CGFloat, weight: NSFont.Weight = .bold, color: NSColor = .white,
          center: CGPoint, monospaced: Bool = false) {
    let font = font(size: size, weight: weight, monospaced: monospaced)
    let attributed = NSAttributedString(string: string, attributes: [.font: font, .foregroundColor: color])
    let bounds = attributed.size()
    attributed.draw(at: CGPoint(x: center.x - bounds.width / 2, y: center.y - bounds.height / 2))
}

func symbol(_ name: String, size: CGFloat, color: NSColor, center: CGPoint) {
    let image = NSImage(systemSymbolName: name, accessibilityDescription: nil)!
        .withSymbolConfiguration(.init(pointSize: size, weight: .heavy).applying(.init(paletteColors: [color])))!
    image.draw(in: NSRect(x: center.x - image.size.width / 2, y: center.y - image.size.height / 2,
                          width: image.size.width, height: image.size.height))
}

func roundedTile(_ rect: NSRect = tile, radius: CGFloat = radius) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

/// Every style draws in a 1024-point square; `render` scales it to the requested pixel size.
func draw(_ style: Style) {
    switch style {
    case .gradient:
        NSGradient(colors: [color(0x218C9E), color(0x3340A0)])!.draw(in: roundedTile(), angle: -60)
        text("ก", size: 400, center: CGPoint(x: 370, y: 610))
        text("a", size: 380, color: .white.withAlphaComponent(0.92), center: CGPoint(x: 660, y: 380))
        symbol("arrow.left.arrow.right", size: 150, color: .white.withAlphaComponent(0.8), center: CGPoint(x: 330, y: 300))

    case .keycap:
        NSGradient(colors: [color(0xF4F4F6), color(0xD9DAE0)])!.draw(in: roundedTile(), angle: -90)
        color(0x000000, 0.12).setFill()
        roundedTile(tile.insetBy(dx: 70, dy: 70).offsetBy(dx: 0, dy: 10), radius: 120).fill()
        NSGradient(colors: [color(0xFFFFFF), color(0xEDEEF2)])!
            .draw(in: roundedTile(tile.insetBy(dx: 70, dy: 70).offsetBy(dx: 0, dy: 30), radius: 120), angle: -90)
        text("a", size: 300, weight: .semibold, color: color(0x2B2D42), center: CGPoint(x: 360, y: 650))
        text("ฟ", size: 300, weight: .semibold, color: color(0xD1495B), center: CGPoint(x: 660, y: 380))

    case .split:
        NSGraphicsContext.saveGraphicsState()
        roundedTile().addClip()
        color(0x1D3557).setFill()
        tile.fill()
        let diagonal = NSBezierPath()
        diagonal.move(to: CGPoint(x: tile.minX, y: tile.minY))
        diagonal.line(to: CGPoint(x: tile.maxX, y: tile.minY))
        diagonal.line(to: CGPoint(x: tile.maxX, y: tile.maxY))
        diagonal.close()
        color(0xE76F51).setFill()
        diagonal.fill()
        NSGraphicsContext.restoreGraphicsState()
        text("ก", size: 360, center: CGPoint(x: 360, y: 640))
        text("a", size: 360, center: CGPoint(x: 670, y: 360))

    case .minimal:
        color(0x111114).setFill()
        roundedTile().fill()
        text("ก/a", size: 270, weight: .medium, center: CGPoint(x: 512, y: 530), monospaced: true)
        color(0x4CC9F0).setFill()
        NSBezierPath(ovalIn: NSRect(x: 482, y: 270, width: 60, height: 60)).fill()

    case .cards:
        NSGradient(colors: [color(0xFFF3E0), color(0xFFE0B2)])!.draw(in: roundedTile(), angle: -90)
        let back = NSRect(x: 230, y: 330, width: 380, height: 460)
        let front = NSRect(x: 420, y: 230, width: 380, height: 460)
        // The front card covers the back card's right side, so its glyph sits left of centre.
        for (rect, fill, glyph, angle, shift) in [
            (back, color(0x2A9D8F), "ก", CGFloat(-8), CGFloat(-85)), (front, color(0x264653), "a", CGFloat(8), CGFloat(0)),
        ] {
            NSGraphicsContext.saveGraphicsState()
            let transform = NSAffineTransform()
            transform.translateX(by: rect.midX, yBy: rect.midY)
            transform.rotate(byDegrees: angle)
            transform.translateX(by: -rect.midX, yBy: -rect.midY)
            transform.concat()
            color(0x000000, 0.15).setFill()
            roundedTile(rect.offsetBy(dx: 0, dy: -14), radius: 70).fill()
            fill.setFill()
            roundedTile(rect, radius: 70).fill()
            text(glyph, size: 260, center: CGPoint(x: rect.midX + shift, y: rect.midY + 60))
            NSGraphicsContext.restoreGraphicsState()
        }
    }
}

/// Draws into a bitmap of exactly `size` pixels; an NSImage would double it on a Retina screen.
func render(_ style: Style, size: Int) -> NSBitmapImageRep {
    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8,
        samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    let scale = NSAffineTransform()
    scale.scale(by: CGFloat(size) / 1024)
    scale.concat()
    draw(style)
    NSGraphicsContext.restoreGraphicsState()
    return bitmap
}

func png(_ bitmap: NSBitmapImageRep) -> Data {
    bitmap.representation(using: .png, properties: [:])!
}

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let argument = CommandLine.arguments.dropFirst().first ?? ""

if argument == "previews" {
    // Each style at full size and at 64 px, so legibility in the Dock and Finder lists can be judged.
    let cell = 400, small = 64, gap = 40
    let width = Style.allCases.count * (cell + gap) + gap
    let sheet = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: cell + small + 140, bitsPerSample: 8,
        samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: sheet)
    color(0xECECEC).setFill()
    NSRect(x: 0, y: 0, width: width, height: sheet.pixelsHigh).fill()
    for (index, style) in Style.allCases.enumerated() {
        let x = gap + index * (cell + gap)
        render(style, size: cell).draw(in: NSRect(x: x, y: small + 100, width: cell, height: cell))
        render(style, size: small).draw(in: NSRect(x: x + (cell - small) / 2, y: 70, width: small, height: small))
        text("\(index + 1). \(style.rawValue)", size: 28, weight: .semibold, color: color(0x333333),
             center: CGPoint(x: x + cell / 2, y: 30))
    }
    NSGraphicsContext.restoreGraphicsState()
    let out = root.appendingPathComponent("build/icon-styles.png")
    try png(sheet).write(to: out)
    print("wrote \(out.path)")
    exit(0)
}

if argument == "png", CommandLine.arguments.count == 4, let style = Style(rawValue: CommandLine.arguments[2]) {
    try png(render(style, size: 1024)).write(to: URL(fileURLWithPath: CommandLine.arguments[3]))
    exit(0)
}

guard let style = Style(rawValue: argument) else {
    print("usage: swift scripts/make-icon.swift <\(Style.allCases.map(\.rawValue).joined(separator: "|"))|previews>")
    exit(64)
}
let iconset = FileManager.default.temporaryDirectory.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for points in [16, 32, 128, 256, 512] {
    for factor in [1, 2] {
        let name = factor == 1 ? "icon_\(points)x\(points).png" : "icon_\(points)x\(points)@2x.png"
        try png(render(style, size: points * factor)).write(to: iconset.appendingPathComponent(name))
    }
}
let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset.path, "-o", root.appendingPathComponent("Resources/AppIcon.icns").path]
try iconutil.run()
iconutil.waitUntilExit()
print(iconutil.terminationStatus == 0 ? "wrote Resources/AppIcon.icns (\(style.rawValue))" : "iconutil failed")
