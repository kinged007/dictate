import Cocoa

/// Simple AppKit settings window (no SwiftUI scene APIs needed on 10.15).
final class SettingsWindowController: NSWindowController, NSTextFieldDelegate {
    private let transcriptionBaseURLField = NSTextField(string: Settings.transcriptionBaseURL)
    private let transcriptionKeyField = NSSecureTextField(string: Settings.transcriptionAPIKey ?? "")
    private let transcribeModelField = NSTextField(string: Settings.transcribeModel)

    private let cleanupBaseURLField = NSTextField(string: Settings.cleanupBaseURL)
    private let cleanupKeyField = NSSecureTextField(string: Settings.cleanupAPIKey ?? "")
    private let cleanupModelField = NSTextField(string: Settings.cleanupModel)
    private let promptField = NSTextField(string: Settings.cleanupPrompt)
    private let launchAtLoginCheckbox = NSButton(
        checkboxWithTitle: "Launch Dictate at login",
        target: nil,
        action: nil
    )

    private let statusLabel = NSTextField(labelWithString: "")

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 540, height: 520),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Dictate Settings"
        window.isReleasedWhenClosed = false
        self.init(window: window)

        let transcriptionGrid = NSGridView(views: [
            [label("Base URL"), transcriptionBaseURLField],
            [label("API key"), transcriptionKeyField],
            [label("Model"), transcribeModelField]
        ])
        transcriptionGrid.column(at: 0).xPlacement = .trailing
        transcriptionGrid.rowSpacing = 8
        transcriptionGrid.columnSpacing = 12
        transcriptionGrid.column(at: 1).width = 360

        let cleanupGrid = NSGridView(views: [
            [label("Base URL"), cleanupBaseURLField],
            [label("API key"), cleanupKeyField],
            [label("Model"), cleanupModelField]
        ])
        cleanupGrid.column(at: 0).xPlacement = .trailing
        cleanupGrid.rowSpacing = 8
        cleanupGrid.columnSpacing = 12
        cleanupGrid.column(at: 1).width = 360

        transcriptionBaseURLField.placeholderString = "https://api.groq.com/openai/v1"
        transcriptionKeyField.placeholderString = "gsk_…"
        transcribeModelField.placeholderString = "whisper-large-v3-turbo"
        cleanupBaseURLField.placeholderString = "https://api.groq.com/openai/v1"
        cleanupKeyField.placeholderString = "Groq API key"
        cleanupModelField.placeholderString = "openai/gpt-oss-120b"
        promptField.placeholderString = "Leave blank to use the built-in cleanup prompt"
        promptField.cell?.wraps = true

        launchAtLoginCheckbox.state = LoginItemManager.isEnabled ? .on : .off

        let transcribeSection = sectionLabel("Transcription (Groq)")
        let cleanupSection = sectionLabel("LLM cleanup (Groq)")
        let promptSection = sectionLabel("Cleanup prompt")

        let saveButton = NSButton(title: "Save", target: self, action: #selector(save))
        saveButton.keyEquivalent = "\r"
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.font = .systemFont(ofSize: 11)

        let stack = NSStackView(views: [
            transcribeSection, transcriptionGrid,
            cleanupSection, cleanupGrid,
            promptSection, promptField,
            launchAtLoginCheckbox,
            statusLabel, saveButton
        ])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.setCustomSpacing(4, after: transcribeSection)
        stack.setCustomSpacing(4, after: cleanupSection)
        stack.setCustomSpacing(4, after: promptSection)
        stack.setCustomSpacing(18, after: transcriptionGrid)
        stack.setCustomSpacing(18, after: cleanupGrid)
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        stack.translatesAutoresizingMaskIntoConstraints = false

        window.contentView = stack
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: window.contentView!.topAnchor),
            stack.leadingAnchor.constraint(equalTo: window.contentView!.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: window.contentView!.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: window.contentView!.bottomAnchor)
        ])
        window.center()
    }

    private func label(_ text: String) -> NSTextField {
        NSTextField(labelWithString: text)
    }

    private func sectionLabel(_ text: String) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.font = .boldSystemFont(ofSize: 13)
        return field
    }

    @objc private func save() {
        let transcribeBase = transcriptionBaseURLField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: transcribeBase), url.scheme != nil else {
            statusLabel.stringValue = "Transcription base URL must be a full URL, e.g. https://api.groq.com/openai/v1"
            return
        }
        let cleanupBase = cleanupBaseURLField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanupBase.isEmpty || (URL(string: cleanupBase)?.scheme != nil) else {
            statusLabel.stringValue = "Cleanup base URL must be a full URL, e.g. http://localhost:4070/v1"
            return
        }
        Settings.transcriptionBaseURL = transcribeBase
        Settings.transcriptionAPIKey = transcriptionKeyField.stringValue
        Settings.transcribeModel = transcribeModelField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        Settings.cleanupBaseURL = cleanupBase
        Settings.cleanupAPIKey = cleanupKeyField.stringValue
        Settings.cleanupModel = cleanupModelField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        Settings.cleanupPrompt = promptField.stringValue
        LoginItemManager.setEnabled(launchAtLoginCheckbox.state == .on)
        statusLabel.stringValue = "Saved."
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.window?.close()
        }
    }
}
