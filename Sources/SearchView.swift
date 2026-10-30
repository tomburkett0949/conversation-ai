import SwiftUI

struct SearchView: View {
    @StateObject private var meetings = MeetingsModel()
    @State private var query = ""

    private var results: [Excerpt] { Retriever.find(query, in: meetings.items) }

    var body: some View {
        List {
            if query.count > 1 && results.isEmpty {
                Text("No matches.").foregroundStyle(Brand.dim).listRowBackground(Color.clear)
            }
            ForEach(results) { r in
                NavigationLink(destination: MeetingDetailView(item: r.item, startAt: r.time)) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(r.item.title ?? r.item.date.formatted(date: .abbreviated, time: .shortened)) · \(stamp(r.time))")
                            .font(.footnote.bold()).foregroundStyle(Brand.pink)
                        highlighted(r.text)
                    }
                }
                .listRowBackground(Brand.panel)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Brand.bg.ignoresSafeArea())
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Find any word or phrase")
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { meetings.load() }
    }

    private func highlighted(_ text: String) -> Text {
        var attr = AttributedString(text)
        if let range = attr.range(of: query, options: .caseInsensitive) {
            attr[range].foregroundColor = Brand.hot
            attr[range].font = .body.bold()
        }
        return Text(attr).foregroundColor(Brand.ink)
    }

    private func stamp(_ t: TimeInterval) -> String { String(format: "%d:%02d", Int(t) / 60, Int(t) % 60) }
}
