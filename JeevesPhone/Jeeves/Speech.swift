import Foundation
import Speech
import AVFoundation


// These live OUTSIDE the main-actor class on purpose: Apple calls these callbacks on background threads, and closures created inside a
// main-actor class would crash the app there.
func askSpeechPermission() async {
    _ = await withCheckedContinuation { (c: CheckedContinuation<SFSpeechRecognizerAuthorizationStatus, Never>) in
        SFSpeechRecognizer.requestAuthorization { c.resume(returning: $0) }
    }
}

func installMicTap(_ input: AVAudioInputNode, _ req: SFSpeechAudioBufferRecognitionRequest) {
    input.removeTap(onBus: 0)
    input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { buffer, _ in req.append(buffer) }
}

func startRecognition(_ rec: SFSpeechRecognizer?, _ req: SFSpeechAudioBufferRecognitionRequest, _ handler: @escaping @Sendable (String?, Bool) -> Void) -> SFSpeechRecognitionTask? {
    rec?.recognitionTask(with: req) { result, error in
        handler(result?.bestTranscription.formattedString, (result?.isFinal ?? false) || error != nil)
    }
}

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
        await askSpeechPermission()
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
        installMicTap(engine.inputNode, req)
        engine.prepare(); try? engine.start(); listening = true
        task = startRecognition(recognizer, req) { [weak self] text, done in
            Task { @MainActor in
                guard let self else { return }
                if let text { self.heard = text }
                if done { self.finish() }
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
        u.voice = Self.butlerVoice(); u.rate = 0.5
        speaking = true; synth.speak(u)
    }
    func stopSpeaking() { synth.stopSpeaking(at: .immediate); speaking = false }
    nonisolated func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish u: AVSpeechUtterance) { Task { @MainActor in self.speaking = false } }

    /// Best installed British voice: premium > enhanced > standard, preferring male butler-ish names.
    static func butlerVoice() -> AVSpeechSynthesisVoice? {
        let gb = AVSpeechSynthesisVoice.speechVoices().filter { $0.language == "en-GB" }
        let male = ["Arthur", "Daniel", "Oliver", "Malcolm", "Gordon"]
        func score(_ v: AVSpeechSynthesisVoice) -> Int { v.quality.rawValue * 10 + (male.contains { v.name.contains($0) } ? 5 : 0) }
        return gb.max { score($0) < score($1) } ?? AVSpeechSynthesisVoice(language: "en-GB")
    }
    static var voiceIsBasic: Bool { (butlerVoice()?.quality.rawValue ?? 1) < 2 }
}
