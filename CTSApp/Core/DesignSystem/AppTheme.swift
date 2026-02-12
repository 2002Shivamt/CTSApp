import SwiftUI

enum ThemeVariant {
    case legacy
    case packA
    case packB
    case packC
}

enum ThemeSettings {
    /// Single switch to revert visual theme quickly.
    static var active: ThemeVariant = .packB
    
}

struct ThemeTokens {
    let appBackgroundStart: Color
    let appBackgroundEnd: Color

    let textPrimary: Color
    let textSecondary: Color
    let textMuted: Color

    let surfacePrimary: Color
    let borderSubtle: Color

    let brandPrimary: Color
    let brandSecondary: Color
    let primaryButtonText: Color

    let socialGoogleBackground: Color
    let socialGoogleBorder: Color
    let socialGoogleText: Color
    let socialAppleBackground: Color
    let socialAppleText: Color
}

enum AppTheme {
    static var current: ThemeTokens {
        switch ThemeSettings.active {
        case .legacy:
            return ThemeTokens(
                appBackgroundStart: Color.black,
                appBackgroundEnd: Color(red: 0.08, green: 0.08, blue: 0.14),
                textPrimary: .primary,
                textSecondary: .secondary,
                textMuted: .secondary,
                surfacePrimary: Color.white.opacity(0.06),
                borderSubtle: Color(UIColor.quaternaryLabel),
                brandPrimary: .blue,
                brandSecondary: .purple,
                primaryButtonText: .white,
                socialGoogleBackground: .white,
                socialGoogleBorder: Color(red: 0.57, green: 0.64, blue: 0.75),
                socialGoogleText: Color(red: 0.12, green: 0.20, blue: 0.37),
                socialAppleBackground: .black,
                socialAppleText: .white
            )

        case .packA:
            return ThemeTokens(
                appBackgroundStart: Color(hex: "0D101A"),
                appBackgroundEnd: Color(hex: "171E34"),
                textPrimary: Color(hex: "F5F7FF"),
                textSecondary: Color(hex: "A8B1CC"),
                textMuted: Color(hex: "7F89A8"),
                surfacePrimary: Color(hex: "1A2033").opacity(0.9),
                borderSubtle: Color(hex: "2E3752"),
                brandPrimary: Color(hex: "7C3BFF"),
                brandSecondary: Color(hex: "4D7CFE"),
                primaryButtonText: .white,
                socialGoogleBackground: .white,
                socialGoogleBorder: Color(hex: "8FA3BF"),
                socialGoogleText: Color(hex: "1B2D52"),
                socialAppleBackground: .black,
                socialAppleText: .white
            )

        case .packB:
            return ThemeTokens(
                appBackgroundStart: Color(hex: "F6F8FC"),
                appBackgroundEnd: Color(hex: "EEF2F9"),
                textPrimary: Color(hex: "1B2436"),
                textSecondary: Color(hex: "4E5A76"),
                textMuted: Color(hex: "7C87A3"),
                surfacePrimary: Color(hex: "FFFFFF"),
                borderSubtle: Color(hex: "D8DFEC"),
                brandPrimary: Color(hex: "6E38F7"),
                brandSecondary: Color(hex: "3B82F6"),
                primaryButtonText: .white,
                socialGoogleBackground: .white,
                socialGoogleBorder: Color(hex: "C9D5EA"),
                socialGoogleText: Color(hex: "1F335A"),
                socialAppleBackground: .black,
                socialAppleText: .white
            )

        case .packC:
            return ThemeTokens(
                appBackgroundStart: Color(hex: "0B0F1A"),
                appBackgroundEnd: Color(hex: "1A1F3A"),
                textPrimary: Color(hex: "F7FAFF"),
                textSecondary: Color(hex: "C5D0EA"),
                textMuted: Color(hex: "92A0C2"),
                surfacePrimary: Color(hex: "FFFFFF1A"),
                borderSubtle: Color(hex: "FFFFFF33"),
                brandPrimary: Color(hex: "8B5CF6"),
                brandSecondary: Color(hex: "3B82F6"),
                primaryButtonText: .white,
                socialGoogleBackground: .white,
                socialGoogleBorder: Color(hex: "93A7D0"),
                socialGoogleText: Color(hex: "1D3158"),
                socialAppleBackground: .black,
                socialAppleText: .white
            )
        }
    }
}

struct ThemedScreen<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.current.appBackgroundStart, AppTheme.current.appBackgroundEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            content
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 255, 255, 255)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

