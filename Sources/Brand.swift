import SwiftUI

/// Central branding. Rename the product or change colours here (mirrors config/brand.config.json).
enum Brand {
    static let productName = "Conversation AI"
    static let tagline = "Your private memory for conversations"

    // Adaptive colours: (light, dark). Follows the Appearance setting.
    static let bg = Color(light: 0xF6F5F8, dark: 0x0A0A0C)
    static let panel = Color(light: 0xFFFFFF, dark: 0x141418)
    static let panel2 = Color(light: 0xEEECF1, dark: 0x1B1B21)
    static let line = Color(light: 0xDAD8E0, dark: 0x2A2A31)
    static let ink = Color(light: 0x17161A, dark: 0xF2F2F4)
    static let dim = Color(light: 0x6B6A75, dark: 0xA3A3AD)
    static let pink = Color(light: 0xD6168F, dark: 0xFF9AF6)
    static let hot = Color(light: 0xE6189C, dark: 0xE6189C)
    static let danger = Color(light: 0xD93636, dark: 0xFF5A5A)
    static let gradient = LinearGradient(colors: [Color(hex: 0xFF3DB8), Color(hex: 0xB01178)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing)

    static func display(_ size: CGFloat) -> Font { .custom("BebasNeue-Regular", size: size) }
}

extension Color {
    init(light: UInt32, dark: UInt32) {
        self.init(UIColor { trait in
            let h = trait.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((h >> 16) & 0xFF) / 255, green: CGFloat((h >> 8) & 0xFF) / 255,
                           blue: CGFloat(h & 0xFF) / 255, alpha: 1)
        })
    }
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }
}
