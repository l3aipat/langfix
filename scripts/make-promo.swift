// Renders a 1080x1920 promo clip of LangFix fixing wrong-layout typing to build/LangFix-promo.mp4.
// Every scene shows behaviour the app really has; the typing is drawn, not screen-recorded.
// usage: swift scripts/make-promo.swift [stills]   (stills also writes a few frames as PNGs)
import AppKit
import AVFoundation

let width = 1080, height = 1920, fps = 30

struct Step {
    let at: Double
    let text: String
    let layout: String
    var key: String? = nil
    var badge: String? = nil
}

struct Scene {
    let start: Double
    let end: Double
    let caption: String
    var subcaption = ""
    var steps: [Step] = []
    var isFinale = false
}

/// Builds steps that type one key every `interval` seconds starting at `start`.
func typing(_ states: [(key: String, text: String, layout: String, badge: String?)], from start: Double,
            interval: Double = 0.32) -> [Step] {
    states.enumerated().map { i, s in Step(at: start + Double(i) * interval, text: s.text, layout: s.layout, key: s.key, badge: s.badge) }
}

let scenes: [Scene] = [
    Scene(start: 0, end: 3.6, caption: "พิมพ์ไทย แต่ลืมเปลี่ยนแป้น", subcaption: "ต้องลบแล้วพิมพ์ใหม่ทุกที",
          steps: [Step(at: 0, text: "", layout: "EN")] + typing([
              ("L", "l", "EN", nil), (";", "l;", "EN", nil), ("Y", "l;y", "EN", nil),
              ("L", "l;yl", "EN", nil), ("F", "l;ylf", "EN", nil), ("U", "l;ylfu", "EN", nil),
          ], from: 0.5)),
    Scene(start: 3.6, end: 8.4, caption: "LangFix แก้ให้ทันที", subcaption: "พิมพ์ไปได้เลย ไม่ต้องหยุด",
          steps: [Step(at: 3.6, text: "", layout: "EN")] + typing([
              ("L", "l", "EN", nil), (";", "l;", "EN", nil), ("Y", "สวั", "TH", "ก"),
              ("L", "สวัส", "TH", nil), ("F", "สวัสด", "TH", nil), ("U", "สวัสดี", "TH", nil),
          ], from: 4.1, interval: 0.42)),
    Scene(start: 8.4, end: 12.4, caption: "ภาษาอังกฤษก็ได้", subcaption: "ลืมสลับกลับเป็นอังกฤษ ก็แก้ให้",
          steps: [Step(at: 8.4, text: "", layout: "TH")] + typing([
              ("H", "้", "TH", nil), ("E", "้ำ", "TH", nil), ("L", "hel", "EN", "A"),
              ("L", "hell", "EN", nil), ("O", "hello", "EN", nil),
          ], from: 8.9, interval: 0.42)),
    Scene(start: 12.4, end: 15.8, caption: "คำสั้นก็ไม่หลุด", subcaption: "แก้ให้ตอนกดเว้นวรรค",
          steps: [Step(at: 12.4, text: "", layout: "EN")] + typing([
              ("O", "o", "EN", nil), ("T", "ot", "EN", nil), ("SPACE", "นะ ", "TH", "ก"),
              ("W", "นะ ไ", "TH", nil), (",", "นะ ไม", "TH", nil), ("J", "นะ ไม่", "TH", nil),
          ], from: 12.9, interval: 0.4)),
    Scene(start: 15.8, end: 19.4, caption: "แก้ผิด? กด Delete ทันที", subcaption: "ย้อนกลับเป็นที่พิมพ์ไว้",
          steps: [Step(at: 15.8, text: "", layout: "EN")] + typing([
              ("L", "l", "EN", nil), (";", "l;", "EN", nil), ("Y", "สวั", "TH", "ก"),
              ("DELETE", "l;y", "EN", "A"),
          ], from: 16.2, interval: 0.55)),
    Scene(start: 19.4, end: 24, caption: "LangFix", subcaption: "แก้คำพิมพ์ผิดแป้น ไทย ⇄ อังกฤษ สำหรับ Mac", isFinale: true),
]
let duration = scenes.last!.end

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(red: CGFloat(hex >> 16 & 0xFF) / 255, green: CGFloat(hex >> 8 & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}
let navy = color(0x1D3557), coral = color(0xE76F51), ink = color(0x1F2430), paper = color(0xFFFFFF)

@discardableResult
func text(_ string: String, size: CGFloat, weight: NSFont.Weight = .bold, color: NSColor, center: CGPoint? = nil,
          origin: CGPoint? = nil, alpha: CGFloat = 1) -> NSSize {
    let attributed = NSAttributedString(string: string, attributes: [
        .font: NSFont.systemFont(ofSize: size, weight: weight), .foregroundColor: color.withAlphaComponent(alpha),
    ])
    let bounds = attributed.size()
    let point = origin ?? CGPoint(x: center!.x - bounds.width / 2, y: center!.y - bounds.height / 2)
    attributed.draw(at: point)
    return bounds
}

func rounded(_ rect: NSRect, _ radius: CGFloat, _ fill: NSColor) {
    fill.setFill()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
}

func ease(_ x: Double) -> CGFloat { CGFloat(1 - pow(1 - min(max(x, 0), 1), 3)) }

let icon = NSImage(contentsOfFile: URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    .deletingLastPathComponent().appendingPathComponent("Resources/AppIcon.icns").path)

/// Draws the frame at time `t` (seconds) into the current graphics context.
func drawFrame(_ t: Double) {
    let scene = scenes.last { $0.start <= t } ?? scenes[0]
    let local = t - scene.start
    NSGradient(colors: [navy, color(0x2B3F6B), coral])!.draw(in: NSRect(x: 0, y: 0, width: width, height: height), angle: -70)

    let captionIn = ease(local / 0.35)
    text(scene.caption, size: scene.isFinale ? 120 : 84, color: paper, center: CGPoint(x: 540, y: 1560 + (1 - captionIn) * 40),
         alpha: captionIn)
    text(scene.subcaption, size: 44, weight: .medium, color: paper, center: CGPoint(x: 540, y: scene.isFinale ? 1440 : 1450),
         alpha: captionIn * 0.85)

    if scene.isFinale {
        let pop = ease(local / 0.5)
        let side: CGFloat = 420 * (0.8 + 0.2 * pop)
        icon?.draw(in: NSRect(x: 540 - side / 2, y: 820 - side / 2, width: side, height: side), from: .zero,
                   operation: .sourceOver, fraction: pop)
        let ctaIn = ease((local - 0.8) / 0.4)
        rounded(NSRect(x: 140, y: 380, width: 800, height: 150), 75, paper.withAlphaComponent(ctaIn))
        text("สนใจ? คอมเมนต์ “อยากได้”", size: 56, color: coral, center: CGPoint(x: 540, y: 455), alpha: ctaIn)
        text("ทำงานในเครื่อง ไม่ส่งข้อความที่พิมพ์ออกไปไหน", size: 36, weight: .medium, color: paper,
             center: CGPoint(x: 540, y: 290), alpha: ctaIn * 0.85)
        return
    }

    let step = scene.steps.last { $0.at <= t } ?? scene.steps[0]

    // A chat window with a message box, the layout shown in its corner like the macOS menu bar.
    let window = NSRect(x: 90, y: 760, width: 900, height: 520)
    rounded(window, 44, paper)
    rounded(NSRect(x: window.minX, y: window.maxY - 90, width: window.width, height: 90), 44, color(0xF1F2F6))
    color(0xF1F2F6).setFill()
    NSRect(x: window.minX, y: window.maxY - 90, width: window.width, height: 40).fill()
    for (i, dot) in [0xFF5F57, 0xFEBC2E, 0x28C840].enumerated() {
        color(UInt32(dot)).setFill()
        NSBezierPath(ovalIn: NSRect(x: window.minX + 36 + CGFloat(i) * 38, y: window.maxY - 58, width: 24, height: 24)).fill()
    }
    rounded(NSRect(x: window.maxX - 150, y: window.maxY - 70, width: 110, height: 50), 14, step.layout == "TH" ? coral : navy)
    text(step.layout == "TH" ? "ไทย" : "ABC", size: 30, color: paper, center: CGPoint(x: window.maxX - 95, y: window.maxY - 45))

    let field = NSRect(x: window.minX + 50, y: window.minY + 150, width: window.width - 100, height: 160)
    rounded(field, 30, color(0xF6F7FB))
    let typed = text(step.text, size: 96, weight: .semibold, color: ink, origin: CGPoint(x: field.minX + 40, y: field.minY + 22))
    let caretX = field.minX + 44 + (step.text.isEmpty ? 0 : typed.width)
    if Int(t * 2.4) % 2 == 0 || t - step.at < 0.4 {
        coral.setFill()
        NSRect(x: caretX, y: field.minY + 36, width: 6, height: 92).fill()
    }

    // The badge LangFix flashes beside the caret when it switches layout.
    if let badge = step.badge, t - step.at < 0.9 {
        let pop = ease((t - step.at) / 0.15) * CGFloat(min(1, (0.9 - (t - step.at)) / 0.25))
        let box = NSRect(x: caretX + 14, y: field.minY - 64, width: 76, height: 76)
        rounded(box, 18, NSColor(white: 0.1, alpha: 0.88 * pop))
        text(badge, size: 46, color: paper, center: CGPoint(x: box.midX, y: box.midY + 2), alpha: pop)
    }
    text("LangFix", size: 30, weight: .semibold, color: color(0x8A90A0), origin: CGPoint(x: field.minX + 4, y: window.minY + 60))

    // The key being pressed, so viewers can see what was actually typed.
    if let key = step.key, t - step.at < 0.6 {
        let press = 1 - CGFloat(min(1, (t - step.at) / 0.6))
        let cap = NSRect(x: 540 - (key.count > 1 ? 170 : 90), y: 470, width: key.count > 1 ? 340 : 180, height: 180)
        rounded(cap.offsetBy(dx: 0, dy: -12), 32, NSColor(white: 0, alpha: 0.25 * press + 0.1))
        rounded(cap.offsetBy(dx: 0, dy: -12 * (1 - press)), 32, paper)
        text(key, size: key.count > 1 ? 54 : 88, color: ink, center: CGPoint(x: cap.midX, y: cap.midY - 12 * (1 - press)))
    }
    text("ปุ่มที่กด", size: 34, weight: .medium, color: paper, center: CGPoint(x: 540, y: 400), alpha: 0.7)
}

func render(_ t: Double, into context: CGContext) {
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
    drawFrame(t)
    NSGraphicsContext.restoreGraphicsState()
}

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let out = root.appendingPathComponent("build/LangFix-promo.mp4")
try? FileManager.default.removeItem(at: out)

if CommandLine.arguments.dropFirst().first == "stills" {
    for t in [2.8, 5.2, 9.9, 13.9, 17.6, 21.5] {
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8,
                                   samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                                   bytesPerRow: 0, bitsPerPixel: 0)!
        render(t, into: NSGraphicsContext(bitmapImageRep: rep)!.cgContext)
        try rep.representation(using: .png, properties: [:])!.write(to: root.appendingPathComponent("build/promo-\(t).png"))
    }
}

