//
//  Class_TraxControl.swift
//  Class Trax
//
//  Created by Mike Tabbert on 3/11/26.
//

import AppIntents
import SwiftUI
import WidgetKit

struct Class_TraxControl: ControlWidget {
    static let kind: String = "com.mrmike.classtrax.Class Trax"

    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(
            kind: Self.kind,
            provider: Provider()
        ) { value in
            ControlWidgetToggle(
                "Live Countdown",
                isOn: value.isRunning,
                action: ToggleClassTraxControlIntent(value.name)
            ) { isRunning in
                Label(isRunning ? "Active" : "Idle", systemImage: "timer")
            }
        }
        .displayName("ClassTrax")
        .description("Shows the current ClassTrax control state for testing.")
    }
}

extension Class_TraxControl {
    struct Value {
        var isRunning: Bool
        var name: String
    }

    struct Provider: AppIntentControlValueProvider {
        func previewValue(configuration: TimerConfiguration) -> Value {
            Class_TraxControl.Value(isRunning: false, name: configuration.timerName)
        }

        func currentValue(configuration: TimerConfiguration) async throws -> Value {
            let isRunning = false
            return Class_TraxControl.Value(isRunning: isRunning, name: configuration.timerName)
        }
    }
}

struct TimerConfiguration: ControlConfigurationIntent {
    static let title: LocalizedStringResource = "ClassTrax Control"

    @Parameter(title: "Display Name", default: "ClassTrax")
    var timerName: String
}

struct ToggleClassTraxControlIntent: SetValueIntent {
    static let title: LocalizedStringResource = "Toggle ClassTrax Control"

    @Parameter(title: "Display Name")
    var name: String

    @Parameter(title: "Control Active")
    var value: Bool

    init() {}

    init(_ name: String) {
        self.name = name
    }

    func perform() async throws -> some IntentResult {
        return .result()
    }
}
