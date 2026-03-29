import SwiftUI

enum DesignTokens {

    // MARK: - Colors (Premium ChatGPT palette)
    enum Colors {
        // Primary brand
        static let chatGPTGreen = Color(red: 0.063, green: 0.639, blue: 0.498)  // #10A37F
        static let chatGPTGreenLight = Color(red: 0.110, green: 0.780, blue: 0.610)
        static let chatGPTGreenDark = Color(red: 0.040, green: 0.480, blue: 0.370)

        // Surfaces — deeper, richer darks
        static let surfaceDark = Color(red: 0.067, green: 0.071, blue: 0.082)     // near-black
        static let surfaceMid = Color(red: 0.102, green: 0.106, blue: 0.125)      // cards
        static let surfaceChat = Color(red: 0.137, green: 0.141, blue: 0.169)     // elevated
        static let surfaceElevated = Color(red: 0.173, green: 0.180, blue: 0.216) // popovers

        // Bubbles
        static let userBubble = Color(red: 0.063, green: 0.639, blue: 0.498)      // green user
        static let assistantBg = Color(red: 0.137, green: 0.141, blue: 0.169)     // subtle dark

        // Codex accent
        static let codexPurple = Color(red: 0.600, green: 0.340, blue: 1.0)       // #9957FF
        static let codexPurpleLight = Color(red: 0.720, green: 0.500, blue: 1.0)
        static let codexBlue = Color(red: 0.200, green: 0.600, blue: 1.0)         // vivid blue

        // Text
        static let textPrimary = Color.white
        static let textSecondary = Color(red: 0.520, green: 0.530, blue: 0.600)
        static let textTertiary = Color(red: 0.360, green: 0.370, blue: 0.430)

        // Semantic
        static let errorRed = Color(red: 1.0, green: 0.310, blue: 0.310)          // #FF4F4F
        static let successGreen = Color(red: 0.180, green: 0.820, blue: 0.540)    // #2ED189
        static let warningAmber = Color(red: 1.0, green: 0.720, blue: 0.220)      // #FFB838

        // Glass & borders
        static let border = Color.white.opacity(0.08)
        static let glassStroke = Color.white.opacity(0.12)
        static let glassFill = Color.white.opacity(0.05)
    }

    // MARK: - Gradients
    enum Gradients {
        static let greenAccent = LinearGradient(
            colors: [Colors.chatGPTGreen, Colors.chatGPTGreenLight],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        static let purpleAccent = LinearGradient(
            colors: [Colors.codexPurple, Colors.codexPurpleLight],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        static let surfaceGlow = LinearGradient(
            colors: [Colors.surfaceMid, Colors.surfaceDark],
            startPoint: .top, endPoint: .bottom
        )
        static let heroGreen = LinearGradient(
            colors: [
                Colors.chatGPTGreen.opacity(0.25),
                Colors.surfaceDark.opacity(0.0)
            ],
            startPoint: .top, endPoint: .bottom
        )
        static let heroPurple = LinearGradient(
            colors: [
                Colors.codexPurple.opacity(0.20),
                Colors.surfaceDark.opacity(0.0)
            ],
            startPoint: .top, endPoint: .bottom
        )
    }

    // MARK: - Typography
    enum Typography {
        static let headline: Font = .system(size: 17, weight: .bold, design: .rounded)
        static let sectionHeader: Font = .system(size: 15, weight: .semibold, design: .rounded)
        static let body: Font = .system(size: 13, weight: .regular)
        static let bodyMedium: Font = .system(size: 13, weight: .medium)
        static let caption: Font = .system(size: 11, weight: .medium)
        static let captionLight: Font = .system(size: 11, weight: .regular)
        static let timestamp: Font = .system(size: 10, weight: .light)
        static let code: Font = .system(size: 11, weight: .regular, design: .monospaced)
        static let micro: Font = .system(size: 9, weight: .medium)
    }

    // MARK: - Spacing
    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }

    // MARK: - Corner Radius
    enum Radius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let pill: CGFloat = 50
    }

    // MARK: - Animation
    enum Animation {
        static let quick = SwiftUI.Animation.easeOut(duration: 0.15)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.25)
        static let spring = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.72)
        static let bouncy = SwiftUI.Animation.spring(response: 0.45, dampingFraction: 0.65)
        static let streaming = SwiftUI.Animation.easeIn(duration: 0.03)
        static let glow = SwiftUI.Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)
    }
}
