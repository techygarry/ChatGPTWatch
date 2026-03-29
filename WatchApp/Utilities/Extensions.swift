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
                    ? AnyShapeStyle(DesignTokens.Colors.chatGPTGreen.opacity(0.25))
                    : AnyShapeStyle(.ultraThinMaterial)
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium, style: .continuous))
    }

    func cardStyle() -> some View {
        self
            .padding(DesignTokens.Spacing.md)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium, style: .continuous))
    }

    func glassCard() -> some View {
        cardStyle()
    }
}
