import AVFoundation
import Foundation

enum Storage {
    static var recordingsDir: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Recordings", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}

final class Recorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var elapsed: TimeInterval = 0
    @Published var level: Float = 0
    @Published var message: String?

    private var recorder: AVAudioRecorder?
    private var timer: Timer?

    func start() {
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                guard let self else { return }
                if granted { self.begin() } else {
                    self.message = "Microphone access is off. Turn it on in Settings > Conversation AI."
                }
            }
        }
    }

    private func begin() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
            let f = DateFormatter(); f.dateFormat = "yyyyMMdd-HHmmss"
            let url = Storage.recordingsDir.appendingPathComponent("Recording-\(f.string(from: Date())).m4a")
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            let r = try AVAudioRecorder(url: url, settings: settings)
            r.isMeteringEnabled = true
            guard r.record() else { message = "Could not start recording."; return }
            recorder = r
            isRecording = true
            elapsed = 0
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self, let r = self.recorder else { return }
                r.updateMeters()
                self.elapsed = r.currentTime
                let db = r.averagePower(forChannel: 0)
                self.level = max(0, min(1, (db + 50) / 50))
            }
        } catch {
            message = "Recording failed: \(error.localizedDescription)"
        }
    }

    func stop() {
        recorder?.stop()
        recorder = nil
        timer?.invalidate(); timer = nil
        isRecording = false
        level = 0
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
