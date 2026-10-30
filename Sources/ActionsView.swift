import SwiftUI

struct ActionRow: Identifiable {
    let id: String
    let text: String
    let item: RecordingItem
}

@MainActor
final class ActionsModel: ObservableObject {
    @Published var rows: [ActionRow] = []
    @Published var done: Set<String> = Set(UserDefaults.standard.stringArray(forKey: "doneActions") ?? [])

    func load() {
        let m = MeetingsModel(); m.load()
        rows = m.items.flatMap { item -> [ActionRow] in
            guard let s = Storage.loadMeeting(for: item.url)?.summary else { return [] }
            return s.actions.map { ActionRow(id: item.url.lastPathComponent + "|" + $0, text: $0, item: item) }
        }
    }

    func toggle(_ r: ActionRow) {
        if done.contains(r.id) { done.remove(r.id) } else { done.insert(r.id) }
        UserDefaults.standard.set(Array(done), forKey: "doneActions")
    }
}

struct ActionsView: View {
    @StateObject private var model = ActionsModel()
    @State private var showDone = false

    private var visible: [ActionRow] { model.rows.filter { showDone || !model.done.contains($0.id) } }

    var body: some View {
        Group {
            if model.rows.isEmpty {
                Text("No action items yet.\nOpen a meeting and tap Create summary — any tasks it finds appear here.")
                    .multilineTextAlignment(.center).foregroundStyle(Brand.dim).padding(30)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Toggle("Show completed", isOn: $showDone).listRowBackground(Brand.panel)
                    ForEach(visible) { r in
                        let isDone = model.done.contains(r.id)
                        HStack(alignment: .top, spacing: 12) {
                            Button { model.toggle(r) } label: {
                                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                                    .font(.title3).foregroundStyle(isDone ? Brand.pink : Brand.dim)
                            }.buttonStyle(.plain)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(r.text).strikethrough(isDone).foregroundStyle(isDone ? Brand.dim : Brand.ink)
                                NavigationLink(destination: MeetingDetailView(item: r.item)) {
                                    Text(r.item.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.footnote).foregroundStyle(Brand.pink)
                                }
                            }
                        }
                        .listRowBackground(Brand.panel)
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .background(Brand.bg.ignoresSafeArea())
        .navigationTitle("Actions")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { model.load() }
    }
}
