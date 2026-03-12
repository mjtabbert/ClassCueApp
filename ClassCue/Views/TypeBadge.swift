//
//  TypeBadge.swift
//  ClassCue
//
//  Developer: Mr. Mike
//  Updated: March 11, 2026
//

import SwiftUI

struct TypeBadge: View {

    let type: AlarmItem.ScheduleType

    var label: String {
        switch type {

        case .math:
            return "MATH"

        case .ela:
            return "ELA"

        case .science:
            return "SCIENCE"

        case .socialStudies:
            return "SOCIAL"

        case .prep:
            return "PREP"

        case .recess:
            return "RECESS"

        case .lunch:
            return "LUNCH"

        case .transition:
            return "MOVE"

        case .other:
            return "OTHER"

        case .blank:
            return "BLANK"
        }
    }

    var foregroundColor: Color {
        switch type {
        case .science, .blank:
            return .primary
        case .transition:
            return .secondary
        default:
            return .white
        }
    }

    var body: some View {

        Text(label)
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundColor(foregroundColor)
            .background(type.themeColor)
            .clipShape(Capsule())
    }
}
