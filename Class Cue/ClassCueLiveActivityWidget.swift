//
//  ClassCueLiveActivityWidget.swift
//  ClassCue
//
//  Developer: Mr. Mike
//  Last Updated: March 11, 2026
//  Build: ClassCue Dev Build 23
//

import WidgetKit
import SwiftUI
import ActivityKit

struct ClassCueLiveActivityWidget: Widget {

    var body: some WidgetConfiguration {

        ActivityConfiguration(for: ClassCueActivityAttributes.self) { context in

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(context.state.isHeld ? "ON HOLD" : "CLASSCUE")
                        .font(.caption.weight(.bold))
                        .foregroundColor(context.state.isHeld ? .orange : .secondary)

                    Spacer()

                    if !context.state.room.isEmpty {
                        Text(context.state.room)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Text(context.state.className)
                    .font(.headline)
                    .lineLimit(2)

                VStack(alignment: .leading, spacing: 6) {
                    if context.state.isHeld {
                        Text("Paused")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                    } else {
                        Text(context.state.endTime, style: .timer)
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .monospacedDigit()
                    }
                }
            }
            .padding(.horizontal, 4)

        } dynamicIsland: { context in

            DynamicIsland {

                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.state.className)
                            .font(.headline)

                        if !context.state.room.isEmpty {
                            Text(context.state.room)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                DynamicIslandExpandedRegion(.center) {

                    VStack {

                        if context.state.isHeld {
                            Text("Class On Hold")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.orange)
                        }

                        if context.state.isHeld {
                            Text("Paused")
                                .font(.title3.weight(.bold))
                        } else {
                            Text(context.state.endTime, style: .timer)
                                .font(.title)
                                .monospacedDigit()
                        }
                    }
                }

            } compactLeading: {

                Text(context.state.className.prefix(3).uppercased())

            } compactTrailing: {

                if context.state.isHeld {
                    Image(systemName: "pause.fill")
                } else {
                    Text(context.state.endTime, style: .timer)
                }

            } minimal: {

                Image(systemName: context.state.isHeld ? "pause.circle.fill" : "timer")
            }
        }
    }
}
