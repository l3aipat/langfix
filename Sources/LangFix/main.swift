import AppKit
import ApplicationServices
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let monitor = KeyboardMonitor()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let toggleItem = NSMenuItem(title: "Auto-correct layout", action: #selector(toggle), keyEquivalent: "")
    private let excludeItem = NSMenuItem(title: "", action: #selector(toggleExcluded), keyEquivalent: "")
    private let loginItem = NSMenuItem(title: "Open at Login", action: #selector(toggleLogin), keyEquivalent: "")
    private let forgetItem = NSMenuItem(title: "", action: #selector(forgetIgnored), keyEquivalent: "")
    private let permissionItem = NSMenuItem(
        title: "Turn on LangFix in Accessibility settings…", action: #selector(openAccessibilitySettings), keyEquivalent: "")

    func applicationDidFinishLaunching(_ notification: Notification) {
        let menu = NSMenu()
        permissionItem.target = self
        permissionItem.isHidden = true
        menu.addItem(permissionItem)
        toggleItem.target = self
        toggleItem.state = .on
        menu.addItem(toggleItem)
        excludeItem.target = self
        menu.addItem(excludeItem)
        loginItem.target = self
        menu.addItem(loginItem)
        forgetItem.target = self
        menu.addItem(forgetItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit LangFix", action: #selector(NSApp.terminate), keyEquivalent: "q"))
        menu.delegate = self
        statusItem.menu = menu
        registerLoginItemOnFirstLaunch()

        guard InputSources.bothInstalled() else {
            setStatus("ก/a ⚠︎", tooltip: "Add both a Thai and an English keyboard in System Settings › Keyboard.")
            return
        }
        startWhenTrusted(prompt: true)
    }

    /// The tap can only be created once the user grants Accessibility, which happens outside the app.
    private func startWhenTrusted(prompt: Bool) {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
        if AXIsProcessTrustedWithOptions(options), monitor.start() {
            permissionItem.isHidden = true
            setStatus("ก/a", tooltip: "LangFix is fixing wrong-layout typing")
            return
        }
        // After an update the old switch can still look on, so say how to reset it.
        permissionItem.isHidden = false
        setStatus("ก/a ⚠︎", tooltip: """
            LangFix needs Accessibility permission. If LangFix is already switched on there, \
            remove it with − and add it again.
            """)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.startWhenTrusted(prompt: false) }
    }

    private func setStatus(_ title: String, tooltip: String) {
        statusItem.button?.title = title
        statusItem.button?.toolTip = tooltip
    }

    /// A layout fixer that is not running is useless, so start at login unless the user turns it off.
    private func registerLoginItemOnFirstLaunch() {
        let key = "didRegisterLoginItem"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        try? SMAppService.mainApp.register()
        UserDefaults.standard.set(true, forKey: key)
    }

    @objc private func toggleLogin() {
        let service = SMAppService.mainApp
        try? service.status == .enabled ? service.unregister() : service.register()
    }

    /// LangFix never activates itself, so the frontmost app is still the one the user was typing in.
    @objc private func toggleExcluded() {
        guard let id = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else { return }
        monitor.setExcluded(id, !monitor.excludedApps.contains(id))
    }

    @objc private func forgetIgnored() {
        monitor.forgetIgnored()
    }

    @objc private func openAccessibilitySettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }

    @objc private func toggle() {
        monitor.enabled.toggle()
        toggleItem.state = monitor.enabled ? .on : .off
    }
}

extension AppDelegate: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        let front = NSWorkspace.shared.frontmostApplication
        excludeItem.title = "Off in \(front?.localizedName ?? "this app")"
        excludeItem.state = monitor.excludedApps.contains(front?.bundleIdentifier ?? "") ? .on : .off
        excludeItem.isHidden = front?.bundleIdentifier == nil
        let count = monitor.ignoredCount
        forgetItem.title = "Forget \(count) undone word\(count == 1 ? "" : "s")"
        forgetItem.isHidden = count == 0
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
