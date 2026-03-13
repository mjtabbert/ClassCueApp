import Foundation
import SwiftData

@Model
final class PersistedAlarmItem {
    var id: UUID
    var name: String
    var start: Date
    var end: Date
    var location: String
    var scheduleTypeRawValue: String
    var dayOfWeekValue: Int?
    var gradeLevelValue: String
    var classDefinitionID: UUID?
    var linkedStudentIDs: [UUID]

    init(from item: AlarmItem) {
        self.id = item.id
        self.name = item.className
        self.start = item.startTime
        self.end = item.endTime
        self.location = item.location
        self.scheduleTypeRawValue = item.type.rawValue
        self.dayOfWeekValue = item.dayOfWeekValue
        self.gradeLevelValue = item.gradeLevel
        self.classDefinitionID = item.classDefinitionID
        self.linkedStudentIDs = item.linkedStudentIDs
    }

    func asAlarmItem() -> AlarmItem {
        AlarmItem(
            id: id,
            name: name,
            start: start,
            end: end,
            location: location,
            scheduleType: AlarmItem.ScheduleType(rawValue: scheduleTypeRawValue) ?? .other,
            dayOfWeek: dayOfWeekValue,
            gradeLevel: gradeLevelValue,
            classDefinitionID: classDefinitionID,
            linkedStudentIDs: linkedStudentIDs
        )
    }
}

@Model
final class PersistedStudentSupportProfile {
    var id: UUID
    var name: String
    var className: String
    var gradeLevel: String
    var classDefinitionID: UUID?
    var graduationYear: String
    var parentNames: String
    var parentPhoneNumbers: String
    var parentEmails: String
    var studentEmail: String
    var accommodations: String
    var prompts: String

    init(from item: StudentSupportProfile) {
        self.id = item.id
        self.name = item.name
        self.className = item.className
        self.gradeLevel = item.gradeLevel
        self.classDefinitionID = item.classDefinitionID
        self.graduationYear = item.graduationYear
        self.parentNames = item.parentNames
        self.parentPhoneNumbers = item.parentPhoneNumbers
        self.parentEmails = item.parentEmails
        self.studentEmail = item.studentEmail
        self.accommodations = item.accommodations
        self.prompts = item.prompts
    }

    func asStudentSupportProfile() -> StudentSupportProfile {
        StudentSupportProfile(
            id: id,
            name: name,
            className: className,
            gradeLevel: gradeLevel,
            classDefinitionID: classDefinitionID,
            graduationYear: graduationYear,
            parentNames: parentNames,
            parentPhoneNumbers: parentPhoneNumbers,
            parentEmails: parentEmails,
            studentEmail: studentEmail,
            accommodations: accommodations,
            prompts: prompts
        )
    }
}

@Model
final class PersistedClassDefinitionItem {
    var id: UUID
    var name: String
    var scheduleKindRawValue: String
    var gradeLevel: String
    var defaultLocation: String

    init(from item: ClassDefinitionItem) {
        self.id = item.id
        self.name = item.name
        self.scheduleKindRawValue = item.scheduleKind.rawValue
        self.gradeLevel = item.gradeLevel
        self.defaultLocation = item.defaultLocation
    }

    func asClassDefinitionItem() -> ClassDefinitionItem {
        ClassDefinitionItem(
            id: id,
            name: name,
            scheduleType: ClassDefinitionItem.ScheduleKind(rawValue: scheduleKindRawValue) ?? .other,
            gradeLevel: gradeLevel,
            defaultLocation: defaultLocation
        )
    }
}

@Model
final class PersistedCommitmentItem {
    var id: UUID
    var title: String
    var kindRawValue: String
    var dayOfWeek: Int
    var startTime: Date
    var endTime: Date
    var location: String
    var notes: String

    init(from item: CommitmentItem) {
        self.id = item.id
        self.title = item.title
        self.kindRawValue = item.kind.rawValue
        self.dayOfWeek = item.dayOfWeek
        self.startTime = item.startTime
        self.endTime = item.endTime
        self.location = item.location
        self.notes = item.notes
    }

    func asCommitmentItem() -> CommitmentItem {
        CommitmentItem(
            id: id,
            title: title,
            kind: CommitmentItem.Kind(rawValue: kindRawValue) ?? .other,
            dayOfWeek: dayOfWeek,
            startTime: startTime,
            endTime: endTime,
            location: location,
            notes: notes
        )
    }
}

@Model
final class PersistedTodoItem {
    var id: UUID
    var task: String
    var isCompleted: Bool
    var priorityRawValue: String
    var dueDate: Date?
    var categoryRawValue: String
    var bucketRawValue: String
    var workspaceRawValue: String
    var linkedContext: String
    var studentOrGroup: String
    var followUpNote: String
    var reminderRawValue: String

