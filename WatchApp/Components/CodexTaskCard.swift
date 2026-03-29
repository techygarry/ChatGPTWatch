import SwiftUI

struct CodexTaskCard: View {
    let session: CodexSession

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text(session.input.firstLine.truncated(to: 30))
                .font(DesignTokens.Typography.bodyMedium)
                .lineLimit(1)

            HStack(spacing: DesignTokens.Spacing.sm) {
                StatusBadge(status: session.status)
                Spacer()
                Text(session.createdAt.relativeString)
                    .font(DesignTokens.Typography.timestamp)
                    .foregroundStyle(.tertiary)
            }

            if !session.filesChanged.isEmpty {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(DesignTokens.Colors.codexPurple.opacity(0.6))
                    Text("\(session.filesChanged.count) file\(session.filesChanged.count == 1 ? "" : "s") changed")
                        .font(DesignTokens.Typography.micro)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(DesignTokens.Spacing.md)
        .glassEffect(.regular, in: .rect(cornerRadius: DesignTokens.Radius.medium))
    }
}
