import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

struct MeetingSummary: Codable {
    var overview: String
    var keyPoints: [String]
    var actions: [String]
    var decisions: [String]
    var onDeviceAI: Bool
}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
@Generable
struct GeneratedSummary {
    @Guide(description: "Two or three sentence overview of the conversation")
    var overview: String
    @Guide(description: "The most important points, short bullets")
    var keyPoints: [String]
    @Guide(description: "Tasks someone agreed or needs to do, each starting with a verb. Empty if none.")
    var actions: [String]
    @Guide(description: "Decisions that were made. Empty if none.")
    var decisions: [String]
}
#endif

enum Summarizer {
    static var aiAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            if case .available = SystemLanguageModel.default.availability { return true }
        }
        #endif
        return false
    }

    static func summarize(_ lines: [TranscriptLine]) async -> MeetingSummary? {
        let text = lines.map { $0.text }.joined(separator: "\n")
        guard text.count > 40 else { return nil }
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), aiAvailable {
            if let s = try? await aiSummary(text) { return s }
        }
        #endif
        return basicSummary(lines)
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private static func aiSummary(_ text: String) async throws -> MeetingSummary {
        // The on-device model has a small context window, so long transcripts are condensed in chunks first.
        var material = text
        if text.count > 5000 {
            var parts: [String] = []
            for chunk in chunks(text, size: 5000) {
                let session = LanguageModelSession(instructions: "You condense transcript excerpts. Keep every task, decision, name, date and number.")
                let r = try await session.respond(to: "Condense this transcript excerpt to under 120 words:\n\(chunk)")
                parts.append(r.content)
            }
            material = parts.joined(separator: "\n")
            if material.count > 5000 { material = String(material.prefix(5000)) }
        }
        let session = LanguageModelSession(instructions: "You write accurate notes for a UK English speaker. Use only what is in the transcript. Never invent anything.")
        let r = try await session.respond(to: "Summarise this transcript:\n\(material)", generating: GeneratedSummary.self)
        let g = r.content
        return MeetingSummary(overview: g.overview, keyPoints: g.keyPoints, actions: g.actions, decisions: g.decisions, onDeviceAI: true)
    }
    #endif

    private static func chunks(_ s: String, size: Int) -> [String] {
        var out: [String] = []; var cur = ""
        for line in s.split(separator: "\n") {
            if cur.count + line.count > size, !cur.isEmpty { out.append(cur); cur = "" }
            cur += line + "\n"
        }
        if !cur.isEmpty { out.append(cur) }
        return out
    }

    /// Fallback when Apple Intelligence is unavailable: simple keyword-based extraction.
    private static func basicSummary(_ lines: [TranscriptLine]) -> MeetingSummary {
        let sentences = lines.flatMap { $0.text.components(separatedBy: CharacterSet(charactersIn: ".?!")) }
            .map { $0.trimmingCharacters(in: .whitespaces) }.filter { $0.count > 15 }
        func pick(_ words: [String]) -> [String] {
            Array(sentences.filter { s in words.contains { s.lowercased().contains($0) } }.prefix(8))
        }
        return MeetingSummary(
            overview: sentences.prefix(3).joined(separator: ". ") + ".",
            keyPoints: Array(sentences.sorted { $0.count > $1.count }.prefix(5)),
            actions: pick(["need to", "i will", "we will", "i'll", "should", "follow up", "deadline", "by friday", "by monday", "remind"]),
            decisions: pick(["decided", "agreed", "we'll go with", "the plan is"]),
            onDeviceAI: false)
    }
}
