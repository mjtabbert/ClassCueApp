//
//  ClassTraxLiveActivityWidget.swift
//  ClassTrax
//
//  Developer: Mr. Mike
//  Last Updated: March 13, 2026
//

import WidgetKit
import SwiftUI
import ActivityKit

struct ClassTraxLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ClassTraxActivityAttributes.self) { context in
            LiveActivitySurfaceView(context: context)
                .padding(.horizontal, 4)
                .activityBackgroundTint(Color.black.opacity(0.18))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: context.state.iconName)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(ClassTraxLiveActivityWidget.accentColor(for: context.state.iconName))
                        Text(context.state.className)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.isHeld {
                        Label("Held", systemImage: "pause.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.orange)
                    } else {
                        Text(timerInterval: Date()...context.state.endTime, countsDown: true, showsHours: false)
                            .font(.headline.weight(.black))
                            .monospacedDigit()
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    if !context.state.nextClassName.isEmpty {
                        Text("Next Up \(context.state.nextClassName)")
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                    }
                }
            } compactLeading: {
                Image(systemName: context.state.iconName)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(ClassTraxLiveActivityWidget.accentColor(for: context.state.iconName))
            } compactTrailing: {
                if context.state.isHeld {
                    Image(systemName: "pause.fill")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.orange)
                } else {
                    Image(systemName: "timer")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                }
            } minimal: {
                Image(systemName: context.state.iconName)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(ClassTraxLiveActivityWidget.accentColor(for: context.state.iconName))
            }
        }
        .supplementalActivityFamilies([.small])
    }

    private struct LiveActivitySurfaceView: View {
        @Environment(\.activityFamily) private var activityFamily
        let context: ActivityViewContext<ClassTraxActivityAttributes>

        var body: some View {
            switch activityFamily {
            case .small:
                watchLiveActivity(context: context)
            case .medium:
                lockScreenLiveActivity(context: context)
            @unknown default:
                lockScreenLiveActivity(context: context)
            }
        }

        private func watchLiveActivity(context: ActivityViewContext<ClassTraxActivityAttributes>) -> some View {
            let accent = ClassTraxLiveActivityWidget.accentColor(for: context.state.iconName)

            return ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                    )

                VStack(spacing: 4) {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(accent.opacity(0.18))
                            .frame(width: 16, height: 16)
                            .overlay {
                                Image(systemName: context.state.iconName)
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(accent)
                            }

                        Text(context.state.className)
                            .font(.system(size: 13, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.55)

                        Spacer(minLength: 0)
                    }

                    if context.state.isHeld {
                        Text("Paused")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .minimumScaleFactor(0.65)
                            .lineLimit(1)
                    } else {
                        Text(context.state.endTime, style: .timer)
                            .font(.system(size: 30, weight: .black, design: .rounded))
                            .monospacedDigit()
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 7)
            }
        }

        private func lockScreenLiveActivity(context: ActivityViewContext<ClassTraxActivityAttributes>) -> some View {
            let accent = ClassTraxLiveActivityWidget.accentColor(for: context.state.iconName)
            let nextAccent = ClassTraxLiveActivityWidget.accentColor(for: context.state.nextIconName)

            return ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.86),
                                accent.opacity(0.30),
                                Color.black.opacity(0.94)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(.white.opacity(0.14), lineWidth: 1)
                    )
                    .shadow(color: accent.opacity(0.22), radius: 18, x: 0, y: 10)

                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .center, spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(accent.opacity(0.18))
                            Image(systemName: context.state.iconName)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(accent)
                        }
                        .frame(width: 30, height: 30)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.state.className)
                                .font(.subheadline.weight(.black))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }

                        Spacer()

                        if !context.state.room.isEmpty {
                            Text(context.state.room)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.72))
                                .lineLimit(1)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.white.opacity(0.08), in: Capsule())
                        }
                    }

                    if context.state.isHeld {
                        Text("Paused")
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .lineLimit(1)
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(context.state.endTime, style: .timer)
                                .font(.system(size: 42, weight: .black, design: .rounded))
                                .monospacedDigit()
                                .lineLimit(1)
                                .minimumScaleFactor(0.58)

                            Text("Ends at \(context.state.endTime.formatted(date: .omitted, time: .shortened))")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.72))
                                .lineLimit(1)
                        }
                    }

                    if !context.state.nextClassName.isEmpty {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(nextAccent)
                                .frame(width: 8, height: 8)

                            Text("Next Up \(context.state.nextClassName)")
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)

                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .foregroundStyle(.white)
                .padding(16)
            }
        }
    }

    private static func accentColor(for symbolName: String) -> Color {
        switch symbolName {
        case "function":
            return .red
        case "text.book.closed.fill":
            return .orange
        case "atom":
            return .yellow
        case "globe.americas.fill":
            return .green
        case "pencil.and.ruler.fill":
            return .blue
        case "figure.run":
            return .indigo
        case "fork.knife":
            return .purple
        case "arrow.left.arrow.right":
            return .gray
        default:
            return .cyan
        }
    }
}
