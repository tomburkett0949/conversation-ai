import SwiftUI
import AVFoundation

struct RecordingItem: Identifiable {
    let id = UUID()
    let url: URL
    let date: Date
    let duration: TimeInterval
    let preview: String
}

final class MeetingsModel: ObservableObject {
    @Published var items: [RecordingItem] = []

    func load() {
        let urls = (try? FileManager.default.contentsOfDirectory(at: Storage.recordingsDir,
                    includingPropertiesForKeys: [.creationDateKey])) ?? []
        items = urls.filter { $0.pathExtension == "m4a" }.compactMap { url in
            let date = (try? url.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date()
            let dur = (try? AVAudioPlayer(contentsOf: url).duration) ?? 0
            var preview = ""
            if let m = Storage.loadMeeting(for: url) {
                preview = m.lines.prefix(2).map { $0.text }.joined(separator: " ")
            }
            return RecordingItem(url: url, date: date, duration: dur, preview: preview)
        }.sorted { $0.date > $1.date }
    }

    func delete(at offsets: IndexSet) {
        for i in offsets {
            try? FileManager.default.removeItem(at: items[i].url)
            try? FileManager.default.removeItem(at: Storage.jsonURL(for: items[i].url))
        }
        items.remove(atOffsets: offsets)
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
                        NavigationLink(destination: MeetingDetailView(item: item)) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.date.formatted(date: .abbreviated, time: .shortened)).foregroundStyle(Brand.ink)
                                Text(durationText(item.duration)).font(.footnote).foregroundStyle(Brand.dim)
                                if !item.preview.isEmpty {
                                    Text(item.preview).font(.footnote).foregroundStyle(Brand.dim).lineLimit(2)
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

    private func durationText(_ d: TimeInterval) -> String {
        String(format: "%d:%02d", Int(d) / 60, Int(d) % 60)
    }
}
