import Foundation

/// Manages the "Launch at login" LaunchAgent in ~/Library/LaunchAgents.
/// Uses the app's own executable path so the toggle works no matter where
/// the app is installed (build/ or /Applications).
enum LoginItemManager {
    static let label = "com.dictate"

    private static var launchAgentURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(label).plist")
    }

    static var isEnabled: Bool {
        FileManager.default.fileExists(atPath: launchAgentURL.path)
    }

    static func setEnabled(_ enabled: Bool) {
        if enabled {
            install()
        } else {
            uninstall()
        }
    }

    private static func install() {
        let plist: [String: Any] = [
            "Label": label,
            "ProgramArguments": [Bundle.main.executableURL?.path ?? "/Applications/Dictate.app/Contents/MacOS/Dictate"],
            "RunAtLoad": true,
            "KeepAlive": false,
            "ProcessType": "Interactive"
        ]
        let dir = launchAgentURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        if let data = try? PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0) {
            try? data.write(to: launchAgentURL, options: .atomic)
        }
        // Load it now so the change applies without a reboot.
        unloadCurrent()
        if !runLaunchCtl(["bootstrap", "gui/\(getuid())", launchAgentURL.path]) {
            _ = runLaunchCtl(["load", "-w", launchAgentURL.path])
        }
    }

    private static func uninstall() {
        unloadCurrent()
        try? FileManager.default.removeItem(at: launchAgentURL)
    }

    private static func unloadCurrent() {
        if !runLaunchCtl(["bootout", "gui/\(getuid())/\(label)"]) {
            _ = runLaunchCtl(["unload", launchAgentURL.path])
        }
    }

    @discardableResult
    private static func runLaunchCtl(_ args: [String]) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = args
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
}