    init(from item: TodoItem) {
        self.id = item.id
        self.task = item.task
        self.isCompleted = item.isCompleted
        self.priorityRawValue = item.priority.rawValue
        self.dueDate = item.dueDate
        self.categoryRawValue = item.category.rawValue
        self.bucketRawValue = item.bucket.rawValue
        self.workspaceRawValue = item.workspace.rawValue
        self.linkedContext = item.linkedContext
        self.studentOrGroup = item.studentOrGroup
        self.followUpNote = item.followUpNote
        self.reminderRawValue = item.reminder.rawValue
    }

    func asTodoItem() -> TodoItem {
        TodoItem(
            id: id,
            task: task,
            isCompleted: isCompleted,
            priority: TodoItem.Priority(rawValue: priorityRawValue) ?? .none,
            dueDate: dueDate,
            category: TodoItem.Category(rawValue: categoryRawValue) ?? .prep,
            bucket: TodoItem.Bucket(rawValue: bucketRawValue) ?? .today,
            workspace: TodoItem.Workspace(rawValue: workspaceRawValue) ?? .school,
            linkedContext: linkedContext,
            studentOrGroup: studentOrGroup,
            followUpNote: followUpNote,
            reminder: TodoItem.Reminder(rawValue: reminderRawValue) ?? .none
        )
    }
}

@Model
final class PersistedFollowUpNoteItem {
    var id: UUID
    var kindRawValue: String
    var context: String
    var studentOrGroup: String
    var note: String
    var createdAt: Date

    init(from item: FollowUpNoteItem) {
        self.id = item.id
        self.kindRawValue = item.kind.rawValue
        self.context = item.context
        self.studentOrGroup = item.studentOrGroup
        self.note = item.note
        self.createdAt = item.createdAt
    }

    func asFollowUpNoteItem() -> FollowUpNoteItem {
        FollowUpNoteItem(
            id: id,
            kind: FollowUpNoteItem.Kind(rawValue: kindRawValue) ?? .classNote,
            context: context,
            studentOrGroup: studentOrGroup,
            note: note,
            createdAt: createdAt
        )
    }
}

@Model
final class PersistedSubPlanItem {
    var id: UUID
    var dateKey: String
    var linkedAlarmID: UUID?
    var className: String
    var gradeLevel: String
    var location: String
    var overview: String
    var lessonPlan: String
    var materials: String
    var subNotes: String
    var includeRoster: Bool
    var includeSupports: Bool
    var includeAttendance: Bool
    var includeCommitments: Bool
    var includeDaySchedule: Bool
    var createdAt: Date
    var updatedAt: Date

    init(from item: SubPlanItem) {
        self.id = item.id
        self.dateKey = item.dateKey
        self.linkedAlarmID = item.linkedAlarmID
        self.className = item.className
        self.gradeLevel = item.gradeLevel
        self.location = item.location
        self.overview = item.overview
        self.lessonPlan = item.lessonPlan
        self.materials = item.materials
        self.subNotes = item.subNotes
        self.includeRoster = item.includeRoster
        self.includeSupports = item.includeSupports
        self.includeAttendance = item.includeAttendance
        self.includeCommitments = item.includeCommitments
        self.includeDaySchedule = item.includeDaySchedule
        self.createdAt = item.createdAt
        self.updatedAt = item.updatedAt
    }

