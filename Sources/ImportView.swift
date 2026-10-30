import SwiftUI
import AVFoundation
import Speech
import UniformTypeIdentifiers

@MainActor
final class ImportModel: ObservableObject {
    @Published var status = ""
    @Published var busy = false
    @Published var finished = false

    func importFile(_ src: URL) async {
        busy = true; finished = false
        defer { busy = false }
        let scoped = src.startAccessingSecurityScopedResource()
        defer { if scoped { src.stopAccessingSecurityScopedResource() } }

        status = "Preparing audio…"
        let stamp = Int(Date().timeIntervalSince1970)
        let dest = Storage.recordingsDir.appendingPathComponent("import-\(stamp).m4a")
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("src-\(stamp)-\(src.lastPathComponent)")
        do {
            try? FileManager.default.removeItem(at: tmp)
            try FileManager.default.copyItem(at: src, to: tmp)
        } catch { status = "Couldn't read that file."; return }
        defer { try? FileManager.default.removeItem(at: tmp) }

        guard await convertToM4A(tmp, dest) else { status = "Couldn't read audio from that file."; return }
        let asset = AVURLAsset(url: dest)
        let duration = (try? await asset.load(.duration).seconds) ?? 0

        status = "Transcribing on this device… this can take a few minutes for long files."
        guard await requestSpeech() else { status = "Speech recognition is off. Turn it on in Settings."; return }
        guard let lines = await transcribe(dest), !lines.isEmpty else {
            status = "Saved the audio, but no speech was found (or on-device English isn't available)."
            var m = SavedMeeting(date: Date(), duration: duration, lines: [], bookmarks: [], notes: "")
            m.summary = nil
            Storage.saveMeeting(m, for: dest)
            finished = true
            return
        }
        var meeting = SavedMeeting(date: Date(), duration: duration, lines: lines, bookmarks: [], notes: "")
        status = "Writing summary…"
        meeting.summary = await Summarizer.summarize(lines)
        Storage.saveMeeting(meeting, for: dest)
        status = "Done. It's in Meetings."
        finished = true
    }

    private func convertToM4A(_ src: URL, _ dest: URL) async -> Bool {
        let asset = AVURLAsset(url: src)
        guard let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else { return false }
        session.outputURL = dest
        session.outputFileType = .m4a
        return await withCheckedContinuation { cont in
            session.exportAsynchronously { cont.resume(returning: session.status == .completed) }
        }
    }

    private func requestSpeech() async -> Bool {
        await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { cont.resume(returning: $0 == .authorized) }
        }
    }

    private func transcribe(_ url: URL) async -> [TranscriptLine]? {
        guard let rec = SFSpeechRecognizer(locale: Locale(identifier: "en-GB")), rec.supportsOnDeviceRecognition else { return nil }
        let req = SFSpeechURLRecognitionRequest(url: url)
        req.requiresOnDeviceRecognition = true
        req.shouldReportPartialResults = false
        req.addsPunctuation = true
        return await withCheckedContinuation { (cont: CheckedContinuation<[TranscriptLine]?, Never>) in
            var resumed = false
            rec.recognitionTask(with: req) { result, error in
                if resumed { return }
                if let r = result, r.isFinal {
                    resumed = true
                    cont.resume(returning: Self.group(r.bestTranscription.segments))
                } else if error != nil {
                    resumed = true
                    cont.resume(returning: nil)
                }
            }
        }
    }

    /// Groups word segments into readable lines: new line after a pause or about 14 words.
    nonisolated private static func group(_ segs: [SFTranscriptionSegment]) -> [TranscriptLine] {
        var lines: [TranscriptLine] = []
        var words: [String] = []; var start: TimeInterval = 0; var lastEnd: TimeInterval = 0
        for s in segs {
            if !words.isEmpty, (s.timestamp - lastEnd > 1.2 || words.count >= 14) {
                lines.append(TranscriptLine(time: start, text: words.joined(separator: " ")))
                words = []
            }
            if words.isEmpty { start = s.timestamp }
            words.append(s.substring)
            lastEnd = s.timestamp + s.duration
        }
        if !words.isEmpty { lines.append(TranscriptLine(time: start, text: words.joined(separator: " "))) }
        return lines
    }
}

struct ImportView: View {
    @StateObject private var model = ImportModel()
    @State private var picking = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.and.arrow.down").font(.system(size: 54)).foregroundStyle(Brand.pink)
            Text("Import a recording").font(.title2.bold()).foregroundStyle(Brand.ink)
            Text("Pick an audio or video file (MP3, M4A, WAV, MP4, MOV…) from Files, iCloud Drive or Voice Memos. It's transcribed on this device and summarised, with nothing uploaded.")
                .multilineTextAlignment(.center).font(.footnote).foregroundStyle(Brand.dim)
            Button { picking = true } label: {
                Text("Choose file").bold().frame(maxWidth: .infinity).padding(14)
                    .background(Brand.pink.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
            }.disabled(model.busy)
            if model.busy { ProgressView() }
            if !model.status.isEmpty { Text(model.status).font(.footnote).foregroundStyle(Brand.ink).multilineTextAlignment(.center) }
            if model.finished {
                NavigationLink("Open Meetings") { MeetingsView() }.bold()
            }
            Spacer()
        }
        .padding(24)
        .background(Brand.bg.ignoresSafeArea())
        .navigationTitle("Import")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $picking, allowedContentTypes: [.audio, .movie, .mpeg4Audio, .mp3, .wav]) { result in
            if case .success(let url) = result { Task { await model.importFile(url) } }
        }
    }
}
