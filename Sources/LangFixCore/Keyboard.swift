/// Raw values are the language codes macOS uses for input sources and spell checking.
public enum Language: String, CaseIterable, Codable, Sendable {
    case english = "en", thai = "th"

    public var other: Language { self == .english ? .thai : .english }
}

/// A physical key plus shift state, independent of which layout is active.
public struct KeyPosition: Hashable, Sendable {
    let index: Int
}

/// US QWERTY and Thai Kedmanee, aligned so the same index is the same physical key.
public enum Keyboard {
    static let qwerty = Array((
        "1234567890-=qwertyuiop[]\\asdfghjkl;'zxcvbnm,./"
            + "!@#$%^&*()_+QWERTYUIOP{}|ASDFGHJKL:\"ZXCVBNM<>?").unicodeScalars)
    static let kedmanee = Array((
        "ๅ/_ภถุึคตจขชๆไำพะัีรนยบลฃฟหกดเ้่าสวงผปแอิืทมใฝ"
            + "+๑๒๓๔ู฿๕๖๗๘๙๐\"ฎฑธํ๊ณฯญฐ,ฅฤฆฏโฌ็๋ษศซ.()ฉฮฺ์?ฒฬฦ").unicodeScalars)

    /// ANSI virtual key codes in the same physical order as each layout's unshifted half.
    public static let keyCodes: [UInt16] = [
        18, 19, 20, 21, 23, 22, 26, 28, 25, 29, 27, 24,
        12, 13, 14, 15, 17, 16, 32, 34, 31, 35, 33, 30, 42,
        0, 1, 2, 3, 5, 4, 38, 40, 37, 41, 39,
        6, 7, 8, 9, 11, 45, 46, 43, 47, 44,
    ]

    public static func keyStroke(at position: KeyPosition) -> (keyCode: UInt16, shift: Bool) {
        (keyCodes[position.index % keyCodes.count], position.index >= keyCodes.count)
    }

    static func characters(_ language: Language) -> [Unicode.Scalar] {
        language == .english ? qwerty : kedmanee
    }

    private static let lookup: [Language: [Unicode.Scalar: KeyPosition]] = {
        precondition(qwerty.count == kedmanee.count, "layouts must cover the same keys")
        var result: [Language: [Unicode.Scalar: KeyPosition]] = [:]
        for language in Language.allCases {
            for (index, character) in characters(language).enumerated() {
                result[language, default: [:]][character] = KeyPosition(index: index)
            }
        }
        return result
    }()

    public static var keyCount: Int { qwerty.count }

    public static func position(of character: Unicode.Scalar, in language: Language) -> KeyPosition? {
        lookup[language]?[character]
    }

    public static func character(at position: KeyPosition, in language: Language) -> Unicode.Scalar {
        characters(language)[position.index]
    }

    /// Retypes a whole run of text on the other layout. The direction follows whichever script
    /// dominates, and characters that no key produces (spaces, newlines) are kept as they are.
    public static func convert(_ text: String) -> (text: String, language: Language)? {
        let thai = text.unicodeScalars.filter { (0x0E00...0x0E7F).contains($0.value) }.count
        let latin = text.unicodeScalars.filter { $0.properties.isAlphabetic && $0.isASCII }.count
        guard thai + latin > 0 else { return nil }
        let from: Language = thai > latin ? .thai : .english
        var converted = ""
        for scalar in text.unicodeScalars {
            converted.unicodeScalars.append(position(of: scalar, in: from).map { character(at: $0, in: from.other) } ?? scalar)
        }
        return (converted, from.other)
    }

    public static func text(_ keys: [KeyPosition], in language: Language) -> String {
        var text = ""
        text.unicodeScalars.append(contentsOf: keys.map { character(at: $0, in: language) })
        return text
    }
}
