import Foundation
import LangFixCore

/// Everything the user can change, saved on every edit. The keyboard monitor and the Settings
/// window share this one object, so neither keeps its own copy.
final class Preferences: ObservableObject {
    private enum Key {
        static let minimumLength = "minimumLength"
        static let ignored = "ignoredWords"
        static let excluded = "excludedApps"
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

    var rules: Rules { Rules(minimumLength: minimumLength, ignored: ignored) }

    init(defaults: UserDefaults = .standard) {
        defaults.register(defaults: [
            Key.minimumLength: Rules().minimumLength,
            Key.excluded: ["com.apple.Terminal", "com.googlecode.iterm2"],
        ])
        self.defaults = defaults
        let length = defaults.integer(forKey: Key.minimumLength)
        minimumLength = min(max(length, Rules.lengthRange.lowerBound), Rules.lengthRange.upperBound)
        ignored = defaults.data(forKey: Key.ignored)
            .flatMap { try? JSONDecoder().decode(Set<IgnoredWord>.self, from: $0) } ?? []
        excludedApps = Set(defaults.stringArray(forKey: Key.excluded) ?? [])
    }
}
