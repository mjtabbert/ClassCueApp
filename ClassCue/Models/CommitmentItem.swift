//
//  CommitmentItem.swift
//  ClassTrax
//
//  Developer: Mr. Mike
//  Last Updated: March 12, 2026
//

import Foundation
import SwiftUI

struct CommitmentItem: Identifiable, Codable, Equatable {
    enum Recurrence: String, Codable, CaseIterable {
        case weekly
        case oneTime

        var displayName: String {
            switch self {
            case .weekly:
                return "Recurring Weekly"
            case .oneTime:
                return "One Time"
            }
        }
    }

    enum Kind: String, Codable, CaseIterable {
        case duty
        case meeting
        case conference
        case plc
        case coverage
        case reminder
        case other

        var displayName: String {
            switch self {
            case .duty:
                return "Duty"
            case .meeting:
                return "Meeting"
            case .conference:
                return "Conference"
            case .plc:
                return "PLC"
            case .coverage:
                return "Coverage"
            case .reminder:
                return "Reminder"
            case .other:
                return "Other"
            }
        }

        var systemImage: String {
            switch self {
            case .duty:
                return "figure.walk"
            case .meeting:
                return "person.2.fill"
            case .conference:
                return "bubble.left.and.bubble.right.fill"
            case .plc:
                return "rectangle.3.group.bubble.left.fill"
            case .coverage:
                return "person.crop.rectangle.stack.fill"
            case .reminder:
                return "bell.badge.fill"
            case .other:
                return "briefcase.fill"
            }
        }

        var tint: Color {
            switch self {
            case .duty:
                return .orange
            case .meeting:
                return .blue
            case .conference:
                return .pink
            case .plc:
                return .indigo
            case .coverage:
                return .teal
            case .reminder:
                return .yellow
            case .other:
                return .gray
            }
        }
    }

    var id = UUID()
    var title: String
    var kind: Kind = .other
    var dayOfWeek: Int
    var recurrence: Recurrence = .weekly
    var specificDate: Date? = nil
    var startTime: Date
    var endTime: Date
    var location: String = ""
    var notes: String = ""

    init(
        id: UUID = UUID(),
        title: String,
        kind: Kind = .other,
        dayOfWeek: Int,
        recurrence: Recurrence = .weekly,
        specificDate: Date? = nil,
        startTime: Date,
        endTime: Date,
        location: String = "",
        notes: String = ""
    ) {
        self.id = id
        self.title = title
        self.kind = kind
        self.dayOfWeek = dayOfWeek
        self.recurrence = recurrence
        self.specificDate = specificDate
        self.startTime = startTime
        self.endTime = endTime
        self.location = location
        self.notes = notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decode(String.self, forKey: .title)
        kind = try container.decodeIfPresent(Kind.self, forKey: .kind) ?? .other
        dayOfWeek = try container.decode(Int.self, forKey: .dayOfWeek)
        recurrence = try container.decodeIfPresent(Recurrence.self, forKey: .recurrence) ?? .weekly
        specificDate = try container.decodeIfPresent(Date.self, forKey: .specificDate)
        startTime = try container.decode(Date.self, forKey: .startTime)
        endTime = try container.decode(Date.self, forKey: .endTime)
        location = try container.decodeIfPresent(String.self, forKey: .location) ?? ""
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
    }
}
