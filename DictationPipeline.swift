import AVFoundation
import Cocoa
import Foundation

enum DictationState {
    case idle
    case recording
    case processing
}

/// The core loop: hotkey toggles recording -> transcribe -> LLM cleanup ->
/// paste at cursor. Swift 5.3, no async/await — all completion-handler based.
final class DictationPipeline {
    var onStateChange: ((DictationState) -> Void)?

    private(set) var state: DictationState = .idle {
        didSet { onStateChange?(state) }
    }

    private let recorder = Recorder()
    private let client = DictationClient()
    private let paster = Paster()

    func toggle() {
        switch state {
        case .idle:
            startRecording()
        case .recording:
            stopRecording()
        case .processing:
            break // ignore hotkey while a dictation is in flight
        }
    }

    private func startRecording() {
        ensurePermissions { [weak self] ok in
            guard let self = self, ok else { return }
            do {
                self.recorder.onFinish = { [weak self] result in
                    DispatchQueue.main.async {
                        guard let self = self else { return }
                        switch result {
                        case .success(let url):
                            self.process(audioURL: url)
                        case .failure(let error):
                            self.state = .idle
                            self.alert("Recording failed", error.localizedDescription)
                        }
                    }
                }
                try self.recorder.start()
                self.state = .recording
            } catch {
                self.state = .idle
                self.alert("Recording failed", error.localizedDescription)
            }
        }
    }

    private func stopRecording() {
        state = .processing
        recorder.stop()
    }

    private func process(audioURL: URL) {
        guard let apiKey = Settings.transcriptionAPIKey, !apiKey.isEmpty else {
            state = .idle
            alert("No transcription API key", "Open Settings and add your Groq API key.")
            return
        }
        let transcriptionBaseURL = Settings.transcriptionBaseURL
        let transcribeModel = Settings.transcribeModel

        client.transcribe(audioURL: audioURL, baseURL: transcriptionBaseURL, apiKey: apiKey, model: transcribeModel) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let transcript):
                    self.cleanup(transcript: transcript)
                case .failure(let error):
                    self.state = .idle
                    self.alert("Transcription failed", error.localizedDescription)
                }
            }
        }
    }

    private func cleanup(transcript: String) {
        client.clean(
            transcript: transcript,
            baseURL: Settings.cleanupBaseURL,
            apiKey: Settings.cleanupAPIKey ?? "",
            model: Settings.cleanupModel,
            systemPrompt: Settings.cleanupPrompt
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let cleaned):
                    self.state = .idle
                    self.paster.paste(cleaned)
                case .failure(let error):
                    self.state = .idle
                    self.alert("Cleanup failed", "\(error.localizedDescription)\n\nRaw transcript copied to clipboard instead.")
                    let pb = NSPasteboard.general
                    pb.clearContents()
                    pb.setString(transcript, forType: .string)
                }
            }
        }
    }

    // MARK: - Permissions

    private func ensurePermissions(completion: @escaping (Bool) -> Void) {
        if AVCaptureDevice.authorizationStatus(for: .audio) == .authorized {
            ensureAccessibility(completion: completion)
            return
        }
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if granted {
                    self.ensureAccessibility(completion: completion)
                } else {
                    self.alert("Microphone permission required", "Enable it in System Preferences > Security & Privacy > Privacy > Microphone.")
                    completion(false)
                }
            }
        }
    }

    private func ensureAccessibility(completion: @escaping (Bool) -> Void) {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        if AXIsProcessTrustedWithOptions(options) {
            completion(true)
        } else {
            alert(
                "Accessibility permission required",
                "Dictate needs Accessibility access to paste text at your cursor. Add Dictate in System Preferences > Security & Privacy > Privacy > Accessibility, then press the hotkey again."
            )
            completion(false)
        }
    }

    private func alert(_ title: String, _ message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
