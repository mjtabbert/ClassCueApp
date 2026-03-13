import Foundation
import SwiftUI

struct ClassDefinitionItem: Identifiable, Codable, Equatable, Hashable {
    enum ScheduleKind: String, Codable, CaseIterable {
        case math
        case ela
        case science
        case socialStudies
        case prep
        case recess
        case lunch
        case transition
        case other
        case blank

        var displayName: String {
            switch self {
            case .math: return "Math"
            case .ela: return "ELA"
            case .science: return "Science"
            case .socialStudies: return "Social Studies"
            case .prep: return "Prep"
            case .recess: return "Recess"
            case .lunch: return "Lunch"
            case .transition: return "Transition"
            case .other: return "Other"
            case .blank: return "Blank"
            }
        }
    }

    var id: UUID = UUID()
    var name: String
    var scheduleKind: ScheduleKind
    var gradeLevel: String
    var defaultLocation: String

    init(
        id: UUID = UUID(),
        name: String,
        scheduleType: ScheduleKind = .other,
        gradeLevel: String = "",
        defaultLocation: String = ""
    ) {
        self.id = id
        self.name = name
        self.scheduleKind = scheduleType
        self.gradeLevel = gradeLevel
        self.defaultLocation = defaultLocation
    }

    var displayName: String {
        let parts = [
            name.trimmingCharacters(in: .whitespacesAndNewlines),
            gradeLevel.trimmingCharacters(in: .whitespacesAndNewlines)
        ].filter { !$0.isEmpty }
        return parts.isEmpty ? "Untitled Class" : parts.joined(separator: " - ")
    }

    var typeDisplayName: String {
        scheduleKind.displayName
    }

    var symbolName: String {
        switch scheduleKind {
        case .math: return "function"
        case .ela: return "text.book.closed.fill"
        case .science: return "atom"
        case .socialStudies: return "globe.americas.fill"
        case .prep: return "pencil.and.ruler.fill"
        case .recess: return "figure.run"
        case .lunch: return "fork.knife"
        case .transition: return "arrow.left.arrow.right"
        case .other: return "square.grid.2x2.fill"
        case .blank: return "circle.dashed"
        }
    }

    var themeColor: Color {
        switch scheduleKind {
        case .math: return .red
        case .ela: return .orange
        case .science: return .yellow
        case .socialStudies: return .green
        case .prep: return .blue
        case .recess: return .indigo
        case .lunch: return .purple
        case .transition: return Color(.systemGray4)
        case .other: return Color(.systemGray)
        case .blank: return .clear
        }
    }
}
