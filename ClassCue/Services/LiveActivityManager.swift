//
//  LiveActivityManager.swift
//  ClassTrax
//
//  Developer: Mr. Mike
//  Last Updated: March 11, 2026
//  Build: ClassTrax Dev Build 23
//

import Foundation
#if canImport(ActivityKit) && !targetEnvironment(macCatalyst)
import ActivityKit

class LiveActivityManager {

    static var currentActivity: Activity<ClassTraxActivityAttributes>?
    @MainActor static var lastStatusMessage: String = "Idle"
    private static let debugStateKey = "classtrax_live_activity_debug_state_v1"

    struct DebugState: Codable, Equatable {
        var className: String
        var room: String
        var endTime: Date
        var isHeld: Bool
        var iconName: String
        var nextClassName: String
        var nextIconName: String
        var isActive: Bool
        var lastUpdatedAt: Date
    }

    private static var resolvedActivity: Activity<ClassTraxActivityAttributes>? {
        if let currentActivity {
            return currentActivity
        }

        let existing = Activity<ClassTraxActivityAttributes>.activities.first
        currentActivity = existing
        return existing
    }

    private static func saveDebugState(
        className: String,
        room: String,
        endTime: Date,
        isHeld: Bool,
        iconName: String,
        nextClassName: String,
        nextIconName: String,
        isActive: Bool
    ) {
        let state = DebugState(
            className: className,
            room: room,
            endTime: endTime,
            isHeld: isHeld,
            iconName: iconName,
            nextClassName: nextClassName,
            nextIconName: nextIconName,
            isActive: isActive,
            lastUpdatedAt: Date()
        )

        guard let data = try? JSONEncoder().encode(state) else { return }
        UserDefaults.standard.set(data, forKey: debugStateKey)
    }

    private static func markDebugStateInactive() {
        guard var state = debugState() else { return }
        state.isActive = false
        state.lastUpdatedAt = Date()
        guard let data = try? JSONEncoder().encode(state) else { return }
        UserDefaults.standard.set(data, forKey: debugStateKey)
    }

    static func debugState() -> DebugState? {
        guard
            let data = UserDefaults.standard.data(forKey: debugStateKey),
            let state = try? JSONDecoder().decode(DebugState.self, from: data)
        else {
            return nil
        }

        return state
    }

    static func refreshFromLastKnownState() {
        guard let state = debugState() else { return }
        sync(
            className: state.className,
            room: state.room,
            endTime: state.endTime,
            isHeld: state.isHeld,
            iconName: state.iconName,
            nextClassName: state.nextClassName,
            nextIconName: state.nextIconName
        )
    }

    static func restartFromLastKnownState() {
        guard let state = debugState() else { return }

        Task {
            stop()
            try? await Task.sleep(for: .milliseconds(350))
            start(
                className: state.className,
                room: state.room,
                endTime: state.endTime,
                isHeld: state.isHeld,
                iconName: state.iconName,
                nextClassName: state.nextClassName,
                nextIconName: state.nextIconName
            )
        }
    }

    // MARK: - Start Activity

    static func start(
        className: String,
        room: String,
        endTime: Date,
        isHeld: Bool,
        iconName: String,
        nextClassName: String,
        nextIconName: String
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            Task { @MainActor in
                lastStatusMessage = "Live Activities are disabled in iOS settings."
            }
            return
        }

        let attributes = ClassTraxActivityAttributes(
            className: className
        )

        let state = ClassTraxActivityAttributes.ContentState(
            className: className,
            room: room,
            endTime: endTime,
            isHeld: isHeld,
            iconName: iconName,
            nextClassName: nextClassName,
            nextIconName: nextIconName
        )

        let content = ActivityContent(
            state: state,
            staleDate: nil
        )

        saveDebugState(
            className: className,
            room: room,
            endTime: endTime,
            isHeld: isHeld,
            iconName: iconName,
            nextClassName: nextClassName,
            nextIconName: nextIconName,
            isActive: true
        )

        if resolvedActivity != nil {
            update(
                className: className,
                room: room,
                endTime: endTime,
                isHeld: isHeld,
                iconName: iconName,
                nextClassName: nextClassName,
                nextIconName: nextIconName
            )
            return
        }

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: content
            )
            Task { @MainActor in
                lastStatusMessage = currentActivity == nil
                    ? "Activity request returned no activity."
                    : "Started \(className)"
            }
        } catch {
            print("Live Activity start failed:", error.localizedDescription)
            Task { @MainActor in
                lastStatusMessage = "Start failed: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Update Activity

    static func update(
        className: String,
        room: String,
        endTime: Date,
        isHeld: Bool,
        iconName: String,
        nextClassName: String,
        nextIconName: String
    ) {

        Task {
            guard let activity = resolvedActivity else { return }

            let updatedState = ClassTraxActivityAttributes.ContentState(
                className: className,
                room: room,
                endTime: endTime,
                isHeld: isHeld,
                iconName: iconName,
                nextClassName: nextClassName,
                nextIconName: nextIconName
            )

            await activity.update(
                ActivityContent(
                    state: updatedState,
                    staleDate: nil
                )
            )

            saveDebugState(
                className: className,
                room: room,
                endTime: endTime,
                isHeld: isHeld,
                iconName: iconName,
                nextClassName: nextClassName,
                nextIconName: nextIconName,
                isActive: true
            )

            await MainActor.run {
                lastStatusMessage = "Updated \(className)"
            }
        }
    }

    static func sync(
        className: String,
        room: String,
        endTime: Date,
        isHeld: Bool,
        iconName: String,
        nextClassName: String,
        nextIconName: String
    ) {
        if resolvedActivity == nil {
            start(
                className: className,
                room: room,
                endTime: endTime,
                isHeld: isHeld,
                iconName: iconName,
                nextClassName: nextClassName,
                nextIconName: nextIconName
            )
        } else {
            update(
                className: className,
                room: room,
                endTime: endTime,
                isHeld: isHeld,
                iconName: iconName,
                nextClassName: nextClassName,
                nextIconName: nextIconName
            )
        }
    }

    // MARK: - Stop Activity

    static func stop() {

        Task {
            for activity in Activity<ClassTraxActivityAttributes>.activities {
                await activity.end(
                    nil,
                    dismissalPolicy: .immediate
                )
            }

            currentActivity = nil
            markDebugStateInactive()
            await MainActor.run {
                lastStatusMessage = "Stopped"
            }
        }
    }
}
#else
final class LiveActivityManager {
    @MainActor static var lastStatusMessage: String = "Live Activities unavailable on Mac."

    static func start(
        className: String,
        room: String,
        endTime: Date,
        isHeld: Bool,
        iconName: String,
        nextClassName: String,
        nextIconName: String
    ) {
        Task { @MainActor in
            lastStatusMessage = "Live Activities unavailable on this platform."
        }
    }

    static func update(
        className: String,
        room: String,
        endTime: Date,
        isHeld: Bool,
        iconName: String,
        nextClassName: String,
        nextIconName: String
    ) {
        Task { @MainActor in
            lastStatusMessage = "Live Activities unavailable on this platform."
        }
    }

    static func sync(
        className: String,
        room: String,
        endTime: Date,
        isHeld: Bool,
        iconName: String,
        nextClassName: String,
        nextIconName: String
    ) {
        Task { @MainActor in
            lastStatusMessage = "Live Activities unavailable on this platform."
        }
    }

    static func stop() {
        Task { @MainActor in
            lastStatusMessage = "Live Activities unavailable on this platform."
        }
    }
}
#endif
