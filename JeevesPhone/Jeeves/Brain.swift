import Foundation
import FoundationModels

/// The on-phone brain: Apple's on-device language model. Free, private, works offline. Needs an Apple Intelligence iPhone.
@MainActor final class Brain: ObservableObject {
    private var session: LanguageModelSession?
    var status: String {
        switch SystemLanguageModel.default.availability {
        case .available: return ""
        case .unavailable(let why): return "Apple's on-device model isn't available (\(why)). Needs an Apple Intelligence iPhone with it switched on in Settings."
        }
    }
    func ask(_ text: String) async -> String {
        if !status.isEmpty { return status }
        if session == nil {
            session = LanguageModelSession(tools: [TimeTool(), DiaryTool(), AddDiaryTool(), ReminderTool()],
                instructions: "You are Jeeves, a dry, courteous British butler and personal assistant to Tom. Reply in one or two short spoken sentences, no lists or markdown. Use the tools for the time, the diary and reminders. Never claim to have done something unless a tool confirmed it. If asked for something you cannot do on a phone, say so plainly.")
        }
        do { return try await session!.respond(to: text).content }
        catch { session = nil; return "My apologies, Tom, I could not manage that one." }
    }
}
