import Foundation
import EventKit
import FoundationModels
import UserNotifications

let store = EKEventStore()

struct TimeTool: Tool {
    let name = "currentTime"; let description = "Current date and time anywhere in the world. ALWAYS use this for any question about the time or date, in any city or country."
    @Generable struct Arguments {
        @Guide(description: "City, region or country, e.g. New York, Tokyo, Sydney. Leave empty for Tom's own location.") var place: String
    }
    static let aliases: [String: String] = [
        "new york": "America/New_York", "nyc": "America/New_York", "usa": "America/New_York", "united states": "America/New_York", "america": "America/New_York",
        "los angeles": "America/Los_Angeles", "la": "America/Los_Angeles", "california": "America/Los_Angeles", "san francisco": "America/Los_Angeles",
        "texas": "America/Chicago", "florida": "America/New_York", "canada": "America/Toronto",
        "uk": "Europe/London", "england": "Europe/London", "britain": "Europe/London", "london": "Europe/London", "scotland": "Europe/London", "wales": "Europe/London",
        "france": "Europe/Paris", "germany": "Europe/Berlin", "spain": "Europe/Madrid", "italy": "Europe/Rome", "ireland": "Europe/Dublin",
        "japan": "Asia/Tokyo", "china": "Asia/Shanghai", "india": "Asia/Kolkata", "dubai": "Asia/Dubai", "uae": "Asia/Dubai", "singapore": "Asia/Singapore",
        "australia": "Australia/Sydney", "new zealand": "Pacific/Auckland", "south africa": "Africa/Johannesburg", "fiji": "Pacific/Fiji",
        "argentina": "America/Argentina/Buenos_Aires", "brazil": "America/Sao_Paulo", "mexico": "America/Mexico_City", "hong kong": "Asia/Hong_Kong", "korea": "Asia/Seoul",
    ]
    static func zone(_ place: String) -> TimeZone? {
        let q = place.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty { return .current }
        if let id = aliases[q], let z = TimeZone(identifier: id) { return z }
        let ids = TimeZone.knownTimeZoneIdentifiers
        let hit = ids.first { ($0.split(separator: "/").last.map { $0.replacingOccurrences(of: "_", with: " ").lowercased() }) == q }
            ?? ids.first { $0.replacingOccurrences(of: "_", with: " ").lowercased().contains(q) }
        return hit.flatMap { TimeZone(identifier: $0) }
    }
    func call(arguments a: Arguments) async throws -> String {
        guard let z = Self.zone(a.place) else { return "I don't know the time zone for \(a.place)." }
        let f = DateFormatter(); f.dateFormat = "EEEE d MMMM yyyy, HH:mm"; f.locale = Locale(identifier: "en_GB"); f.timeZone = z
        let where_ = a.place.trimmingCharacters(in: .whitespaces).isEmpty ? "here" : a.place
        return "In \(where_) it is \(f.string(from: .now)) (\(z.identifier))."
    }
}

struct DiaryTool: Tool {
    let name = "diary"; let description = "Read Tom's diary events for the next N days (calendar of the phone, including iCloud)."
    @Generable struct Arguments { @Guide(description: "How many days ahead, 1 to 31") var days: Int }
    func call(arguments: Arguments) async throws -> String {
        guard (try? await store.requestFullAccessToEvents()) == true else { return "Calendar access has not been allowed." }
        let end = Calendar.current.date(byAdding: .day, value: max(1, min(31, arguments.days)), to: .now)!
        let evs = store.events(matching: store.predicateForEvents(withStart: Calendar.current.startOfDay(for: .now), end: end, calendars: nil)).sorted { $0.startDate < $1.startDate }
        if evs.isEmpty { return "Nothing in the diary for that period." }
        let f = DateFormatter(); f.dateFormat = "EEE d MMM HH:mm"; f.locale = Locale(identifier: "en_GB")
        return evs.prefix(25).map { "\(f.string(from: $0.startDate)): \($0.title ?? "Untitled")" }.joined(separator: "\n")
    }
}

struct AddDiaryTool: Tool {
    let name = "addDiaryEntry"; let description = "Add an event to Tom's diary. Only call after Tom has clearly asked for it."
    @Generable struct Arguments {
        @Guide(description: "Event title") var title: String
        @Guide(description: "Start date and time as ISO 8601, e.g. 2026-11-02T18:30:00") var start: String
        @Guide(description: "Length in minutes") var minutes: Int
    }
    func call(arguments a: Arguments) async throws -> String {
        guard (try? await store.requestFullAccessToEvents()) == true else { return "Calendar access has not been allowed." }
        let f = DateFormatter(); f.locale = Locale(identifier: "en_GB_POSIX"); f.timeZone = .current; f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        guard let d = f.date(from: String(a.start.prefix(19))) else { return "I could not read that date." }
        let e = EKEvent(eventStore: store); e.title = a.title; e.startDate = d; e.endDate = d.addingTimeInterval(Double(max(5, a.minutes)) * 60)
        e.calendar = store.defaultCalendarForNewEvents
        try store.save(e, span: .thisEvent); return "Added \(a.title)."
    }
}

struct ReminderTool: Tool {
    let name = "remindMe"; let description = "Set a reminder or timer that notifies Tom after a number of minutes."
    @Generable struct Arguments {
        @Guide(description: "What to remind Tom about") var text: String
        @Guide(description: "Minutes from now") var minutes: Int
    }
    func call(arguments a: Arguments) async throws -> String {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        let c = UNMutableNotificationContent(); c.title = "Jeeves"; c.body = a.text; c.sound = .default
        let t = UNTimeIntervalNotificationTrigger(timeInterval: Double(max(1, a.minutes)) * 60, repeats: false)
        try await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: UUID().uuidString, content: c, trigger: t))
        return "Reminder set for \(a.minutes) minutes."
    }
}
