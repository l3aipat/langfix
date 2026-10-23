import Foundation
import LangFixCore

/// Counts only, never the text, so the menu can show how often LangFix helped and misfired.
struct Stats: Codable, Equatable {
    var fixed = 0
    var undone = 0
    var converted = 0
    var since = Date()
}

/// Everything the user can change, saved on every edit. The keyboard monitor and the Settings
/// window share this one object, so neither keeps its own copy.
final class Preferences: ObservableObject {
    private enum Key {
        static let minimumLength = "minimumLength"
        static let ignored = "ignoredWords"
        static let excluded = "excludedApps"
        static let stats = "stats"
        static let rememberLayouts = "rememberLayoutPerApp"
        static let appLayouts = "appLayouts"
    }

    private let defaults: UserDefaults

    @Published var minimumLength: Int {
        didSet { defaults.set(minimumLength, forKey: Key.minimumLength) }
    }
    @Published var ignored: Set<IgnoredWord> {
        didSet { defaults.set(try? JSONEncoder().encode(ignored), forKey: Key.ignored) }
    }
    /// Bundle IDs where typing is left alone, such as terminals where commands are not words.
    @Published var excludedApps: Set<String> {
        didSet { defaults.set(excludedApps.sorted(), forKey: Key.excluded) }
    }

    @Published var stats: Stats {
        didSet { defaults.set(try? JSONEncoder().encode(stats), forKey: Key.stats) }
    }

    /// Switch to the layout each app last used whenever the user comes back to it.
    @Published var rememberLayoutPerApp: Bool {
        didSet { defaults.set(rememberLayoutPerApp, forKey: Key.rememberLayouts) }
    }
    @Published var appLayouts: [String: Language] {
        didSet { defaults.set(try? JSONEncoder().encode(appLayouts), forKey: Key.appLayouts) }
    }

    var rules: Rules { Rules(minimumLength: minimumLength, ignored: ignored) }

    init(defaults: UserDefaults = .standard) {
        defaults.register(defaults: [
            Key.minimumLength: Rules().minimumLength,
            Key.excluded: ["com.apple.Terminal", "com.googlecode.iterm2"],
            Key.rememberLayouts: true,
        ])
        self.defaults = defaults
        let length = defaults.integer(forKey: Key.minimumLength)
        minimumLength = min(max(length, Rules.lengthRange.lowerBound), Rules.lengthRange.upperBound)
        ignored = defaults.data(forKey: Key.ignored)
            .flatMap { try? JSONDecoder().decode(Set<IgnoredWord>.self, from: $0) } ?? []
        excludedApps = Set(defaults.stringArray(forKey: Key.excluded) ?? [])
        stats = defaults.data(forKey: Key.stats).flatMap { try? JSONDecoder().decode(Stats.self, from: $0) } ?? Stats()
        rememberLayoutPerApp = defaults.bool(forKey: Key.rememberLayouts)
        appLayouts = defaults.data(forKey: Key.appLayouts)
            .flatMap { try? JSONDecoder().decode([String: Language].self, from: $0) } ?? [:]
    }
}
