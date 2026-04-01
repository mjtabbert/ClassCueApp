//
//  FollowUpNoteItem.swift
//  ClassTrax
//
//  Created by Codex on 3/13/26.
//

import Foundation

struct FollowUpNoteItem: Identifiable, Codable, Equatable {
    enum Kind: String, Codable, CaseIterable {
        case generalNote
        case personalNote
        case classNote
        case studentNote
        case parentContact

        var title: String {
            switch self {
            case .generalNote:
                return "School Note"
            case .personalNote:
                return "Personal Note"
            case .classNote:
                return "Class Note"
            case .studentNote:
                return "Student Note"
            case .parentContact:
                return "Parent Contact"
            }
        }
    }

    var id: UUID = UUID()
    var kind: Kind
    var context: String
    var studentOrGroup: String
    var note: String
    var followUpDate: Date
    var createdAt: Date = Date()

    init(
        id: UUID = UUID(),
        kind: Kind,
        context: String,
        studentOrGroup: String,
        note: String,
        followUpDate: Date = Date(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.kind = kind
        self.context = context
        self.studentOrGroup = studentOrGroup
        self.note = note
        self.followUpDate = followUpDate
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        context = try container.decodeIfPresent(String.self, forKey: .context) ?? ""
        studentOrGroup = try container.decodeIfPresent(String.self, forKey: .studentOrGroup) ?? ""
        note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        followUpDate = try container.decodeIfPresent(Date.self, forKey: .followUpDate) ?? createdAt

        if let kind = try container.decodeIfPresent(Kind.self, forKey: .kind) {
            self.kind = kind
        } else if let raw = try container.decodeIfPresent(String.self, forKey: .kind) {
            switch raw {
            case "general", "generalNote":
                self.kind = .generalNote
            case "personal", "personalNote":
                self.kind = .personalNote
            case "classFollowUp":
                self.kind = .classNote
            case "studentFollowUp":
                self.kind = .studentNote
            case "parentContact":
                self.kind = .parentContact
            default:
                self.kind = .classNote
            }
        } else {
            self.kind = .classNote
        }
    }
}
