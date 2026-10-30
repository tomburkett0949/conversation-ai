import SwiftUI

@main
struct ConversationAIApp: App {
    @AppStorage("appearance") private var appearance = "system"

    private var scheme: ColorScheme? {
        switch appearance {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack { HomeView() }
                .preferredColorScheme(scheme)
                .tint(Brand.pink)
        }
    }
}
