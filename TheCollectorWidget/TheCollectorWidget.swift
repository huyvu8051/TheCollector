import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), isRecording: false,responseMessage: "Hello world.")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let entry = SimpleEntry(date: Date(), isRecording: getRecordingStatus(), responseMessage: getResponseMessage())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        var entries: [SimpleEntry] = []
        let currentDate = Date()

        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, isRecording: getRecordingStatus(), responseMessage: getResponseMessage())
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    private func getRecordingStatus() -> Bool {
        let appGroupID = "group.com.huyvu.TheCollector"
        if let sharedDefaults = UserDefaults(suiteName: appGroupID) {
            return sharedDefaults.bool(forKey: "isRecording")
        }
        return false
    }
    
    private func getResponseMessage() -> String {
        let appGroupID = "group.com.huyvu.TheCollector"
        if let sharedDefaults = UserDefaults(suiteName: appGroupID) {
            return sharedDefaults.string(forKey: "responseMessage") ?? ""
        }
        return ""
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let isRecording: Bool
    let responseMessage: String
}

struct TheCollectorWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Text("\(entry.isRecording ? "🔴" : "⭕️") \(entry.responseMessage)")
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

@main
struct TheCollectorWidget: Widget {
    let kind: String = "TheCollectorWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TheCollectorWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("The Collector Widget")
        .description("Shows the recording status.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct TheCollectorWidget_Previews: PreviewProvider {
    static var previews: some View {
        TheCollectorWidgetEntryView(entry: SimpleEntry(date: Date(), isRecording: false, responseMessage: "Hello world."))
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
    }
}
