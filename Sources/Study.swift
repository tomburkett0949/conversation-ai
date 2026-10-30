import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

struct Flashcard: Codable, Identifiable {
    var id = UUID()
    var question: String
    var answer: String
}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
@Generable
struct GeneratedCard {
    @Guide(description: "A clear study question about one fact or idea in the transcript")
    var question: String
    @Guide(description: "A short, accurate answer taken from the transcript")
    var answer: String
}

@available(iOS 26.0, *)
@Generable
struct GeneratedCards {
    @Guide(description: "Between 6 and 10 flashcards", .count(8))
    var cards: [GeneratedCard]
}
#endif

enum StudyMaker {
    static func make(_ lines: [TranscriptLine]) async -> [Flashcard]? {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), Summarizer.aiAvailable {
            var text = lines.map { $0.text }.joined(separator: "\n")
            if text.count > 5000 {
                // Spread the sample across the whole recording rather than just the start.
                let step = text.count / 5000 + 1
                text = lines.enumerated().filter { $0.offset % step == 0 }.map { $0.element.text }.joined(separator: "\n")
                text = String(text.prefix(5000))
            }
            let session = LanguageModelSession(instructions: "You make flashcards for a student from a lecture or coaching session transcript. Use only facts stated in the transcript. Never invent anything.")
            if let r = try? await session.respond(to: "Make flashcards from this transcript:\n\(text)", generating: GeneratedCards.self) {
                return r.content.cards.map { Flashcard(question: $0.question, answer: $0.answer) }
            }
        }
        #endif
        return nil
    }
}
