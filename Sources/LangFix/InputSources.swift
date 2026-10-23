import Carbon
import LangFixCore

enum InputSources {
    static func current() -> Language {
        let source = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
        return languages(of: source).first == Language.thai.rawValue ? .thai : .english
    }

    static func select(_ language: Language) {
        let filter = [
            kTISPropertyInputSourceCategory as String: kTISCategoryKeyboardInputSource as String,
            kTISPropertyInputSourceIsSelectCapable as String: true,
        ] as CFDictionary
        guard let sources = TISCreateInputSourceList(filter, false)?.takeRetainedValue() as? [TISInputSource],
              let match = sources.first(where: { languages(of: $0).first == language.rawValue })
        else { return }
        TISSelectInputSource(match)
    }

    /// Missing either layout makes correction pointless, so the app checks this at launch.
    static func bothInstalled() -> Bool {
        let filter = [kTISPropertyInputSourceIsSelectCapable as String: true] as CFDictionary
        let sources = TISCreateInputSourceList(filter, false)?.takeRetainedValue() as? [TISInputSource] ?? []
        let firsts = Set(sources.compactMap { languages(of: $0).first })
        return Language.allCases.allSatisfy { firsts.contains($0.rawValue) }
    }

    private static func languages(of source: TISInputSource) -> [String] {
        guard let raw = TISGetInputSourceProperty(source, kTISPropertyInputSourceLanguages) else { return [] }
        return Unmanaged<CFArray>.fromOpaque(raw).takeUnretainedValue() as? [String] ?? []
    }
}
