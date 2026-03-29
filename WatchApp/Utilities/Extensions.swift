import SwiftUI

// MARK: - Date Formatting
extension Date {
    var relativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    var shortTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

// MARK: - String Helpers
extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func truncated(to length: Int) -> String {
        if count <= length { return self }
        return String(prefix(length)) + "..."
    }

    var firstLine: String {
        components(separatedBy: .newlines).first ?? self
    }
}

// MARK: - View Modifiers
extension View {
    func chatBubbleStyle(isUser: Bool) -> some View {
        self
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(
                isUser
                    ? AnyShapeStyle(DesignTokens.Gradients.greenAccent)
                    : AnyShapeStyle(DesignTokens.Colors.assistantBg)
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium, style: .continuous))
    }

    func glassCard() -> some View {
        self
            .padding(DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.surfaceMid)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.medium, style: .continuous)
                    .strokeBorder(DesignTokens.Colors.glassStroke, lineWidth: 0.5)
            )
    }

    func cardStyle() -> some View {
        glassCard()
    }

    func accentGlow(color: Color, radius: CGFloat = 8) -> some View {
        self.shadow(color: color.opacity(0.3), radius: radius, y: 2)
    }
}