    func asSubPlanItem() -> SubPlanItem {
        SubPlanItem(
            id: id,
            dateKey: dateKey,
            linkedAlarmID: linkedAlarmID,
            className: className,
            gradeLevel: gradeLevel,
            location: location,
            overview: overview,
            lessonPlan: lessonPlan,
            materials: materials,
            subNotes: subNotes,
            includeRoster: includeRoster,
            includeSupports: includeSupports,
            includeAttendance: includeAttendance,
            includeCommitments: includeCommitments,
            includeDaySchedule: includeDaySchedule,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

@Model
final class PersistedDailySubPlanItem {
    var id: UUID
    var dateKey: String
    var morningNotes: String
    var sharedMaterials: String
    var dismissalNotes: String
    var emergencyNotes: String
    var includeAttendance: Bool
    var includeRoster: Bool
    var includeSupports: Bool
    var includeCommitments: Bool
    var createdAt: Date
    var updatedAt: Date

    init(from item: DailySubPlanItem) {
        self.id = item.id
        self.dateKey = item.dateKey
        self.morningNotes = item.morningNotes
        self.sharedMaterials = item.sharedMaterials
        self.dismissalNotes = item.dismissalNotes
        self.emergencyNotes = item.emergencyNotes
        self.includeAttendance = item.includeAttendance
        self.includeRoster = item.includeRoster
        self.includeSupports = item.includeSupports
        self.includeCommitments = item.includeCommitments
        self.createdAt = item.createdAt
        self.updatedAt = item.updatedAt
    }

    func asDailySubPlanItem() -> DailySubPlanItem {
        DailySubPlanItem(
            id: id,
            dateKey: dateKey,
            morningNotes: morningNotes,
            sharedMaterials: sharedMaterials,
            dismissalNotes: dismissalNotes,
            emergencyNotes: emergencyNotes,
            includeAttendance: includeAttendance,
            includeRoster: includeRoster,
            includeSupports: includeSupports,
            includeCommitments: includeCommitments,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

struct FirstPersistenceSliceSnapshot {
    var alarms: [AlarmItem]
    var studentProfiles: [StudentSupportProfile]
    var classDefinitions: [ClassDefinitionItem]
    var commitments: [CommitmentItem]
}

struct SecondPersistenceSliceSnapshot {
    var todos: [TodoItem]
    var followUpNotes: [FollowUpNoteItem]
    var subPlans: [SubPlanItem]
    var dailySubPlans: [DailySubPlanItem]
}

enum ClassCuePersistence {
    static let firstSliceMigrationKey = "swiftdata_first_slice_migration_v1"
    static let secondSliceMigrationKey = "swiftdata_second_slice_migration_v1"

    static let sharedModelContainer: ModelContainer = {
        do {
            return try ModelContainer(
                for:
                    PersistedAlarmItem.self,
                    PersistedStudentSupportProfile.self,
                    PersistedClassDefinitionItem.self,
                    PersistedCommitmentItem.self,
                    PersistedTodoItem.self,
                    PersistedFollowUpNoteItem.self,
                    PersistedSubPlanItem.self,
                    PersistedDailySubPlanItem.self
            )
        } catch {
            fatalError("Unable to create SwiftData container: \(error)")
        }
    }()

    @MainActor
    static func importFirstSliceIfNeeded(
        legacyAlarms: [AlarmItem],
        legacyStudentProfiles: [StudentSupportProfile],
        legacyClassDefinitions: [ClassDefinitionItem],
        legacyCommitments: [CommitmentItem],
        into context: ModelContext
    ) {
        let hasImported = UserDefaults.standard.bool(forKey: firstSliceMigrationKey)
        if hasImported { return }

        replaceAll(PersistedClassDefinitionItem.self, in: context, with: legacyClassDefinitions.map(PersistedClassDefinitionItem.init))
        replaceAll(PersistedStudentSupportProfile.self, in: context, with: legacyStudentProfiles.map(PersistedStudentSupportProfile.init))
        replaceAll(PersistedAlarmItem.self, in: context, with: legacyAlarms.map(PersistedAlarmItem.init))
        replaceAll(PersistedCommitmentItem.self, in: context, with: legacyCommitments.map(PersistedCommitmentItem.init))
        save(context)

        UserDefaults.standard.set(true, forKey: firstSliceMigrationKey)
    }

    @MainActor
    static func loadFirstSlice(from context: ModelContext) -> FirstPersistenceSliceSnapshot {
        let classes = (try? context.fetch(FetchDescriptor<PersistedClassDefinitionItem>(
            sortBy: [SortDescriptor(\.name), SortDescriptor(\.gradeLevel)]
        ))) ?? []
        let students = (try? context.fetch(FetchDescriptor<PersistedStudentSupportProfile>(
            sortBy: [SortDescriptor(\.name)]
        ))) ?? []
        let alarms = (try? context.fetch(FetchDescriptor<PersistedAlarmItem>(
            sortBy: [SortDescriptor(\.dayOfWeekValue), SortDescriptor(\.start)]
        ))) ?? []
        let commitments = (try? context.fetch(FetchDescriptor<PersistedCommitmentItem>(
            sortBy: [SortDescriptor(\.dayOfWeek), SortDescriptor(\.startTime)]
        ))) ?? []

        return FirstPersistenceSliceSnapshot(
            alarms: alarms.map { $0.asAlarmItem() },
            studentProfiles: students.map { $0.asStudentSupportProfile() },
            classDefinitions: classes.map { $0.asClassDefinitionItem() },
            commitments: commitments.map { $0.asCommitmentItem() }
        )
    }

    @MainActor
    static func saveFirstSlice(
        alarms: [AlarmItem],
        studentProfiles: [StudentSupportProfile],
        classDefinitions: [ClassDefinitionItem],
        commitments: [CommitmentItem],
        into context: ModelContext
    ) {
        replaceAll(PersistedClassDefinitionItem.self, in: context, with: classDefinitions.map(PersistedClassDefinitionItem.init))
        replaceAll(PersistedStudentSupportProfile.self, in: context, with: studentProfiles.map(PersistedStudentSupportProfile.init))
        replaceAll(PersistedAlarmItem.self, in: context, with: alarms.map(PersistedAlarmItem.init))
        replaceAll(PersistedCommitmentItem.self, in: context, with: commitments.map(PersistedCommitmentItem.init))
        save(context)
        UserDefaults.standard.set(true, forKey: firstSliceMigrationKey)
    }

    @MainActor
    static func importSecondSliceIfNeeded(
        legacyTodos: [TodoItem],
        legacyFollowUpNotes: [FollowUpNoteItem],
        legacySubPlans: [SubPlanItem],
        legacyDailySubPlans: [DailySubPlanItem],
        into context: ModelContext
    ) {
        let hasImported = UserDefaults.standard.bool(forKey: secondSliceMigrationKey)
        if hasImported { return }

        replaceAll(PersistedTodoItem.self, in: context, with: legacyTodos.map(PersistedTodoItem.init))
        replaceAll(PersistedFollowUpNoteItem.self, in: context, with: legacyFollowUpNotes.map(PersistedFollowUpNoteItem.init))
        replaceAll(PersistedSubPlanItem.self, in: context, with: legacySubPlans.map(PersistedSubPlanItem.init))
        replaceAll(PersistedDailySubPlanItem.self, in: context, with: legacyDailySubPlans.map(PersistedDailySubPlanItem.init))
        save(context)

        UserDefaults.standard.set(true, forKey: secondSliceMigrationKey)
    }

    @MainActor
    static func loadSecondSlice(from context: ModelContext) -> SecondPersistenceSliceSnapshot {
        let todos = (try? context.fetch(FetchDescriptor<PersistedTodoItem>(
            sortBy: [SortDescriptor(\.task)]
        ))) ?? []
        let followUpNotes = (try? context.fetch(FetchDescriptor<PersistedFollowUpNoteItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        ))) ?? []
        let subPlans = (try? context.fetch(FetchDescriptor<PersistedSubPlanItem>(
            sortBy: [SortDescriptor(\.dateKey), SortDescriptor(\.updatedAt, order: .reverse)]
        ))) ?? []
        let dailySubPlans = (try? context.fetch(FetchDescriptor<PersistedDailySubPlanItem>(
            sortBy: [SortDescriptor(\.dateKey), SortDescriptor(\.updatedAt, order: .reverse)]
        ))) ?? []

        return SecondPersistenceSliceSnapshot(
            todos: todos.map { $0.asTodoItem() },
            followUpNotes: followUpNotes.map { $0.asFollowUpNoteItem() },
            subPlans: subPlans.map { $0.asSubPlanItem() },
            dailySubPlans: dailySubPlans.map { $0.asDailySubPlanItem() }
        )
    }

    @MainActor
    static func saveSecondSlice(
        todos: [TodoItem],
        followUpNotes: [FollowUpNoteItem],
        subPlans: [SubPlanItem],
        dailySubPlans: [DailySubPlanItem],
        into context: ModelContext
    ) {
        replaceAll(PersistedTodoItem.self, in: context, with: todos.map(PersistedTodoItem.init))
        replaceAll(PersistedFollowUpNoteItem.self, in: context, with: followUpNotes.map(PersistedFollowUpNoteItem.init))
        replaceAll(PersistedSubPlanItem.self, in: context, with: subPlans.map(PersistedSubPlanItem.init))
        replaceAll(PersistedDailySubPlanItem.self, in: context, with: dailySubPlans.map(PersistedDailySubPlanItem.init))
        save(context)
        UserDefaults.standard.set(true, forKey: secondSliceMigrationKey)
    }

    @MainActor
    static func loadFollowUpNotes(from context: ModelContext) -> [FollowUpNoteItem] {
        let notes = (try? context.fetch(FetchDescriptor<PersistedFollowUpNoteItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        ))) ?? []
        return notes.map { $0.asFollowUpNoteItem() }
    }

    @MainActor
    static func saveFollowUpNotes(_ notes: [FollowUpNoteItem], into context: ModelContext) {
        replaceAll(PersistedFollowUpNoteItem.self, in: context, with: notes.map(PersistedFollowUpNoteItem.init))
        save(context)
        UserDefaults.standard.set(true, forKey: secondSliceMigrationKey)
    }

    @MainActor
    private static func replaceAll<T: PersistentModel>(_ type: T.Type, in context: ModelContext, with models: [T]) {
        let descriptor = FetchDescriptor<T>()
        let existing = (try? context.fetch(descriptor)) ?? []
        for item in existing {
            context.delete(item)
        }
        for model in models {
            context.insert(model)
        }
    }

    @MainActor
    private static func save(_ context: ModelContext) {
        do {
            try context.save()
        } catch {
            assertionFailure("Failed to save SwiftData migration slice: \(error)")
        }
    }
}
