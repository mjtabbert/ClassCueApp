//
//  NextUpSummaryCard.swift
//  ClassCue
//
//  Developer: Mr. Mike
//  Last Updated: March 11, 2026
//  Build: ClassCue Dev Build 23
//

import SwiftUI

struct NextUpSummaryCard: View {

    let item: AlarmItem
    let now: Date
    var isCompact: Bool = false

    var body: some View {

        HStack(alignment: .top, spacing: 14) {

            VStack(alignment: .leading, spacing: 8) {

                HStack(spacing: 8) {
                    Text("NEXT UP")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.blue)

                    TypeBadge(type: item.type)
                }

                Text(item.className)
                    .font(isCompact ? .subheadline : .headline)
                    .fontWeight(.bold)
                    .lineLimit(1)

                Text(timeRangeText)
                    .font((isCompact ? Font.footnote : .subheadline).weight(.semibold))
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                if !item.location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(item.location)
                        .font(isCompact ? .caption : .footnote)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 12)

            Text(timeText)
                .font((isCompact ? Font.headline : .title3).weight(.bold))
                .monospacedDigit()
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.systemGray6))
        )
    }

    // MARK: - Timing

    private var start: Date {
        anchoredTime(for: item.startTime) ?? item.startTime
    }

    private var end: Date {
        anchoredEndTime
    }

    private var timeText: String {

        let totalSeconds = max(Int(start.timeIntervalSince(now)), 0)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private var timeRangeText: String {
        "\(start.formatted(date: .omitted, time: .shortened)) - \(end.formatted(date: .omitted, time: .shortened))"
    }

    private var anchoredEndTime: Date {
        guard let anchoredEnd = anchoredTime(for: item.endTime) else {
            return item.endTime
        }

        if anchoredEnd >= start {
            return anchoredEnd
        }

        return Calendar.current.date(byAdding: .day, value: 1, to: anchoredEnd) ?? anchoredEnd
    }

    private func anchoredTime(for date: Date) -> Date? {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return Calendar.current.date(
            bySettingHour: components.hour ?? 0,
            minute: components.minute ?? 0,
            second: 0,
            of: now
        )
    }
}
