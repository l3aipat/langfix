import AppKit
import LangFixCore

/// A small "ก" or "A" that flashes beside the text cursor when the layout changes.
final class LayoutBadge {
    private static let size: CGFloat = 30

    private let panel: NSPanel
    private let label = NSTextField(labelWithString: "")
    private var hideWork: DispatchWorkItem?

    init() {
        panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: Self.size, height: Self.size),
                        styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .statusBar
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .transient]

        let background = NSView(frame: panel.contentLayoutRect)
        background.wantsLayer = true
        background.layer?.cornerRadius = 7
        background.layer?.backgroundColor = NSColor(white: 0.1, alpha: 0.85).cgColor
        label.font = .systemFont(ofSize: 17, weight: .bold)
        label.textColor = .white
        label.alignment = .center
        label.frame = background.bounds.insetBy(dx: 0, dy: 4)
        background.addSubview(label)
        panel.contentView = background
    }

    func show(_ language: Language) {
        label.stringValue = language == .thai ? "ก" : "A"
        let anchor = Self.caretRect() ?? NSRect(origin: NSEvent.mouseLocation, size: .zero).offsetBy(dx: 12, dy: -12)
        panel.setFrameOrigin(NSPoint(x: anchor.maxX + 4, y: anchor.minY - Self.size - 2))
        panel.alphaValue = 1
        panel.orderFrontRegardless()

        hideWork?.cancel()
        let work = DispatchWorkItem { [panel] in
            NSAnimationContext.runAnimationGroup({ $0.duration = 0.25; panel.animator().alphaValue = 0 },
                                                 completionHandler: { panel.orderOut(nil) })
        }
        hideWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: work)
    }

    /// The caret in Cocoa screen coordinates. Chrome and Electron apps do not expose it, so callers
    /// fall back to the mouse pointer.
    private static func caretRect() -> NSRect? {
        let system = AXUIElementCreateSystemWide()
        AXUIElementSetMessagingTimeout(system, 0.1)
        var focused: AnyObject?
        var range: AnyObject?
        var bounds: AnyObject?
        guard AXUIElementCopyAttributeValue(system, kAXFocusedUIElementAttribute as CFString, &focused) == .success,
              let element = focused, CFGetTypeID(element) == AXUIElementGetTypeID(),
              AXUIElementCopyAttributeValue(element as! AXUIElement, kAXSelectedTextRangeAttribute as CFString, &range) == .success,
              let range,
              AXUIElementCopyParameterizedAttributeValue(element as! AXUIElement, kAXBoundsForRangeParameterizedAttribute as CFString,
                                                         range, &bounds) == .success,
              let bounds, CFGetTypeID(bounds) == AXValueGetTypeID()
        else { return nil }
        var rect = CGRect.zero
        guard AXValueGetValue(bounds as! AXValue, .cgRect, &rect), rect.height > 0,
              let screenHeight = NSScreen.screens.first?.frame.height
        else { return nil }
        // Accessibility measures from the top of the main screen, AppKit from the bottom.
        return NSRect(x: rect.minX, y: screenHeight - rect.maxY, width: rect.width, height: rect.height)
    }
}
