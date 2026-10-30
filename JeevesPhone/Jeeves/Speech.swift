import Foundation
import Speech
import AVFoundation

/// Free, on-device hearing and speaking. Nothing leaves the phone.
@MainActor final class Voice: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published var heard = ""
    @Published var listening = false
    @Published var speaking = false
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-GB"))
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let synth = AVSpeechSynthesizer()
    var onFinal: ((String) -> Void)?

    override init() { super.init(); synth.delegate = self }

    func authorise() async {
        _ = await withCheckedContinuation { c in SFSpeechRecognizer.requestAuthorization { c.resume(returning: $0) } }
        _ = await AVAudioApplication.requestRecordPermission()
    }

    func start() {
        stopSpeaking(); heard = ""
        let s = AVAudioSession.sharedInstance()
        try? s.setCategory(.playAndRecord, mode: .measurement, options: [.allowBluetooth, .defaultToSpeaker])
        try? s.setActive(true)
        let req = SFSpeechAudioBufferRecognitionRequest(); req.shouldReportPartialResults = true
        req.requiresOnDeviceRecognition = recognizer?.supportsOnDeviceRecognition ?? false
        request = req
        let input = engine.inputNode
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { [weak req] b, _ in req?.append(b) }
        engine.prepare(); try? engine.start(); listening = true
        task = recognizer?.recognitionTask(with: req) { [weak self] r, e in
            Task { @MainActor in
                guard let self else { return }
                if let r { self.heard = r.bestTranscription.formattedString }
                if (r?.isFinal ?? false) || e != nil { self.finish() }
            }
        }
    }

    func stop() { request?.endAudio() }   // tap again to finish; recognition then reports final text

    private func finish() {
        guard listening else { return }
        listening = false; engine.stop(); engine.inputNode.removeTap(onBus: 0); task = nil; request = nil
        let t = heard.trimmingCharacters(in: .whitespacesAndNewlines)
        if !t.isEmpty { onFinal?(t) }
    }

    func speak(_ text: String) {
        let u = AVSpeechUtterance(string: text)
        u.voice = Self.butlerVoice(); u.rate = 0.47; u.pitchMultiplier = 0.9
        speaking = true; synth.speak(u)
    }
    func stopSpeaking() { synth.stopSpeaking(at: .immediate); speaking = false }
    nonisolated func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish u: AVSpeechUtterance) { Task { @MainActor in self.speaking = false } }

    /// Best installed British male voice (Daniel by default; download "Daniel (Enhanced)" in Settings > Accessibility > Spoken Content > Voices for a nicer one).
    static func butlerVoice() -> AVSpeechSynthesisVoice? {
        let gb = AVSpeechSynthesisVoice.speechVoices().filter { $0.language == "en-GB" }
        return gb.filter { $0.name.contains("Daniel") }.max { $0.quality.rawValue < $1.quality.rawValue }
            ?? gb.max { $0.quality.rawValue < $1.quality.rawValue } ?? AVSpeechSynthesisVoice(language: "en-GB")
    }
}
