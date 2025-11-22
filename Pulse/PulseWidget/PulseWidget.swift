import SwiftUI
import WidgetKit

struct PulseWidget: Widget {
    let kind: String = "PulseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PulseTimelineProvider()) { entry in
            PulseWidgetEntryView(entry: entry)
                .containerBackground(.thinMaterial, for: .widget)
        }
        .configurationDisplayName("Pulse")
        .description("Quick access to check-ins and group status")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct PulseWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: PulseTimelineEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

#Preview(as: .systemMedium) {
    PulseWidget()
} timeline: {
    PulseTimelineEntry.preview()
}
