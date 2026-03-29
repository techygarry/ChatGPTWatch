import SwiftUI

enum DesignTokens {

    // MARK: - Colors
    enum Colors {
        // Brand
        static let chatGPTGreen = Color(red: 0.063, green: 0.639, blue: 0.498)
        static let chatGPTGreenLight = Color(red: 0.130, green: 0.800, blue: 0.620)
        static let codexPurple = Color(red: 0.600, green: 0.340, blue: 1.0)
        static let codexPurpleLight = Color(red: 0.720, green: 0.500, blue: 1.0)
        static let codexBlue = Color(red: 0.200, green: 0.600, blue: 1.0)

        // Semantic
        static let errorRed = Color(red: 1.0, green: 0.310, blue: 0.310)
        static let successGreen = Color(red: 0.180, green: 0.820, blue: 0.540)
        static let warningAmber = Color(red: 1.0, green: 0.720, blue: 0.220)

        // Text
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
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
    }

    // MARK: - Typography
    enum Typography {
        static let largeTitle: Font = .system(size: 20, weight: .bold, design: .rounded)
        static let headline: Font = .system(size: 17, weight: .bold, design: .rounded)
        static let sectionHeader: Font = .system(size: 15, weight: .semibold, design: .rounded)
        static let body: Font = .system(size: 13, weight: .regular)
        static let bodyMedium: Font = .system(size: 13, weight: .medium)
        static let caption: Font = .system(size: 11, weight: .medium)
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
        static let small: CGFloat = 10
        static let medium: CGFloat = 14
        static let large: CGFloat = 18
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
