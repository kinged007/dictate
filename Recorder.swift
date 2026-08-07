import AVFoundation
import Foundation

enum RecorderError: LocalizedError {
    case noPermission
    case failedToStart(String)

    var errorDescription: String? {
        switch self {
        case .noPermission: return "Microphone permission denied."
        case .failedToStart(let details): return "Could not start recording: \(details)"
        }
    }
}

/// Records microphone audio to a temp m4a file. AVAudioRecorder is the
/// simplest API that works on macOS 10.15.
final class Recorder: NSObject, AVAudioRecorderDelegate {
    /// Called on the calling thread when recording stops (success or failure).
    var onFinish: ((Result<URL, Error>) -> Void)?

    private var recorder: AVAudioRecorder?

    var isRecording: Bool { recorder?.isRecording ?? false }

    func start() throws {
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("dictate-\(UUID().uuidString).m4a")

        let recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder.delegate = self
        recorder.isMeteringEnabled = true
        guard recorder.record() else {
            throw RecorderError.failedToStart("record() returned false")
        }
        self.recorder = recorder
    }

    func stop() {
        recorder?.stop()
    }

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        self.recorder = nil
        if flag {
            onFinish?(.success(recorder.url))
        } else {
            onFinish?(.failure(RecorderError.failedToStart("recording did not finish successfully")))
        }
    }
}
