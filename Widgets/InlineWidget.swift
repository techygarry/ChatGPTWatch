import WidgetKit
import SwiftUI

struct ChatGPTInlineWidget: Widget {
    let kind = "ChatGPTInline"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: InlineProvider()) { entry in
            InlineWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("ChatGPT Inline")
        .description("Quick ChatGPT access")
        .supportedFamilies([.accessoryInline])
    }
}

struct InlineProvider: TimelineProvider {
    func placeholder(in context: Context) -> InlineEntry {
        InlineEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (InlineEntry) -> Void) {
        completion(InlineEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<InlineEntry>) -> Void) {
        let entry = InlineEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(900)))
        completion(timeline)
    }
}

struct InlineEntry: TimelineEntry {
    let date: Date
}

struct InlineWidgetView: View {
    let entry: InlineEntry

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "brain.head.profile.fill")
            Text("Ask ChatGPT")
        }
        .widgetURL(URL(string: "chatgptwatch://newchat"))
    }
}
