import SwiftUI

struct StatusBadge: View {
    let status: CodexStatus

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            if status == .inProgress {
                ProgressView()
                    .scaleEffect(0.4)
                    .frame(width: 10, height: 10)
                    .tint(statusColor)
            } else {
                Circle()
                    .fill(statusColor)
                    .frame(width: 6, height: 6)
            }

            Text(status.displayName)
                .font(DesignTokens.Typography.micro)
                .foregroundStyle(statusColor)
        }
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .padding(.vertical, 3)
        .background(statusColor.opacity(0.15))
        .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch status {
        case .queued: DesignTokens.Colors.textSecondary
        case .inProgress: DesignTokens.Colors.codexBlue
        case .completed: DesignTokens.Colors.successGreen
        case .failed: DesignTokens.Colors.errorRed
        case .cancelled: DesignTokens.Colors.warningAmber
        }
    }
}
