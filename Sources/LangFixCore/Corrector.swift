public protocol Lexicon {
    /// True when `text` is a word, or the start of one, in `language`.
    func isPrefix(_ text: String, in language: Language) -> Bool
    /// True when `text` is a complete word in `language`.
    func isWord(_ text: String, in language: Language) -> Bool
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

/// The user's settings that shape each decision.
public struct Rules: Equatable, Sendable {
    public static let lengthRange = 2...6

    /// Keys typed before a word is judged. Lower catches short words sooner but misfires more.
    public var minimumLength: Int
    public var ignored: Set<IgnoredWord>

    public init(minimumLength: Int = 3, ignored: Set<IgnoredWord> = []) {
        self.minimumLength = minimumLength
        self.ignored = ignored
    }
}

extension Rules {
    func ignores(_ text: String, in language: Language) -> Bool {
        ignored.contains { $0.language == language && text.unicodeScalars.starts(with: $0.text.unicodeScalars) }
    }
}

public struct Undo: Equatable, Sendable {
    public let correction: Correction
    /// The caller adds this to `Rules.ignored` so the word is never corrected again.
    public let learned: IgnoredWord
}

/// Watches one word at a time and decides whether it was typed in the wrong layout.
public struct Corrector {
    enum WordState: Equatable {
        case watching([KeyPosition])
        /// Just corrected. A backspace now reverts it. Any other key settles the word, or starts
        /// the next one when the correction happened as the previous word ended.
        case corrected(Undo, atWordEnd: Bool)
        /// Already corrected, or judged as text we must not touch, until the next boundary.
        case settled
    }

    public static let maximumLength = 12

    let lexicon: Lexicon
    var state = WordState.watching([])

    public init(lexicon: Lexicon) {
        self.lexicon = lexicon
    }

    /// Anything that ends a word: space, return, arrows, a click, an app switch.
    public mutating func boundary() {
        state = .watching([])
    }

    /// Returns an undo when the backspace lands right after a correction. The caller swallows
    /// that backspace and applies the undo instead.
    public mutating func backspace() -> Undo? {
        switch state {
        case .corrected(let undo, _):
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
    public mutating func type(_ character: Unicode.Scalar, in language: Language, rules: Rules = Rules()) -> Correction? {
        if case .corrected(_, atWordEnd: true) = state { state = .watching([]) }
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
        guard keys.count >= rules.minimumLength else { return nil }

        let typed = Keyboard.text(keys, in: language)
        if rules.ignores(typed, in: language) || lexicon.isPrefix(typed, in: language) {
            if keys.count >= Self.maximumLength { state = .settled }
            return nil
        }
        state = .settled
        let other = language.other
        let converted = Keyboard.text(keys, in: other)
        guard lexicon.isPrefix(converted, in: other) else { return nil }
        state = .corrected(Undo(
            correction: Correction(deleteCount: converted.unicodeScalars.count, insert: typed, switchTo: language),
            learned: IgnoredWord(text: typed, language: language)), atWordEnd: false)
        return Correction(deleteCount: keys.count - 1, insert: converted, switchTo: other)
    }

    /// Feed the space that ends a word, before the app sees it. Catches whole words whose start
    /// read as the current language, such as "ot" for นะ, which `type` must leave alone. A returned
    /// correction already ends in the space, so the caller swallows the original one.
    public mutating func endWord(in language: Language, rules: Rules = Rules()) -> Correction? {
        guard case .watching(let keys) = state, keys.count >= 2 else {
            state = .watching([])
            return nil
        }
        state = .watching([])
        let typed = Keyboard.text(keys, in: language)
        let other = language.other
        let converted = Keyboard.text(keys, in: other)
        guard !rules.ignores(typed, in: language), !lexicon.isWord(typed, in: language),
              lexicon.isWord(converted, in: other)
        else { return nil }
        state = .corrected(Undo(
            correction: Correction(deleteCount: converted.unicodeScalars.count + 1, insert: typed + " ", switchTo: language),
            learned: IgnoredWord(text: typed, language: language)), atWordEnd: true)
        return Correction(deleteCount: keys.count, insert: converted + " ", switchTo: other)
    }
}
