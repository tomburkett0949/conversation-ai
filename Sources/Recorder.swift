import AVFoundation
import Speech
import Foundation

enum Storage {
    static var recordingsDir: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Recordings", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}

struct TranscriptLine: Identifiable, Codable {
    var id = UUID()
    let time: TimeInterval
    let text: String
}

struct SavedMeeting: Codable {
    var date: Date
    var duration: TimeInterval
    var lines: [TranscriptLine]
    var bookmarks: [TimeInterval]
    var notes: String
}

/// Records with AVAudioEngine (so audio can feed live on-device speech recognition at the same time).
final class Recorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var isPaused = false
    @Published var saved = false
    @Published var elapsed: TimeInterval = 0
    @Published var levels: [Float] = Array(repeating: 0, count: 24)
    @Published var message: String?
    @Published var lines: [TranscriptLine] = []
    @Published var partial = ""
    @Published var bookmarks: [TimeInterval] = []
    @Published var notes = ""

    private let engine = AVAudioEngine()
    private let lock = NSLock()
    private var file: AVAudioFile?
    private var fileURL: URL?
    private var frames: AVAudioFramePosition = 0
    private var sampleRate: Double = 44100
    private var rmsLevel: Float = 0
    private var startDate = Date()

    private var recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var taskID = 0
    private var taskStartElapsed: TimeInterval = 0
    private var timer: Timer?

    // MARK: Start / pause / stop

    func start() {
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                guard let self else { return }
                guard granted else {
                    self.message = "Microphone access is off. Turn it on in Settings > Conversation AI."
                    return
                }
                SFSpeechRecognizer.requestAuthorization { status in
                    DispatchQueue.main.async {
                        self.setUpRecognizer(allowed: status == .authorized)
                        self.begin()
                    }
                }
            }
        }
    }

    private func setUpRecognizer(allowed: Bool) {
        guard allowed else {
            message = "Speech recognition is off, so there is no live transcript. Turn it on in Settings."
            return
        }
        if let r = SFSpeechRecognizer(locale: Locale(identifier: "en-GB")), r.supportsOnDeviceRecognition {
            recognizer = r
        } else {
            message = "Live transcript isn't available on this device right now. Audio is still being recorded."
        }
    }

    private func begin() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)

            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            sampleRate = format.sampleRate
            let f = DateFormatter(); f.dateFormat = "yyyyMMdd-HHmmss"
            let url = Storage.recordingsDir.appendingPathComponent("Recording-\(f.string(from: Date())).m4a")
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: format.sampleRate,
                AVNumberOfChannelsKey: Int(format.channelCount)
            ]
            file = try AVAudioFile(forWriting: url, settings: settings,
                                   commonFormat: format.commonFormat, interleaved: format.isInterleaved)
            fileURL = url
            startDate = Date()
            input.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
                self?.handle(buffer)
            }
            engine.prepare()
            try engine.start()
            isRecording = true
            startTask()
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in self?.tick() }
        } catch {
            message = "Recording failed: \(error.localizedDescription)"
        }
    }

    func togglePause() {
        guard isRecording else { return }
        if isPaused {
            do { try engine.start() } catch { message = "Could not resume: \(error.localizedDescription)"; return }
            isPaused = false
            startTask()
        } else {
            engine.pause()
            isPaused = true
            lock.lock(); let req = request; request = nil; lock.unlock()
            req?.endAudio()
        }
    }

    func addBookmark() {
        guard isRecording else { return }
        bookmarks.append(elapsed)
    }

    func stop() {
        guard isRecording else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        timer?.invalidate(); timer = nil
        lock.lock()
        let req = request; request = nil
        file = nil
        let duration = sampleRate > 0 ? Double(frames) / sampleRate : 0
        lock.unlock()
        req?.endAudio()
        isRecording = false
        isPaused = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        // Give the recogniser a moment to deliver its last words, then save everything.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in self?.finish(duration: duration) }
    }

    private func finish(duration: TimeInterval) {
        if !partial.trimmingCharacters(in: .whitespaces).isEmpty {
            lines.append(TranscriptLine(time: taskStartElapsed, text: partial))
            partial = ""
        }
        lines.sort { $0.time < $1.time }
        if let url = fileURL {
            let meeting = SavedMeeting(date: startDate, duration: duration, lines: lines, bookmarks: bookmarks, notes: notes)
            if let data = try? JSONEncoder().encode(meeting) {
                try? data.write(to: url.deletingPathExtension().appendingPathExtension("json"))
            }
        }
        saved = true
    }

    // MARK: Audio callback (audio thread)

    private func handle(_ buffer: AVAudioPCMBuffer) {
        lock.lock()
        try? file?.write(from: buffer)
        frames += AVAudioFramePosition(buffer.frameLength)
        request?.append(buffer)
        if let ch = buffer.floatChannelData?[0] {
            let n = Int(buffer.frameLength)
            var sum: Float = 0
            for i in 0..<n { let v = ch[i]; sum += v * v }
            let rms = n > 0 ? (sum / Float(n)).squareRoot() : 0
            let db = 20 * log10(max(rms, 0.00001))
            rmsLevel = max(0, min(1, (db + 50) / 50))
        }
        lock.unlock()
    }

    private func currentElapsed() -> TimeInterval {
        lock.lock(); defer { lock.unlock() }
        return sampleRate > 0 ? Double(frames) / sampleRate : 0
    }

    private func tick() {
        elapsed = currentElapsed()
        lock.lock(); let l = rmsLevel; lock.unlock()
        levels.removeFirst()
        levels.append(isPaused ? 0 : l)
        // Start a fresh recognition task every 40 s so transcript paragraphs stay short and robust.
        if recognizer != nil, !isPaused, elapsed - taskStartElapsed > 40 { startTask() }
    }

    // MARK: Live transcript (on-device speech recognition)

    private func startTask() {
        guard let rec = recognizer, rec.isAvailable else { return }
        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        req.addsPunctuation = true
        req.requiresOnDeviceRecognition = true   // never send audio to Apple's servers
        taskID += 1
        let id = taskID
        let startAt = currentElapsed()
        taskStartElapsed = startAt
        partial = ""
        lock.lock(); let old = request; request = req; lock.unlock()
        old?.endAudio()
        task = rec.recognitionTask(with: req) { [weak self] result, error in
            DispatchQueue.main.async { self?.onResult(id: id, startAt: startAt, result: result, error: error) }
        }
    }

    private func onResult(id: Int, startAt: TimeInterval, result: SFSpeechRecognitionResult?, error: Error?) {
        if saved { return }
        let current = (id == taskID)
        let text = result?.bestTranscription.formattedString ?? ""
        if let r = result, !r.isFinal, current { partial = text }
        let done = (result?.isFinal ?? false) || error != nil
        guard done else { return }
        let finalText = (text.isEmpty && current) ? partial : text
        if !finalText.trimmingCharacters(in: .whitespaces).isEmpty {
            lines.append(TranscriptLine(time: startAt, text: finalText))
            lines.sort { $0.time < $1.time }
        }
        if current {
            partial = ""
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                guard let self, self.isRecording, !self.isPaused, id == self.taskID else { return }
                self.startTask()
            }
        }
    }
}
