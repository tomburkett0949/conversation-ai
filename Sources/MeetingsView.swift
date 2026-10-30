import SwiftUI
import AVFoundation

struct RecordingItem: Identifiable {
    let id = UUID()
    let url: URL
    let date: Date
    let duration: TimeInterval
    let preview: String
}

final class MeetingsModel: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var items: [RecordingItem] = []
    @Published var playing: URL?
    private var player: AVAudioPlayer?

    func load() {
        let urls = (try? FileManager.default.contentsOfDirectory(at: Storage.recordingsDir,
                    includingPropertiesForKeys: [.creationDateKey])) ?? []
        items = urls.filter { $0.pathExtension == "m4a" }.compactMap { url in
            let date = (try? url.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date()
            let dur = (try? AVAudioPlayer(contentsOf: url).duration) ?? 0
            var preview = ""
            let jsonURL = url.deletingPathExtension().appendingPathExtension("json")
            if let data = try? Data(contentsOf: jsonURL),
               let m = try? JSONDecoder().decode(SavedMeeting.self, from: data) {
                preview = m.lines.prefix(2).map { $0.text }.joined(separator: " ")
            }
            return RecordingItem(url: url, date: date, duration: dur, preview: preview)
        }.sorted { $0.date > $1.date }
    }

    func toggle(_ item: RecordingItem) {
        if playing == item.url { player?.stop(); playing = nil; return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: item.url)
            player?.delegate = self
            player?.play()
            playing = item.url
        } catch { playing = nil }
    }

    func delete(at offsets: IndexSet) {
        for i in offsets {
            try? FileManager.default.removeItem(at: items[i].url)
            try? FileManager.default.removeItem(at: items[i].url.deletingPathExtension().appendingPathExtension("json"))
        }
        items.remove(atOffsets: offsets)
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { self.playing = nil }
    }
}

struct MeetingsView: View {
    @StateObject private var model = MeetingsModel()

    var body: some View {
        Group {
            if model.items.isEmpty {
                Text("No recordings yet.\nTap Record on the home screen.")
                    .multilineTextAlignment(.center).foregroundStyle(Brand.dim)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(model.items) { item in
                        Button { model.toggle(item) } label: {
                            HStack {
                                Image(systemName: model.playing == item.url ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.title2).foregroundStyle(Brand.pink)
                                VStack(alignment: .leading) {
                                    Text(item.date.formatted(date: .abbreviated, time: .shortened)).foregroundStyle(Brand.ink)
                                    Text(String(format: "%d:%02d", Int(item.duration) / 60, Int(item.duration) % 60))
                                        .font(.footnote).foregroundStyle(Brand.dim)
                                    if !item.preview.isEmpty {
                                        Text(item.preview).font(.footnote).foregroundStyle(Brand.dim).lineLimit(2)
                                    }
                                }
                            }
                        }
                        .listRowBackground(Brand.panel)
                    }
                    .onDelete(perform: model.delete)
                }
                .scrollContentBackground(.hidden)
            }
        }
        .background(Brand.bg.ignoresSafeArea())
        .navigationTitle("Meetings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { model.load() }
    }
}
