//
//  ClassCueActivityAttributes.swift
//  ClassCue
//
//  Developer: Mr. Mike
//  Last Updated: March 11, 2026
//  Build: ClassCue Dev Build 23
//

import Foundation

#if canImport(ActivityKit) && !targetEnvironment(macCatalyst)
import ActivityKit

struct ClassCueActivityAttributes: ActivityAttributes {

    public struct ContentState: Codable, Hashable {
        var className: String
        var room: String
        var endTime: Date
        var isHeld: Bool
        var iconName: String
        var nextClassName: String
        var nextIconName: String
    }

    var className: String
}
#else
struct ClassCueActivityAttributes {

    public struct ContentState: Codable, Hashable {
        var className: String
        var room: String
        var endTime: Date
        var isHeld: Bool
        var iconName: String
        var nextClassName: String
        var nextIconName: String
    }

    var className: String
}
#endif
