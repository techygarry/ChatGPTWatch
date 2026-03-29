import WidgetKit
import SwiftUI

struct ChatGPTRectangularWidget: Widget {
    let kind = "ChatGPTRectangular"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RectangularProvider()) { entry in
            RectangularWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("ChatGPT")
        .description("ChatGPT and Codex status")
        .supportedFamilies([.accessoryRectangular])
    }
}

struct RectangularProvider: TimelineProvider {
    func placeholder(in context: Context) -> RectEntry {
        RectEntry(date: Date(), hasAPIKey: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (RectEntry) -> Void) {
        let hasKey = KeychainService.shared.load(key: KeychainKeys.openAIAPIKey) != nil
        completion(RectEntry(date: Date(), hasAPIKey: hasKey))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RectEntry>) -> Void) {
        let hasKey = KeychainService.shared.load(key: KeychainKeys.openAIAPIKey) != nil
        let entry = RectEntry(date: Date(), hasAPIKey: hasKey)
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(900)))
        completion(timeline)
    }
}

struct RectEntry: TimelineEntry {
    let date: Date
    let hasAPIKey: Bool
}

struct RectangularWidgetView: View {
    let entry: RectEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "brain.head.profile.fill")
                    .font(.caption2)
                    .foregroundStyle(.green)
                Text("ChatGPT")
                    .font(.system(size: 13, weight: .semibold))
            }

            if entry.hasAPIKey {
                Text("Tap to start chatting")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    Label("Chat", systemImage: "bubble.fill")
                        .font(.system(size: 10))
                    Label("Codex", systemImage: "chevron.left.forwardslash.chevron.right")
                        .font(.system(size: 10))
                }
                .foregroundStyle(.secondary)
            } else {
                Text("API key needed")
                    .font(.system(size: 11))
                    .foregroundStyle(.orange)
                Text("Open app to configure")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .widgetURL(URL(string: "chatgptwatch://newchat"))
    }
}
