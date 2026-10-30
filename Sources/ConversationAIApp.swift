import SwiftUI

@main
struct ConversationAIApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack { HomeView() }
                .preferredColorScheme(.dark)
                .tint(Brand.pink)
        }
    }
}
