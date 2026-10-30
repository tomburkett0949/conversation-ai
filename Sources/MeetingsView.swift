import SwiftUI
import AVFoundation

struct RecordingItem: Identifiable {
    let id = UUID()
    let url: URL
    let date: Date
    let duration: TimeInterval
    let preview: String
    var title: String? = nil
    var folder: String? = nil
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
            var title: String? = nil
            var folder: String? = nil
            if let m = Storage.loadMeeting(for: url) {
                preview = m.lines.prefix(2).map { $0.text }.joined(separator: " ")
                title = m.title; folder = m.folder
            }
            return RecordingItem(url: url, date: date, duration: dur, preview: preview, title: title, folder: folder)
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
    @State private var folderFilter: String? = nil
    private var folders: [String] { Array(Set(model.items.compactMap { $0.folder })).sorted() }
    private var shown: [RecordingItem] { model.items.filter { folderFilter == nil || $0.folder == folderFilter } }

    var body: some View {
        Group {
            if model.items.isEmpty {
                Text("No recordings yet.\nTap Record on the home screen.")
                    .multilineTextAlignment(.center).foregroundStyle(Brand.dim)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(shown) { item in
                        NavigationLink(destination: MeetingDetailView(item: item)) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.title ?? item.date.formatted(date: .abbreviated, time: .shortened)).foregroundStyle(Brand.ink)
                                Text(durationText(item.duration) + (item.title != nil ? " · " + item.date.formatted(date: .abbreviated, time: .shortened) : "") + (item.folder != nil ? " · " + item.folder! : ""))
                                    .font(.footnote).foregroundStyle(Brand.dim)
                                if !item.preview.isEmpty {
                                    Text(item.preview).font(.footnote).foregroundStyle(Brand.dim).lineLimit(2)
                                }
                            }
                        }
                        .listRowBackground(Brand.panel)
                    }
                    .onDelete { offsets in
                        let ids = offsets.map { shown[$0].id }
                        model.delete(at: IndexSet(model.items.enumerated().filter { ids.contains($0.element.id) }.map { $0.offset }))
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .background(Brand.bg.ignoresSafeArea())
        .navigationTitle("Meetings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !folders.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("All meetings") { folderFilter = nil }
                        ForEach(folders, id: \.self) { f in Button(f) { folderFilter = f } }
                    } label: { Image(systemName: folderFilter == nil ? "folder" : "folder.fill") }
                }
            }
        }
        .onAppear { model.load() }
    }

    private func durationText(_ d: TimeInterval) -> String {
        String(format: "%d:%02d", Int(d) / 60, Int(d) % 60)
    }
}
