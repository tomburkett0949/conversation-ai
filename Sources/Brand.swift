import SwiftUI

/// Central branding. Rename the product or change colours here (mirrors config/brand.config.json).
enum Brand {
    static let productName = "Conversation AI"
    static let tagline = "Your private memory for conversations"

    static let bg = Color(hex: 0x0A0A0C)
    static let panel = Color(hex: 0x141418)
    static let panel2 = Color(hex: 0x1B1B21)
    static let line = Color(hex: 0x2A2A31)
    static let ink = Color(hex: 0xF2F2F4)
    static let dim = Color(hex: 0xA3A3AD)
    static let pink = Color(hex: 0xFF9AF6)
    static let hot = Color(hex: 0xE6189C)
    static let danger = Color(hex: 0xFF5A5A)
    static let gradient = LinearGradient(colors: [Color(hex: 0xFF3DB8), Color(hex: 0xB01178)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing)

    static func display(_ size: CGFloat) -> Font { .custom("BebasNeue-Regular", size: size) }
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }
}
