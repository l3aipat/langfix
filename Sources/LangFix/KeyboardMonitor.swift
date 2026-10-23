import AppKit
import Carbon
import LangFixCore

/// Owns the event tap. Every keystroke reaches the corrector here, on the main run loop.
final class KeyboardMonitor {
    /// Tags events we post so the tap lets them through untouched.
    private static let marker: Int64 = 0x4C46_4958
    private static let deleteKeyCode: Int64 = 51

    private static let ignoredKey = "ignoredWords"

    var enabled = true
    private var corrector = Corrector(lexicon: SpellLexicon(), ignored: KeyboardMonitor.loadIgnored())
    private var tap: CFMachPort?
    private let source = CGEventSource(stateID: .privateState)
    /// The layout LangFix last selected, so its own switch is not mistaken for the user's.
    private var selectedByUs: Language?

    init() {
        source?.userData = Self.marker
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
        ) { [weak self] _ in self?.corrector.boundary() }
        // A user switching layout means they are starting over, often mid-line with no space typed.
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
            object: nil, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            if InputSources.current() != selectedByUs { corrector.boundary() }
            selectedByUs = nil
        }
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
        guard enabled, event.getIntegerValueField(.eventSourceUserData) != Self.marker else { return pass }

        if event.getIntegerValueField(.keyboardEventKeycode) == Self.deleteKeyCode {
            guard let undo = corrector.backspace() else { return pass }
            apply(undo)
            saveIgnored()
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
        guard let correction = corrector.type(character, in: InputSources.current()) else { return pass }
        apply(correction)
        return nil
    }

    var ignoredCount: Int { corrector.ignored.count }

    func forgetIgnored() {
        corrector.forgetIgnored()
        saveIgnored()
    }

    private static func loadIgnored() -> Set<IgnoredWord> {
        guard let data = UserDefaults.standard.data(forKey: ignoredKey) else { return [] }
        return (try? JSONDecoder().decode(Set<IgnoredWord>.self, from: data)) ?? []
    }

    private func saveIgnored() {
        UserDefaults.standard.set(try? JSONEncoder().encode(corrector.ignored), forKey: Self.ignoredKey)
    }

    private func apply(_ correction: Correction) {
        selectedByUs = correction.switchTo
        InputSources.select(correction.switchTo)
        for _ in 0..<correction.deleteCount {
            post(keyCode: CGKeyCode(Self.deleteKeyCode), text: nil)
        }
        post(keyCode: 0, text: correction.insert)
    }

    private func post(keyCode: CGKeyCode, text: String?) {
        for down in [true, false] {
            guard let event = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: down) else { continue }
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
