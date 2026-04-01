//
//  AttendanceRecord.swift
//  ClassTrax
//
//  Created by Codex on 3/13/26.
//

import Foundation

struct AttendanceRecord: Identifiable, Codable, Equatable {
    enum Status: String, Codable, CaseIterable, Identifiable {
        case present = "Present"
        case absent = "Absent"
        case tardy = "Tardy"
        case excused = "Excused"

        var id: String { rawValue }
    }

    var id: UUID = UUID()
    var dateKey: String
    var className: String
    var gradeLevel: String
    var studentName: String
    var studentID: UUID?
    var classDefinitionID: UUID?
    var blockID: UUID?
    var blockStartTime: Date?
    var blockEndTime: Date?
    var status: Status
    var absentHomework: String = ""
    var isHomeworkAssignmentOnly: Bool = false

    var isClassHomeworkNote: Bool {
        studentID == nil && studentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isAttendanceEntry: Bool {
        !isClassHomeworkNote && !isHomeworkAssignmentOnly
    }

    init(
        id: UUID = UUID(),
        dateKey: String,
        className: String,
        gradeLevel: String,
        studentName: String,
        studentID: UUID?,
        classDefinitionID: UUID?,
        blockID: UUID?,
        blockStartTime: Date?,
        blockEndTime: Date?,
        status: Status,
        absentHomework: String = "",
        isHomeworkAssignmentOnly: Bool = false
    ) {
        self.id = id
        self.dateKey = dateKey
        self.className = className
        self.gradeLevel = gradeLevel
        self.studentName = studentName
        self.studentID = studentID
        self.classDefinitionID = classDefinitionID
        self.blockID = blockID
        self.blockStartTime = blockStartTime
        self.blockEndTime = blockEndTime
        self.status = status
        self.absentHomework = absentHomework
        self.isHomeworkAssignmentOnly = isHomeworkAssignmentOnly
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case dateKey
        case className
        case gradeLevel
        case studentName
        case studentID
        case classDefinitionID
        case blockID
        case blockStartTime
        case blockEndTime
        case status
        case absentHomework
        case isHomeworkAssignmentOnly
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        dateKey = try container.decode(String.self, forKey: .dateKey)
        className = try container.decode(String.self, forKey: .className)
        gradeLevel = try container.decode(String.self, forKey: .gradeLevel)
        studentName = try container.decode(String.self, forKey: .studentName)
        studentID = try container.decodeIfPresent(UUID.self, forKey: .studentID)
        classDefinitionID = try container.decodeIfPresent(UUID.self, forKey: .classDefinitionID)
        blockID = try container.decodeIfPresent(UUID.self, forKey: .blockID)
        blockStartTime = try container.decodeIfPresent(Date.self, forKey: .blockStartTime)
        blockEndTime = try container.decodeIfPresent(Date.self, forKey: .blockEndTime)
        status = try container.decode(Status.self, forKey: .status)
        absentHomework = try container.decodeIfPresent(String.self, forKey: .absentHomework) ?? ""
        isHomeworkAssignmentOnly = try container.decodeIfPresent(Bool.self, forKey: .isHomeworkAssignmentOnly) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(dateKey, forKey: .dateKey)
        try container.encode(className, forKey: .className)
        try container.encode(gradeLevel, forKey: .gradeLevel)
        try container.encode(studentName, forKey: .studentName)
        try container.encodeIfPresent(studentID, forKey: .studentID)
        try container.encodeIfPresent(classDefinitionID, forKey: .classDefinitionID)
        try container.encodeIfPresent(blockID, forKey: .blockID)
        try container.encodeIfPresent(blockStartTime, forKey: .blockStartTime)
        try container.encodeIfPresent(blockEndTime, forKey: .blockEndTime)
        try container.encode(status, forKey: .status)
        try container.encode(absentHomework, forKey: .absentHomework)
        try container.encode(isHomeworkAssignmentOnly, forKey: .isHomeworkAssignmentOnly)
    }

    static func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func startOfWeek(for date: Date) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 1
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? date
    }

    static func currentWeekDateKeys(containing date: Date) -> Set<String> {
        let start = startOfWeek(for: date)
        let calendar = Calendar(identifier: .gregorian)
        return Set((0..<7).compactMap {
            guard let value = calendar.date(byAdding: .day, value: $0, to: start) else { return nil }
            return dateKey(for: value)
        })
    }

    static func pruneToCurrentWeek(_ records: [AttendanceRecord], now: Date = Date()) -> [AttendanceRecord] {
        let allowedDateKeys = currentWeekDateKeys(containing: now)
        return records.filter { record in
            record.dateKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || allowedDateKeys.contains(record.dateKey)
        }
    }
}
