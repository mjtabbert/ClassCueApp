//
//  Class_Cue.swift
//  Class Cue
//
//  Created by Mike Tabbert on 3/11/26.
//

import WidgetKit
import SwiftUI

struct ClassCueHomeEntry: TimelineEntry {
    let date: Date
}

struct ClassCueHomeProvider: TimelineProvider {
    func placeholder(in context: Context) -> ClassCueHomeEntry {
        ClassCueHomeEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (ClassCueHomeEntry) -> Void) {
        completion(ClassCueHomeEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ClassCueHomeEntry>) -> Void) {
        let currentDate = Date()
        let entries = (0..<6).compactMap { minuteOffset in
            Calendar.current.date(byAdding: .minute, value: minuteOffset * 30, to: currentDate)
                .map { ClassCueHomeEntry(date: $0) }
        }

        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct ClassCueHomeEntryView: View {
    let entry: ClassCueHomeEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "clock.badge.checkmark.fill")
                    .foregroundStyle(.orange)

                Text("ClassCue")
                    .font(.headline.weight(.bold))

                Spacer()
            }

            Text("Teacher Day")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(entry.date, style: .time)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .monospacedDigit()

            Text("Open the app for today's block, tasks, and commitments.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct Class_Cue: Widget {
    let kind: String = "ClassCueHomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ClassCueHomeProvider()) { entry in
            ClassCueHomeEntryView(entry: entry)
        }
        .configurationDisplayName("ClassCue")
        .description("Quick access to your teacher day dashboard.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    Class_Cue()
} timeline: {
    ClassCueHomeEntry(date: .now)
}
