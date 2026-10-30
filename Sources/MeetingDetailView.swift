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
    var startAt: TimeInterval? = nil
    @StateObject private var player = PlayerModel()
    @State private var meeting: SavedMeeting?
    @State private var tab = "Summary"
    @State private var working = false
    @State private var renaming = false
    @State private var foldering = false
    @State private var input = ""
    @State private var cardIndex = 0
    @State private var revealed = false
    @State private var makingCards = false
    @State private var notes = ""

    private var lines: [TranscriptLine] { meeting?.lines ?? [] }
    private var activeIndex: Int? { lines.lastIndex { $0.time <= player.current } }

    var body: some View {
        VStack(spacing: 0) {
            header
            Picker("", selection: $tab) {
                Text("Summary").tag("Summary")
                Text("Transcript").tag("Transcript")
                Text("Study").tag("Study")
                Text("Notes").tag("Notes")
                Text("Marks").tag("Bookmarks")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16).padding(.bottom, 8)
            content
        }
        .background(Brand.bg.ignoresSafeArea())
        .navigationTitle(meeting?.title ?? item.date.formatted(date: .abbreviated, time: .shortened))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { input = meeting?.title ?? ""; renaming = true } label: { Label("Rename", systemImage: "pencil") }
                    Button { input = meeting?.folder ?? ""; foldering = true } label: { Label("Set folder", systemImage: "folder") }
                    ShareLink(item: exportText) { Label("Share transcript and summary", systemImage: "square.and.arrow.up") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .alert("Rename", isPresented: $renaming) {
            TextField("Title", text: $input)
            Button("Save") { update { $0.title = input.isEmpty ? nil : input } }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Folder", isPresented: $foldering) {
            TextField("e.g. Coaching course, Lectures", text: $input)
            Button("Save") { update { $0.folder = input.isEmpty ? nil : input } }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear {
            player.load(item.url)
            meeting = Storage.loadMeeting(for: item.url)
            notes = meeting?.notes ?? ""
            if let t = startAt { tab = "Transcript"; player.seek(t) }
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
        case "Summary":
            summaryView
        case "Study":
            studyView
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

    private func update(_ change: (inout SavedMeeting) -> Void) {
        guard var m = meeting else { return }
        change(&m)
        meeting = m
        Storage.saveMeeting(m, for: item.url)
    }

    private var exportText: String {
        var out = (meeting?.title ?? item.date.formatted(date: .long, time: .shortened)) + "\n\n"
        if let s = meeting?.summary {
            out += "SUMMARY\n" + s.overview + "\n\n"
            if !s.keyPoints.isEmpty { out += "KEY POINTS\n" + s.keyPoints.map { "- " + $0 }.joined(separator: "\n") + "\n\n" }
            if !s.actions.isEmpty { out += "ACTIONS\n" + s.actions.map { "- " + $0 }.joined(separator: "\n") + "\n\n" }
            if !s.decisions.isEmpty { out += "DECISIONS\n" + s.decisions.map { "- " + $0 }.joined(separator: "\n") + "\n\n" }
        }
        if let n = meeting?.notes, !n.isEmpty { out += "NOTES\n" + n + "\n\n" }
        out += "TRANSCRIPT\n" + lines.map { "[\(time($0.time))] \($0.text)" }.joined(separator: "\n")
        return out
    }

    private var studyView: some View {
        let cards = meeting?.study ?? []
        return ScrollView {
            VStack(spacing: 16) {
                if cards.isEmpty {
                    Text("Turn this recording into flashcards to revise from.").foregroundStyle(Brand.dim).multilineTextAlignment(.center)
                } else {
                    let c = cards[min(cardIndex, cards.count - 1)]
                    Text("Card \(min(cardIndex, cards.count - 1) + 1) of \(cards.count)").font(.footnote).foregroundStyle(Brand.dim)
                    Button { revealed.toggle() } label: {
                        VStack(spacing: 12) {
                            Text(c.question).font(.title3.bold()).foregroundStyle(Brand.pink)
                            if revealed { Divider(); Text(c.answer).foregroundStyle(Brand.ink) }
                            else { Text("Tap to show the answer").font(.footnote).foregroundStyle(Brand.dim) }
                        }
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, minHeight: 200).padding(20)
                        .background(Brand.panel, in: RoundedRectangle(cornerRadius: 16))
                    }.buttonStyle(.plain)
                    HStack {
                        Button("Previous") { cardIndex = max(0, cardIndex - 1); revealed = false }.disabled(cardIndex == 0)
                        Spacer()
                        Button("Next") { cardIndex = min(cards.count - 1, cardIndex + 1); revealed = false }.disabled(cardIndex >= cards.count - 1)
                    }
                }
                if makingCards {
                    ProgressView("Writing flashcards on this device…")
                } else if !lines.isEmpty {
                    Button { makeCards() } label: {
                        Label(cards.isEmpty ? "Create flashcards" : "Make new flashcards", systemImage: "rectangle.on.rectangle")
                            .frame(maxWidth: .infinity).padding(12)
                            .background(Brand.pink.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
                    }
                    if !Summarizer.aiAvailable { Text("Needs Apple Intelligence, which isn't available on this device.").font(.footnote).foregroundStyle(Brand.dim) }
                }
            }
            .padding(16)
        }
    }

    private func makeCards() {
        makingCards = true
        Task {
            let cards = await StudyMaker.make(lines)
            await MainActor.run {
                if let cards, !cards.isEmpty { update { $0.study = cards }; cardIndex = 0; revealed = false }
                makingCards = false
            }
        }
    }

    private var summaryView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let s = meeting?.summary {
                    section("Overview", [s.overview])
                    if !s.keyPoints.isEmpty { section("Key points", s.keyPoints) }
                    if !s.actions.isEmpty { section("Action items", s.actions) }
                    if !s.decisions.isEmpty { section("Decisions", s.decisions) }
                    Text(s.onDeviceAI ? "Written on this device by Apple's on-device AI." : "Basic summary (Apple Intelligence is not available on this device).")
                        .font(.footnote).foregroundStyle(Brand.dim)
                }
                if working {
                    ProgressView("Summarising on this device…").frame(maxWidth: .infinity)
                } else if !lines.isEmpty {
                    Button { generate() } label: {
                        Label(meeting?.summary == nil ? "Create summary" : "Redo summary", systemImage: "sparkles")
                            .frame(maxWidth: .infinity).padding(12)
                            .background(Brand.pink.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
                    }
                } else {
                    Text("No transcript to summarise.").foregroundStyle(Brand.dim)
                }
            }
            .padding(16)
        }
    }

    private func section(_ title: String, _ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline).foregroundStyle(Brand.pink)
            ForEach(items, id: \.self) { Text(items.count > 1 ? "• \($0)" : $0).foregroundStyle(Brand.ink) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func generate() {
        working = true
        Task {
            let result = await Summarizer.summarize(lines)
            await MainActor.run {
                if var m = meeting, let result {
                    m.summary = result
                    meeting = m
                    Storage.saveMeeting(m, for: item.url)
                }
                working = false
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
