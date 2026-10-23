import AppKit
import LangFixCore

/// Uses the dictionaries macOS already ships, so the app carries no word lists.
struct SpellLexicon: Lexicon {
    func isPrefix(_ text: String, in language: Language) -> Bool {
        if language == .english, !hasPlausibleCasing(text) { return false }
        let checker = NSSpellChecker.shared
        let range = NSRange(location: 0, length: (text as NSString).length)
        // Compare scalars: a Thai tone mark fuses with the consonant before it into one Character,
        // so String.hasPrefix says "ทำร้าย" does not start with "ทำร".
        let typed = text.lowercased().unicodeScalars
        if let completions = checker.completions(forPartialWordRange: range, in: text, language: language.rawValue,
                                                 inSpellDocumentWithTag: 0),
           completions.contains(where: { $0.lowercased().unicodeScalars.starts(with: typed) }) {
            return true
        }
        // Complete words with no longer completions need the spell check, but macOS has no Thai
        // spelling dictionary and skips digits and punctuation, so it accepts garbage there.
        guard language == .english, text.unicodeScalars.allSatisfy(CharacterSet.letters.contains) else {
            return false
        }
        let misspelled = checker.checkSpelling(of: text, startingAt: 0, language: language.rawValue, wrap: false,
                                               inSpellDocumentWithTag: 0, wordCount: nil)
        return misspelled.location == NSNotFound
    }

    /// "hello", "Hello" and "HELLO" are typed on purpose. "hEllo" is a Thai word with Shift held.
    private func hasPlausibleCasing(_ text: String) -> Bool {
        let rest = text.dropFirst()
        return text == text.lowercased() || text == text.uppercased() || rest == rest.lowercased()
    }
}
