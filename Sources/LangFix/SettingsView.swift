import AppKit
import LangFixCore
import SwiftUI

struct SettingsView: View {
    @ObservedObject var preferences: Preferences

    var body: some View {
        Form {
            Section("Correction") {
                Stepper(value: $preferences.minimumLength, in: Rules.lengthRange) {
                    Text("Check a word after \(preferences.minimumLength) letters")
                }
                Text("Fewer letters fixes short words sooner but changes more words by mistake. 3 is recommended.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Since \(preferences.stats.since.formatted(date: .abbreviated, time: .omitted))") {
                let stats = preferences.stats
                LabeledContent("Words fixed while typing", value: "\(stats.fixed)")
                LabeledContent("Undone with Delete", value: stats.fixed == 0 ? "0" :
                    "\(stats.undone) (\((Double(stats.undone) / Double(stats.fixed)).formatted(.percent.precision(.fractionLength(0)))))")
                LabeledContent("Selections converted", value: "\(stats.converted)")
                Button("Reset Counts") { preferences.stats = Stats() }
            }

            Section("Undone words") {
                if preferences.ignored.isEmpty {
                    Text("None yet. Press Delete right after LangFix changes a word, and it leaves that word alone from then on.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                ForEach(preferences.ignored.sorted { $0.text < $1.text }, id: \.self) { word in
                    HStack {
                        Text(word.text).font(.body.monospaced())
                        Text("not changed to \(Keyboard.convert(word.text)?.text ?? "")")
                            .foregroundStyle(.secondary)
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

    private func appName(_ bundleID: String) -> String {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { return bundleID }
        return FileManager.default.displayName(atPath: url.path).replacingOccurrences(of: ".app", with: "")
    }
}
