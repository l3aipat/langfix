import AppKit
import Carbon
import LangFixCore

/// Owns the event tap. Every keystroke reaches the corrector here, on the main run loop.
final class KeyboardMonitor {
    /// Tags events we post so the tap lets them through untouched.
    private static let marker: Int64 = 0x4C46_4958
    private static let deleteKeyCode: Int64 = 51
    private static let spaceKeyCode: Int64 = 49
    private static let copyKeyCode: CGKeyCode = 8
    private static let pasteKeyCode: CGKeyCode = 9

    var enabled = true
    private let preferences: Preferences
    private var corrector = Corrector(lexicon: SpellLexicon())
    private var tap: CFMachPort?
    private let source = CGEventSource(stateID: .privateState)
    /// The layout LangFix last selected, so its own switch is not mistaken for the user's.
    private var selectedByUs: Language?
    private var frontmostApp = NSWorkspace.shared.frontmostApplication?.bundleIdentifier

    init(preferences: Preferences) {
        self.preferences = preferences
        source?.userData = Self.marker
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
        ) { [weak self] notification in
            let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            self?.frontmostApp = app?.bundleIdentifier
            self?.corrector.boundary()
            self?.restoreLayout()
        }
        // A user switching layout means they are starting over, often mid-line with no space typed.
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
            object: nil, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            let current = InputSources.current()
            if current != selectedByUs { corrector.boundary() }
            selectedByUs = nil
            if let app = frontmostApp, app != Bundle.main.bundleIdentifier { preferences.appLayouts[app] = current }
        }
    }

    private func restoreLayout() {
        guard enabled, preferences.rememberLayoutPerApp, let app = frontmostApp,
              let layout = preferences.appLayouts[app], layout != InputSources.current()
        else { return }
        selectedByUs = layout
        InputSources.select(layout)
    }

    func start() -> Bool {
        let types: [CGEventType] = [.keyDown, .leftMouseDown, .rightMouseDown, .otherMouseDown]
        let mask = types.reduce(CGEventMask(0)) { $0 | (1 << $1.rawValue) }
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
            eventsOfInterest: mask,
            callback: { _, type, event, context in
                let monitor = Unmanaged<KeyboardMonitor>.fromOpaque(context!).takeUnretainedValue()
                return monitor.handle(type, event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque())
        else { return false }
        self.tap = tap
        CFRunLoopAddSource(CFRunLoopGetMain(), CFMachPortCreateRunLoopSource(nil, tap, 0), .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    private func handle(_ type: CGEventType, _ event: CGEvent) -> Unmanaged<CGEvent>? {
        let pass = Unmanaged.passUnretained(event)
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return pass
        case .keyDown:
            break
        default:
            corrector.boundary()
            return pass
        }
        guard enabled, event.getIntegerValueField(.eventSourceUserData) != Self.marker,
              !preferences.excludedApps.contains(frontmostApp ?? "")
        else { return pass }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let modifiers = event.flags.intersection([.maskCommand, .maskControl, .maskAlternate, .maskShift])
        if keyCode == Self.spaceKeyCode, modifiers == [.maskAlternate, .maskShift] {
            corrector.boundary()
            DispatchQueue.main.async { self.convertSelection() }
            return nil
        }
        if keyCode == Self.deleteKeyCode {
            guard let undo = corrector.backspace() else { return pass }
            apply(undo.correction)
            preferences.ignored.insert(undo.learned)
            preferences.stats.undone += 1
            return nil
        }
        if keyCode == Self.spaceKeyCode, modifiers.isEmpty {
            guard let correction = corrector.endWord(in: InputSources.current(), rules: preferences.rules) else { return pass }
            apply(correction)
            preferences.stats.fixed += 1
            return nil
        }
        let scalars = event.unicodeString.unicodeScalars
        guard event.flags.isDisjoint(with: [.maskCommand, .maskControl, .maskAlternate]),
              scalars.count == 1, let character = scalars.first,
              !character.properties.isWhitespace, character.value >= 0x20
        else {
            corrector.boundary()
            return pass
        }
        guard let correction = corrector.type(character, in: InputSources.current(), rules: preferences.rules) else { return pass }
        apply(correction)
        preferences.stats.fixed += 1
        return nil
    }

    /// Copies the selection, retypes it on the other layout and pastes it back. Reading the
    /// selection through Accessibility fails in Chrome and Electron apps, the clipboard works everywhere.
    func convertSelection() {
        let pasteboard = NSPasteboard.general
        let saved = pasteboard.pasteboardItems?.map { item in
            item.types.compactMap { type in item.data(forType: type).map { (type, $0) } }
        } ?? []
        let before = pasteboard.changeCount
        post(keyCode: Self.copyKeyCode, flags: .maskCommand)
        waitForCopy(since: before, attempts: 25) { copied in
            guard copied, let text = pasteboard.string(forType: .string),
                  let (converted, language) = Keyboard.convert(text)
            else {
                NSSound.beep()
                return
            }
            pasteboard.clearContents()
            pasteboard.setString(converted, forType: .string)
            self.post(keyCode: Self.pasteKeyCode, flags: .maskCommand)
            self.preferences.stats.converted += 1
            self.selectedByUs = language
            InputSources.select(language)
            // The paste reads the clipboard asynchronously, so restore only after it has landed.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                pasteboard.clearContents()
                pasteboard.writeObjects(saved.map { pairs in
                    let item = NSPasteboardItem()
                    for (type, data) in pairs { item.setData(data, forType: type) }
                    return item
                })
            }
        }
    }

    private func waitForCopy(since changeCount: Int, attempts: Int, then finish: @escaping (Bool) -> Void) {
        if NSPasteboard.general.changeCount != changeCount { return finish(true) }
        guard attempts > 0 else { return finish(false) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            self.waitForCopy(since: changeCount, attempts: attempts - 1, then: finish)
        }
    }

    private func apply(_ correction: Correction) {
        selectedByUs = correction.switchTo
        InputSources.select(correction.switchTo)
        for _ in 0..<correction.deleteCount {
            post(keyCode: CGKeyCode(Self.deleteKeyCode))
        }
        post(keyCode: 0, text: correction.insert)
    }

    private func post(keyCode: CGKeyCode, text: String? = nil, flags: CGEventFlags = []) {
        for down in [true, false] {
            guard let event = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: down) else { continue }
            event.flags = flags
            if let text {
                let units = Array(text.utf16)
                event.keyboardSetUnicodeString(stringLength: units.count, unicodeString: units)
            }
            event.post(tap: .cgSessionEventTap)
        }
    }
}

private extension CGEvent {
    var unicodeString: String {
        var length = 0
        var units = [UniChar](repeating: 0, count: 8)
        keyboardGetUnicodeString(maxStringLength: units.count, actualStringLength: &length, unicodeString: &units)
        return String(utf16CodeUnits: units, count: length)
    }
}
