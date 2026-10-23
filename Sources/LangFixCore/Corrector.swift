public protocol Lexicon {
    /// True when `text` is a word, or the start of one, in `language`.
    func isPrefix(_ text: String, in language: Language) -> Bool
}

public struct Correction: Equatable, Sendable {
    /// Characters already on screen that must be erased. The triggering key is never delivered.
    public let deleteCount: Int
    public let insert: String
    public let switchTo: Language
}

/// Text the user undid a correction on. Anything typed in `language` that starts with it is left alone.
public struct IgnoredWord: Hashable, Codable, Sendable {
    public let text: String
    public let language: Language

    public init(text: String, language: Language) {
        self.text = text
        self.language = language
    }
}

/// Watches one word at a time and decides whether it was typed in the wrong layout.
public struct Corrector {
    enum WordState: Equatable {
        case watching([KeyPosition])
        /// Just corrected. A backspace now reverts it; any other key settles the word.
        case corrected(undo: Correction, learn: IgnoredWord)
        /// Already corrected, or judged as text we must not touch, until the next boundary.
        case settled
    }

    public static let minimumLength = 3
    public static let maximumLength = 12

    let lexicon: Lexicon
    var state = WordState.watching([])
    public private(set) var ignored: Set<IgnoredWord>

    public init(lexicon: Lexicon, ignored: Set<IgnoredWord> = []) {
        self.lexicon = lexicon
        self.ignored = ignored
    }

    /// Anything that ends a word: space, return, arrows, a click, an app switch.
    public mutating func boundary() {
        state = .watching([])
    }

    public mutating func forgetIgnored() {
        ignored = []
    }

    /// Returns an undo when the backspace lands right after a correction. The caller swallows
    /// that backspace and applies the undo instead.
    public mutating func backspace() -> Correction? {
        switch state {
        case .corrected(let undo, let learn):
            ignored.insert(learn)
            state = .settled
            return undo
        case .watching(var keys):
            state = keys.popLast() == nil ? .settled : .watching(keys)
            return nil
        case .settled:
            return nil
        }
    }

    /// Feed one typed character produced under `language`. Returns a correction when the word
    /// so far reads as garbage in `language` but as a real prefix in the other layout.
    public mutating func type(_ character: Unicode.Scalar, in language: Language) -> Correction? {
        guard case .watching(var keys) = state else {
            state = .settled
            return nil
        }
        guard let key = Keyboard.position(of: character, in: language) else {
            state = .settled
            return nil
        }
        keys.append(key)
        state = .watching(keys)
        guard keys.count >= Self.minimumLength else { return nil }

        let typed = Keyboard.text(keys, in: language)
        if isIgnored(typed, in: language) || lexicon.isPrefix(typed, in: language) {
            if keys.count >= Self.maximumLength { state = .settled }
            return nil
        }
        state = .settled
        let other = language.other
        let converted = Keyboard.text(keys, in: other)
        guard lexicon.isPrefix(converted, in: other) else { return nil }
        state = .corrected(
            undo: Correction(deleteCount: converted.unicodeScalars.count, insert: typed, switchTo: language),
            learn: IgnoredWord(text: typed, language: language))
        return Correction(deleteCount: keys.count - 1, insert: converted, switchTo: other)
    }

    private func isIgnored(_ text: String, in language: Language) -> Bool {
        ignored.contains { $0.language == language && text.unicodeScalars.starts(with: $0.text.unicodeScalars) }
    }
}
