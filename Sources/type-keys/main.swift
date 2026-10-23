import AppKit
import Carbon
import LangFixCore

// Presses physical keys as a person would, so the system layout decides what each key produces.
// Stops before any key if `app` is not frontmost, so a test never types into someone's chat.
// usage: type-keys <app> <keys as on a US keyboard> <milliseconds between keys>
// ⌫ is Delete, ⇄ is Option-Shift-Space, Ⓐ is Command-A.
// TYPE_KEYS_LAYOUT picks the layout active before the first key (default ABC).
let arguments = CommandLine.arguments
guard arguments.count == 4, let gap = UInt32(arguments[3]) else {
    print("usage: type-keys <app> <keys> <ms-between-keys>")
    exit(64)
}
let app = arguments[1]

func requireFrontmost() {
    let front = NSWorkspace.shared.frontmostApplication?.localizedName ?? "nothing"
    guard front == app else {
        print("stopped: \(front) is frontmost, not \(app)")
        exit(3)
    }
}
guard AXIsProcessTrusted() else {
    print("not trusted: enable Accessibility for the app that runs this terminal")
    exit(2)
}

let layout = ProcessInfo.processInfo.environment["TYPE_KEYS_LAYOUT"] ?? "ABC"
let filter = [kTISPropertyInputSourceID as String: "com.apple.keylayout.\(layout)"] as CFDictionary
guard let start = (TISCreateInputSourceList(filter, false)?.takeRetainedValue() as? [TISInputSource])?.first else {
    print("no input source com.apple.keylayout.\(layout)")
    exit(66)
}
TISSelectInputSource(start)
usleep(300_000)

for scalar in arguments[2].unicodeScalars {
    requireFrontmost()
    if let (keyCode, flags): (UInt16, CGEventFlags) = [
        "⇄": (49, [.maskAlternate, .maskShift]), "Ⓐ": (0, .maskCommand),
    ][scalar] {
        for down in [true, false] {
            let event = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: down)!
            event.flags = flags
            event.post(tap: .cghidEventTap)
        }
        usleep(gap * 1000)
        continue
    }
    let stroke: (keyCode: UInt16, shift: Bool)
    if scalar == " " {
        stroke = (49, false)
    } else if scalar == "⌫" {
        stroke = (51, false)
    } else if let position = Keyboard.position(of: scalar, in: .english) {
        stroke = Keyboard.keyStroke(at: position)
    } else {
        print("no key for \(scalar)")
        exit(65)
    }
    let source = CGEventSource(stateID: .hidSystemState)
    let shiftKeyCode: UInt16 = 56
    var keys = [(stroke.keyCode, true), (stroke.keyCode, false)]
    if stroke.shift { keys = [(shiftKeyCode, true)] + keys + [(shiftKeyCode, false)] }
    for (keyCode, down) in keys {
        let event = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: down)!
        if keyCode == shiftKeyCode { event.type = .flagsChanged }
        event.flags = stroke.shift && (keyCode != shiftKeyCode || down) ? .maskShift : []
        event.post(tap: .cghidEventTap)
        usleep(5_000)
    }
    usleep(gap * 1000)
}
usleep(500_000)
