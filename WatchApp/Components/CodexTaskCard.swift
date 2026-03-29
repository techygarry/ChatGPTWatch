import SwiftUI

struct CodexTaskCard: View {
    let session: CodexSession

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text(session.input.firstLine.truncated(to: 30))
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
                .lineLimit(1)

            HStack(spacing: DesignTokens.Spacing.sm) {
                StatusBadge(status: session.status)

                Spacer()

                Text(session.createdAt.relativeString)
                    .font(DesignTokens.Typography.timestamp)
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }

            if !session.filesChanged.isEmpty {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(DesignTokens.Colors.codexPurple.opacity(0.7))
                    Text("\(session.filesChanged.count) file\(session.filesChanged.count == 1 ? "" : "s") changed")
                        .font(DesignTokens.Typography.micro)
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                }
            }
        }
        .padding(.vertical, DesignTokens.Spacing.xs)
    }
}
