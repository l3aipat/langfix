import AppKit
import LangFixCore
import SwiftUI

struct SettingsView: View {
    @ObservedObject var preferences: Preferences
    @State private var newWord = ""

    var body: some View {
        Form {
            Section("Correction") {
                Stepper(value: $preferences.minimumLength, in: Rules.lengthRange) {
                    Text("Check a word after \(preferences.minimumLength) letters")
                }
                Text("Fewer letters fixes short words sooner but changes more words by mistake. 3 is recommended.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Toggle("Switch to each app’s last layout", isOn: $preferences.rememberLayoutPerApp)
                Toggle("Show ก or A next to the cursor when the layout changes", isOn: $preferences.showLayoutBadge)
            }

            Section("Since \(preferences.stats.since.formatted(date: .abbreviated, time: .omitted))") {
                let stats = preferences.stats
                LabeledContent("Words fixed while typing", value: "\(stats.fixed)")
                LabeledContent("Undone with Delete", value: stats.fixed == 0 ? "0" :
                    "\(stats.undone) (\((Double(stats.undone) / Double(stats.fixed)).formatted(.percent.precision(.fractionLength(0)))))")
                LabeledContent("Selections converted", value: "\(stats.converted)")
                Button("Reset Counts") { preferences.stats = Stats() }
            }

            Section("Words LangFix leaves alone") {
                HStack {
                    TextField("Add a word, such as 555 or จุงเบย", text: $newWord)
                        .onSubmit(addWord)
                    Button("Add", action: addWord)
                        .disabled(newWord.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                Stepper(value: $preferences.undosToLearn, in: UndoTally.thresholdRange) {
                    Text("Add a word after undoing it \(preferences.undosToLearn) times")
                }
                Text("Pressing Delete right after LangFix changes a word undoes the change. Once you undo the same word this many times, it is added here.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(preferences.ignored.sorted { $0.text < $1.text }, id: \.self) { word in
                    HStack {
                        Text(word.text).font(.body.monospaced())
                        if let converted = Keyboard.convert(word.text)?.text {
                            Text("not changed to \(converted)").foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button { preferences.ignored.remove(word) } label: { Image(systemName: "minus.circle") }
                            .buttonStyle(.borderless)
                            .help("Let LangFix correct this word again")
                    }
                }
                if !preferences.ignored.isEmpty {
                    Button("Remove All", role: .destructive) { preferences.ignored.removeAll() }
                }
            }

            Section("Turned off in") {
                if preferences.excludedApps.isEmpty {
                    Text("LangFix works in every app.").font(.caption).foregroundStyle(.secondary)
                }
                ForEach(preferences.excludedApps.sorted(), id: \.self) { bundleID in
                    HStack {
                        Text(appName(bundleID))
                        Spacer()
                        Button { preferences.excludedApps.remove(bundleID) } label: { Image(systemName: "minus.circle") }
                            .buttonStyle(.borderless)
                            .help("Turn LangFix back on in this app")
                    }
                }
                Text("To add an app, open it, then choose “Off in …” from the LangFix menu.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 440, height: 520)
    }

    /// The word's own script says which layout it is typed on.
    private func addWord() {
        let text = newWord.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        let thai = text.unicodeScalars.contains { (0x0E00...0x0E7F).contains($0.value) }
        preferences.ignored.insert(IgnoredWord(text: text, language: thai ? .thai : .english))
        newWord = ""
    }

    private func appName(_ bundleID: String) -> String {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { return bundleID }
        return FileManager.default.displayName(atPath: url.path).replacingOccurrences(of: ".app", with: "")
    }
}
