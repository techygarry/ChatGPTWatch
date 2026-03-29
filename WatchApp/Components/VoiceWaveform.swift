import SwiftUI

struct VoiceWaveform: View {
    let levels: [CGFloat]
    var color: Color = DesignTokens.Colors.chatGPTGreen
    var barWidth: CGFloat = 3
    var barSpacing: CGFloat = 2
    var maxHeight: CGFloat = 30

    var body: some View {
        HStack(spacing: barSpacing) {
            ForEach(Array(levels.enumerated()), id: \.offset) { _, level in
                RoundedRectangle(cornerRadius: barWidth / 2)
                    .fill(color)
                    .frame(width: barWidth, height: max(4, level * maxHeight))
            }
        }
        .frame(height: maxHeight)
    }
}
