import SwiftUI
import AVFoundation

final class PlayerModel: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var current: TimeInterval = 0
    @Published var isPlaying = false
    @Published var duration: TimeInterval = 0
    private var player: AVAudioPlayer?
    private var timer: Timer?

    func load(_ url: URL) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.prepareToPlay()
            duration = player?.duration ?? 0
        } catch { player = nil }
    }

    func toggle() {
        guard let p = player else { return }
        if p.isPlaying { p.pause(); isPlaying = false; timer?.invalidate() }
        else { p.play(); isPlaying = true; startTimer() }
    }

    func seek(_ t: TimeInterval, play: Bool = false) {
        guard let p = player else { return }
        p.currentTime = max(0, min(t, duration))
        current = p.currentTime
        if play && !p.isPlaying { p.play(); isPlaying = true; startTimer() }
    }

    func skip(_ d: TimeInterval) { seek(current + d) }

    func stop() { player?.stop(); timer?.invalidate(); isPlaying = false }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            guard let self, let p = self.player else { return }
            self.current = p.currentTime
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { self.isPlaying = false; self.timer?.invalidate() }
    }
}

struct MeetingDetailView: View {
    let item: RecordingItem
    @StateObject private var player = PlayerModel()
    @State private var meeting: SavedMeeting?
    @State private var tab = "Transcript"
    @State private var notes = ""

    private var lines: [TranscriptLine] { meeting?.lines ?? [] }
    private var activeIndex: Int? { lines.lastIndex { $0.time <= player.current } }

    var body: some View {
        VStack(spacing: 0) {
            header
            Picker("", selection: $tab) {
                Text("Transcript").tag("Transcript")
                Text("Notes").tag("Notes")
                Text("Bookmarks").tag("Bookmarks")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16).padding(.bottom, 8)
            content
        }
        .background(Brand.bg.ignoresSafeArea())
        .navigationTitle(item.date.formatted(date: .abbreviated, time: .shortened))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            player.load(item.url)
            meeting = Storage.loadMeeting(for: item.url)
            notes = meeting?.notes ?? ""
        }
        .onDisappear { player.stop(); saveNotes() }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Slider(value: Binding(get: { player.current }, set: { player.seek($0) }),
                   in: 0...max(player.duration, 1))
            HStack {
                Text(time(player.current)).font(.footnote.monospacedDigit()).foregroundStyle(Brand.dim)
                Spacer()
                Button { player.skip(-15) } label: { Image(systemName: "gobackward.15").font(.title2) }
                Button { player.toggle() } label: {
                    Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 48)).foregroundStyle(Brand.pink)
                }
                Button { player.skip(15) } label: { Image(systemName: "goforward.15").font(.title2) }
                Spacer()
                Text(time(player.duration)).font(.footnote.monospacedDigit()).foregroundStyle(Brand.dim)
            }
            .foregroundStyle(Brand.ink)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
    }

    @ViewBuilder private var content: some View {
        switch tab {
        case "Notes":
            TextEditor(text: $notes)
                .padding(12).scrollContentBackground(.hidden)
                .background(Brand.panel, in: RoundedRectangle(cornerRadius: 12))
                .padding(16)
        case "Bookmarks":
            let marks = meeting?.bookmarks ?? []
            if marks.isEmpty {
                Text("No bookmarks. Tap the bookmark button while recording to mark a moment.")
                    .foregroundStyle(Brand.dim).multilineTextAlignment(.center)
                    .padding(30).frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(Array(marks.enumerated()), id: \.offset) { _, t in
                    Button { player.seek(t, play: true) } label: {
                        Label(time(t), systemImage: "bookmark.fill").foregroundStyle(Brand.ink)
                    }
                    .listRowBackground(Brand.panel)
                }
                .scrollContentBackground(.hidden)
            }
        default:
            transcript
        }
    }

    private var transcript: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if lines.isEmpty {
                    Text("No transcript for this recording.")
                        .foregroundStyle(Brand.dim).padding(30).frame(maxWidth: .infinity)
                }
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(lines.enumerated()), id: \.element.id) { i, l in
                        Button { player.seek(l.time, play: true) } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(time(l.time)).font(.footnote).foregroundStyle(Brand.pink)
                                Text(l.text).font(.system(size: 17)).foregroundStyle(Brand.ink)
                                    .multilineTextAlignment(.leading)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                            .background(i == activeIndex ? Brand.pink.opacity(0.18) : Color.clear,
                                        in: RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                        .id(l.id)
                    }
                }
                .padding(.horizontal, 12).padding(.bottom, 20)
            }
            .onChange(of: activeIndex) { _, new in
                if let new, player.isPlaying { withAnimation { proxy.scrollTo(lines[new].id, anchor: .center) } }
            }
        }
    }

    private func saveNotes() {
        guard var m = meeting, m.notes != notes else { return }
        m.notes = notes
        Storage.saveMeeting(m, for: item.url)
    }

    private func time(_ t: TimeInterval) -> String {
        let s = Int(max(0, t))
        return s >= 3600 ? String(format: "%d:%02d:%02d", s / 3600, (s / 60) % 60, s % 60)
                         : String(format: "%d:%02d", s / 60, s % 60)
    }
}
