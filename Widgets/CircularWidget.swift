import WidgetKit
import SwiftUI

struct ChatGPTCircularWidget: Widget {
    let kind = "ChatGPTCircular"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CircularProvider()) { entry in
            CircularWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("ChatGPT")
        .description("Quick access to ChatGPT")
        .supportedFamilies([.accessoryCircular])
    }
}

struct CircularProvider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let entry = SimpleEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(900)))
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct CircularWidgetView: View {
    let entry: SimpleEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Image(systemName: "brain.head.profile.fill")
                .font(.system(size: 20))
                .foregroundStyle(.green)
        }
        .widgetURL(URL(string: "chatgptwatch://newchat"))
    }
}