let writer = try AVAssetWriter(outputURL: out, fileType: .mp4)
let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
    AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: width, AVVideoHeightKey: height,
    AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 8_000_000],
])
let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
    kCVPixelBufferWidthKey as String: width, kCVPixelBufferHeightKey as String: height,
])
writer.add(input)
writer.startWriting()
writer.startSession(atSourceTime: .zero)

for frame in 0..<Int(duration * Double(fps)) {
    while !input.isReadyForMoreMediaData { usleep(1000) }
    var buffer: CVPixelBuffer?
    CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, &buffer)
    CVPixelBufferLockBaseAddress(buffer!, [])
    let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer!), width: width, height: height, bitsPerComponent: 8,
                            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer!), space: CGColorSpaceCreateDeviceRGB(),
                            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)!
    render(Double(frame) / Double(fps), into: context)
    CVPixelBufferUnlockBaseAddress(buffer!, [])
    adaptor.append(buffer!, withPresentationTime: CMTime(value: CMTimeValue(frame), timescale: CMTimeScale(fps)))
}
input.markAsFinished()
let done = DispatchSemaphore(value: 0)
writer.finishWriting { done.signal() }
done.wait()
print(writer.status == .completed ? "wrote \(out.path)" : "failed: \(String(describing: writer.error))")
