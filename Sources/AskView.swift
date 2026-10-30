import SwiftUI
import NaturalLanguage
#if canImport(FoundationModels)
import FoundationModels
#endif

struct Excerpt: Identifiable {
    let id = UUID()
    let item: RecordingItem
    let time: TimeInterval
    let text: String
}

struct QA: Identifiable {
    let id = UUID()
    let question: String
    var answer: String
    var sources: [Excerpt]
}

enum Retriever {
    private static let stop: Set<String> = ["the","a","an","and","or","of","to","in","on","for","is","are","was","were","what","when","did","do","does","i","we","you","it","that","this","about","say","said","with","my","me","have","had","how","who","which","there","from","at","be","by"]

    static func tokens(_ s: String) -> [String] {
        s.lowercased().split { !$0.isLetter && !$0.isNumber }.map(String.init).filter { $0.count > 2 && !stop.contains($0) }
    }

    /// Scores windows of 4 consecutive transcript lines across every recording by keyword overlap.
    static func search(_ query: String, in items: [RecordingItem], limit: Int = 5) -> [Excerpt] {
        let q = Set(tokens(query))
        guard !q.isEmpty else { return [] }
        var scored: [(Double, Excerpt)] = []
        for item in items {
            guard let m = Storage.loadMeeting(for: item.url) else { continue }
            let lines = m.lines
            var i = 0
            while i < lines.count {
                let window = lines[i..<min(i + 4, lines.count)]
                let text = window.map { $0.text }.joined(separator: " ")
                let words = Set(tokens(text))
                let hits = Double(q.intersection(words).count)
                if hits > 0 {
                    scored.append((hits / Double(q.count) + Double(hits) * 0.01, Excerpt(item: item, time: window.first!.time, text: text)))
                }
                i += 3
            }
        }
        let best = scored.sorted { $0.0 > $1.0 }.prefix(limit).map { $0.1 }
        if best.count >= 3 { return best }
        return best + semantic(query, in: items, limit: limit - best.count, skip: best)
    }

    /// Meaning-based fallback using Apple's on-device sentence embeddings (no keywords needed).
    static func semantic(_ query: String, in items: [RecordingItem], limit: Int, skip: [Excerpt]) -> [Excerpt] {
        guard limit > 0, let emb = NLEmbedding.sentenceEmbedding(for: .english) else { return [] }
        var scored: [(Double, Excerpt)] = []
        var count = 0
        for item in items {
            guard let m = Storage.loadMeeting(for: item.url) else { continue }
            var i = 0
            while i < m.lines.count, count < 600 {
                let window = m.lines[i..<min(i + 3, m.lines.count)]
                let text = window.map { $0.text }.joined(separator: " ")
                let d = emb.distance(between: query, and: text, distanceType: .cosine)
                if d < 1.1, !skip.contains(where: { $0.item.url == item.url && $0.time == window.first!.time }) {
                    scored.append((d, Excerpt(item: item, time: window.first!.time, text: text)))
                }
                i += 3; count += 1
            }
        }
        return scored.sorted { $0.0 < $1.0 }.prefix(limit).map { $0.1 }
    }

    /// Exact word or phrase search for the Search screen.
    static func find(_ query: String, in items: [RecordingItem]) -> [Excerpt] {
        let q = query.lowercased()
        guard q.count > 1 else { return [] }
        var out: [Excerpt] = []
        for item in items {
            guard let m = Storage.loadMeeting(for: item.url) else { continue }
            for l in m.lines where l.text.lowercased().contains(q) {
                out.append(Excerpt(item: item, time: l.time, text: l.text))
            }
        }
        return out
    }
}

@MainActor
final class AskModel: ObservableObject {
    @Published var history: [QA] = []
    @Published var busy = false
    let meetings = MeetingsModel()

    func ask(_ question: String) {
        let q = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty, !busy else { return }
        busy = true
        meetings.load()
        let sources = Retriever.search(q, in: meetings.items)
        Task {
            var answer: String
            if sources.isEmpty {
                answer = "I couldn't find anything about that in your recordings."
            } else if let ai = await Self.aiAnswer(q, sources) {
                answer = ai
            } else {
                answer = "Here are the moments that match. (Apple Intelligence isn't available, so I can't write an answer.)"
            }
            history.append(QA(question: q, answer: answer, sources: sources))
            busy = false
        }
    }

    private static func aiAnswer(_ q: String, _ sources: [Excerpt]) async -> String? {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), Summarizer.aiAvailable {
            var context = ""
            for (n, s) in sources.enumerated() {
                let part = "[\(n + 1)] \(s.item.date.formatted(date: .abbreviated, time: .omitted)): \(s.text)\n"
                if context.count + part.count > 3200 { break }
                context += part
            }
            let session = LanguageModelSession(instructions: "You answer questions using only the numbered excerpts from the user's own recordings. Cite excerpt numbers like [1]. If the excerpts do not contain the answer, say you could not find it. Never guess.")
            return try? await session.respond(to: "Excerpts:\n\(context)\nQuestion: \(q)").content
        }
        #endif
        return nil
    }
}

struct AskView: View {
    @StateObject private var model = AskModel()
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if model.history.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "sparkles").font(.largeTitle).foregroundStyle(Brand.pink)
                            Text("Ask anything about your recordings").font(.headline).foregroundStyle(Brand.ink)
                            Text("For example: “What did I decide about the lineout?” or “What were the deadlines in the lecture?”")
                                .font(.footnote).foregroundStyle(Brand.dim).multilineTextAlignment(.center)
                        }.frame(maxWidth: .infinity).padding(.top, 60)
                    }
                    ForEach(model.history) { qa in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(qa.question).font(.headline).foregroundStyle(Brand.pink)
                            Text(qa.answer).foregroundStyle(Brand.ink)
                            ForEach(Array(qa.sources.enumerated()), id: \.element.id) { n, s in
                                NavigationLink(destination: MeetingDetailView(item: s.item, startAt: s.time)) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("[\(n + 1)] \(s.item.date.formatted(date: .abbreviated, time: .shortened)) · \(stamp(s.time))")
                                            .font(.footnote.bold()).foregroundStyle(Brand.pink)
                                        Text(s.text).font(.footnote).foregroundStyle(Brand.dim).lineLimit(3)
                                            .multilineTextAlignment(.leading)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(10).background(Brand.panel, in: RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                    }
                    if model.busy { ProgressView("Searching your recordings…").frame(maxWidth: .infinity) }
                }
                .padding(16)
            }
            HStack {
                TextField("Ask a question…", text: $text, axis: .vertical)
                    .focused($focused).submitLabel(.send).onSubmit(send)
                    .padding(12).background(Brand.panel, in: RoundedRectangle(cornerRadius: 22))
                Button(action: send) {
                    Image(systemName: "arrow.up.circle.fill").font(.system(size: 36)).foregroundStyle(Brand.pink)
                }
            }
            .padding(12)
        }
        .background(Brand.bg.ignoresSafeArea())
        .navigationTitle("Ask Jeeves")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func send() { model.ask(text); text = "" }
    private func stamp(_ t: TimeInterval) -> String { String(format: "%d:%02d", Int(t) / 60, Int(t) % 60) }
}
