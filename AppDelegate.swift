import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var statusMenuItem: NSMenuItem!
    private var settingsWindowController: SettingsWindowController?
    private let pipeline = DictationPipeline()

    func applicationDidFinishLaunching(_ notification: Notification) {
        installMainMenu()

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "🗣️"
        statusItem = item

        let menu = NSMenu()
        statusMenuItem = NSMenuItem(title: "Dictate (⌘⇧D)", action: #selector(toggleDictation), keyEquivalent: "")
        statusMenuItem.target = self
        menu.addItem(statusMenuItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        item.menu = menu

        pipeline.onStateChange = { [weak self] state in
            self?.updateUI(for: state)
        }
        updateUI(for: pipeline.state)

        HotkeyManager.shared.onHotkey = { [weak self] in
            self?.toggleDictation()
        }
        HotkeyManager.shared.install()
    }

    /// Menu-bar apps created programmatically have no main menu, which breaks
    /// Cmd+C/Cmd+V/etc. in text fields (key equivalents are routed via menus).
    /// An Edit menu with the standard actions restores copy/paste.
    private func installMainMenu() {
        let mainMenu = NSMenu()

        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        let editMenuItem = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        NSApp.mainMenu = mainMenu
    }

    private func updateUI(for state: DictationState) {
        switch state {
        case .idle:
            statusItem.button?.title = "🗣️"
            statusMenuItem.title = "Dictate (⌘⇧D)"
        case .recording:
            statusItem.button?.title = "🔴"
            statusMenuItem.title = "Stop (⌘⇧D)"
        case .processing:
            statusItem.button?.title = "⏳"
            statusMenuItem.title = "Transcribing…"
        }
    }

    @objc private func toggleDictation() {
        pipeline.toggle()
    }

    @objc private func openSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
