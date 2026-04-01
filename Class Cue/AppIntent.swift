//
//  AppIntent.swift
//  Class Trax
//
//  Created by Mike Tabbert on 3/11/26.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "ClassTrax Widget" }
    static var description: IntentDescription { "Configure the ClassTrax widget for schedule visibility." }
}
