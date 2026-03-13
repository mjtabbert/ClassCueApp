//
//  RootTabView.swift
//  ClassCue
//
//  Developer: Mr. Mike
//  Last Updated: March 12, 2026
//

import SwiftUI
import SwiftData

// MARK: - App Tabs

enum AppTab: Hashable {
    case today
    case schedule
    case todo
    case notes
    case settings
}

// MARK: - Root Tab View

struct RootTabView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: AppTab = .today
    @State private var selectedScheduleDay: WeekdayTab = .today

    @AppStorage("timer_v6_data") private var savedAlarms: Data = Data()
    @AppStorage("todo_v6_data") private var savedTodos: Data = Data()
    @AppStorage("commitments_v1_data") private var savedCommitments: Data = Data()
    @AppStorage("student_support_profiles_v1_data") private var savedStudentProfiles: Data = Data()
    @AppStorage("class_definitions_v1_data") private var savedClassDefinitions: Data = Data()
    @AppStorage("attendance_v1_data") private var savedAttendance: Data = Data()
    @AppStorage("sub_plans_v1_data") private var savedSubPlans: Data = Data()
    @AppStorage("daily_sub_plans_v1_data") private var savedDailySubPlans: Data = Data()
    @AppStorage("follow_up_notes_v1_data") private var savedFollowUpNotes: Data = Data()
    @AppStorage("profiles_v1_data") private var savedProfiles: Data = Data()
    @AppStorage("day_overrides_v1_data") private var savedOverrides: Data = Data()
    @AppStorage("ignore_until_v1") private var ignoreUntil: Double = 0

    @State private var alarms: [AlarmItem] = []
    @State private var todos: [TodoItem] = []
    @State private var commitments: [CommitmentItem] = []
    @State private var studentProfiles: [StudentSupportProfile] = []
    @State private var classDefinitions: [ClassDefinitionItem] = []
    @State private var attendanceRecords: [AttendanceRecord] = []
    @State private var subPlans: [SubPlanItem] = []
    @State private var dailySubPlans: [DailySubPlanItem] = []
    @State private var profiles: [ScheduleProfile] = []
    @State private var overrides: [DayOverride] = []

    private var ignoreDate: Date? {
        ignoreUntil > 0 ? Date(timeIntervalSince1970: ignoreUntil) : nil
    }

    private var activeDayOverride: ActiveDayOverride? {
        resolvedDayOverride(
            for: Date(),
            overrides: overrides,
            profiles: profiles
        )
    }

    private var suggestedTaskContexts: [String] {
        let classContexts = alarms
            .map(\.className)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        let commitmentContexts = commitments
            .map(\.title)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        return Array(Set((classContexts + commitmentContexts).filter { !$0.isEmpty }))
            .sorted()
    }

    private var suggestedStudents: [String] {
        let taskStudents = todos
            .map(\.studentOrGroup)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let profileStudents = studentProfiles.map(\.name)
        return normalizedStudentDirectory(profileStudents + taskStudents)
    }

    private var studentSupportsByName: [String: StudentSupportProfile] {
        Dictionary(uniqueKeysWithValues: studentProfiles.map { ($0.name, $0) })
    }

    private var baseTabView: some View {
        TabView(selection: $selectedTab) {
            todayTab
            scheduleTab
            todoTab
            notesTab
            settingsTab
        }
    }

    private func makeObservedTabView() -> AnyView {
        let lifecycleView = AnyView(
            baseTabView
                .onAppear { handleOnAppear() }
                .onChange(of: selectedTab) { _, newTab in
                    handleSelectedTabChange(newTab)
                }
                .onChange(of: alarms) { _, newValue in
                    handleAlarmsChange(newValue)
                }
                .onChange(of: todos) { _, newValue in
                    saveTodos(newValue)
                }
                .onChange(of: commitments) { _, newValue in
                    saveCommitments(newValue)
                }
        )

        let syncView = AnyView(
            lifecycleView
                .onChange(of: studentProfiles) { _, newValue in
                    saveStudentProfiles(newValue)
                }
                .onChange(of: classDefinitions) { _, newValue in
                    saveClassDefinitions(newValue)
                    reconcileClassDefinitionLinks()
                }
                .onChange(of: savedStudentProfiles) { _, _ in
                    loadStudentProfiles()
                    reconcileClassDefinitionLinks()
                }
                .onChange(of: savedClassDefinitions) { _, _ in
                    loadClassDefinitions()
                    reconcileClassDefinitionLinks()
                }
                .onChange(of: savedProfiles) { _, _ in
                    loadProfiles()
                    refreshNotifications()
                }
                .onChange(of: savedOverrides) { _, _ in
                    loadOverrides()
                    refreshNotifications()
                }
        )

        return AnyView(
            syncView
                .onChange(of: attendanceRecords) { _, newValue in
                    if let encoded = try? JSONEncoder().encode(newValue) {
                        savedAttendance = encoded
                    }
                }
                .onChange(of: subPlans) { _, newValue in
                    if let encoded = try? JSONEncoder().encode(newValue) {
                        savedSubPlans = encoded
                    }
                    saveSecondPersistenceSlice(
                        todos: todos,
                        subPlans: newValue,
                        dailySubPlans: dailySubPlans
                    )
                }
                .onChange(of: dailySubPlans) { _, newValue in
                    if let encoded = try? JSONEncoder().encode(newValue) {
                        savedDailySubPlans = encoded
                    }
                    saveSecondPersistenceSlice(
                        todos: todos,
                        subPlans: subPlans,
                        dailySubPlans: newValue
                    )
                }
        )
    }

    var body: some View {
        makeObservedTabView()
    }

    private func handleOnAppear() {
        loadSavedData()
        selectedScheduleDay = .today
        refreshNotifications()
    }

    private func handleSelectedTabChange(_ newTab: AppTab) {
        if newTab == .schedule {
            selectedScheduleDay = .today
        }
    }

    private func handleAlarmsChange(_ newValue: [AlarmItem]) {
        saveAlarms(newValue)
        refreshNotifications()
    }

    private var todayTab: some View {
        TodayView(
            alarms: $alarms,
            todos: $todos,
            commitments: $commitments,
            studentSupportProfiles: $studentProfiles,
            classDefinitions: $classDefinitions,
            attendanceRecords: $attendanceRecords,
            subPlans: $subPlans,
            dailySubPlans: $dailySubPlans,
            suggestedStudents: suggestedStudents,
            studentSupportsByName: studentSupportsByName,
            activeOverrideName: activeDayOverride?.displayName,
            overrideSchedule: activeDayOverride?.alarms,
            ignoreDate: ignoreDate
        ) {
            selectedTab = .schedule
        } openTodoTab: {
            selectedTab = .todo
        } openNotesTab: {
            selectedTab = .notes
        } openSettingsTab: {
            selectedTab = .settings
        }
        .toolbar(.hidden, for: .tabBar)
        .tabItem {
            Label("Today", systemImage: "clock")
        }
        .tag(AppTab.today)
    }

    private var scheduleTab: some View {
        ScheduleView(
            selectedDay: $selectedScheduleDay,
            alarms: $alarms,
            studentProfiles: $studentProfiles,
            classDefinitions: $classDefinitions,
            activeOverrideName: activeDayOverride?.displayName,
            overrideSchedule: activeDayOverride?.alarms,
            openTodayTab: { selectedTab = .today }
        )
        .tabItem {
            Label("Schedule", systemImage: "calendar")
        }
        .tag(AppTab.schedule)
    }

    private var todoTab: some View {
        TodoListView(
            todos: $todos,
            studentProfiles: $studentProfiles,
            classDefinitions: $classDefinitions,
            suggestedContexts: suggestedTaskContexts,
            suggestedStudents: suggestedStudents,
            studentSupportsByName: studentSupportsByName,
            openTodayTab: { selectedTab = .today }
        )
        .tabItem {
            Label("To Do", systemImage: "checklist")
        }
        .tag(AppTab.todo)
    }

    private var notesTab: some View {
        NotesView(
            todos: $todos,
            studentProfiles: $studentProfiles,
            classDefinitions: $classDefinitions,
            suggestedContexts: suggestedTaskContexts,
            suggestedStudents: suggestedStudents,
            openTodayTab: { selectedTab = .today }
        )
            .tabItem {
                Label("Notes", systemImage: "note.text")
            }
            .tag(AppTab.notes)
    }

    private var settingsTab: some View {
        SettingsView()
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(AppTab.settings)
    }

    // MARK: - Data Loading

    private func loadSavedData() {
        let legacyAlarms = decodeLegacyAlarms()
        let legacyCommitments = decodeLegacyCommitments()
        let legacyStudentProfiles = decodeLegacyStudentProfiles()
        let legacyClassDefinitions = decodeLegacyClassDefinitions()
        let legacyTodos = decodeLegacyTodos()
        let legacyFollowUpNotes = decodeLegacyFollowUpNotes()
        let legacySubPlans = decodeLegacySubPlans()
        let legacyDailySubPlans = decodeLegacyDailySubPlans()

        ClassCuePersistence.importFirstSliceIfNeeded(
            legacyAlarms: legacyAlarms,
            legacyStudentProfiles: legacyStudentProfiles,
            legacyClassDefinitions: legacyClassDefinitions,
            legacyCommitments: legacyCommitments,
            into: modelContext
        )
        ClassCuePersistence.importSecondSliceIfNeeded(
            legacyTodos: legacyTodos,
            legacyFollowUpNotes: legacyFollowUpNotes,
            legacySubPlans: legacySubPlans,
            legacyDailySubPlans: legacyDailySubPlans,
            into: modelContext
        )

        let persistenceSnapshot = ClassCuePersistence.loadFirstSlice(from: modelContext)
        let secondSliceSnapshot = ClassCuePersistence.loadSecondSlice(from: modelContext)
        alarms = persistenceSnapshot.alarms.map {
            AlarmItem(
                id: $0.id,
                dayOfWeek: $0.dayOfWeek,
                className: $0.className,
                location: $0.location,
                gradeLevel: GradeLevelOption.normalized($0.gradeLevel),
                startTime: $0.startTime,
                endTime: $0.endTime,
                type: $0.type,
                classDefinitionID: $0.classDefinitionID,
                linkedStudentIDs: $0.linkedStudentIDs
            )
        }
        commitments = persistenceSnapshot.commitments
        studentProfiles = persistenceSnapshot.studentProfiles
            .map {
                StudentSupportProfile(
                    id: $0.id,
                    name: $0.name,
                    className: $0.className,
                    gradeLevel: GradeLevelOption.normalized($0.gradeLevel),
                    classDefinitionID: $0.classDefinitionID,
                    graduationYear: $0.graduationYear,
                    parentNames: $0.parentNames,
                    parentPhoneNumbers: $0.parentPhoneNumbers,
                    parentEmails: $0.parentEmails,
                    studentEmail: $0.studentEmail,
                    accommodations: $0.accommodations,
                    prompts: $0.prompts
                )
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        classDefinitions = persistenceSnapshot.classDefinitions.sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
        todos = secondSliceSnapshot.todos
        reconcileClassDefinitionLinks()
        if let decodedAttendance = try? JSONDecoder().decode([AttendanceRecord].self, from: savedAttendance) {
            attendanceRecords = decodedAttendance
        } else {
            attendanceRecords = []
        }
        subPlans = secondSliceSnapshot.subPlans
        dailySubPlans = secondSliceSnapshot.dailySubPlans
        loadProfiles()
        loadOverrides()
    }

    // MARK: - Save Alarms

    private func saveAlarms(_ alarms: [AlarmItem]) {
        saveFirstPersistenceSlice(alarms: alarms, studentProfiles: studentProfiles, classDefinitions: classDefinitions, commitments: commitments)
        if let encoded = try? JSONEncoder().encode(alarms) {
            savedAlarms = encoded
        }
    }

    // MARK: - Save Todos

    private func saveTodos(_ todos: [TodoItem]) {
        saveSecondPersistenceSlice(
            todos: todos,
            subPlans: subPlans,
            dailySubPlans: dailySubPlans
        )

        if let encoded = try? JSONEncoder().encode(todos) {
            savedTodos = encoded
        }
    }

    private func saveCommitments(_ commitments: [CommitmentItem]) {
        saveFirstPersistenceSlice(alarms: alarms, studentProfiles: studentProfiles, classDefinitions: classDefinitions, commitments: commitments)
        if let encoded = try? JSONEncoder().encode(commitments) {
            savedCommitments = encoded
        }
    }

    private func loadStudentProfiles() {
        let snapshot = ClassCuePersistence.loadFirstSlice(from: modelContext)
        studentProfiles = snapshot.studentProfiles
            .map {
                StudentSupportProfile(
                    id: $0.id,
                    name: $0.name,
                    className: $0.className,
                    gradeLevel: GradeLevelOption.normalized($0.gradeLevel),
                    classDefinitionID: $0.classDefinitionID,
                    graduationYear: $0.graduationYear,
                    parentNames: $0.parentNames,
                    parentPhoneNumbers: $0.parentPhoneNumbers,
                    parentEmails: $0.parentEmails,
                    studentEmail: $0.studentEmail,
                    accommodations: $0.accommodations,
                    prompts: $0.prompts
                )
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func loadClassDefinitions() {
        let snapshot = ClassCuePersistence.loadFirstSlice(from: modelContext)
        classDefinitions = snapshot.classDefinitions.sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
    }

    private func saveStudentProfiles(_ profiles: [StudentSupportProfile]) {
        saveFirstPersistenceSlice(alarms: alarms, studentProfiles: profiles, classDefinitions: classDefinitions, commitments: commitments)
        savedStudentProfiles = (try? JSONEncoder().encode(profiles.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        })) ?? Data()
    }

    private func saveClassDefinitions(_ definitions: [ClassDefinitionItem]) {
        saveFirstPersistenceSlice(alarms: alarms, studentProfiles: studentProfiles, classDefinitions: definitions, commitments: commitments)
        savedClassDefinitions = (try? JSONEncoder().encode(definitions.sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        })) ?? Data()
    }

    private func saveFirstPersistenceSlice(
        alarms: [AlarmItem],
        studentProfiles: [StudentSupportProfile],
        classDefinitions: [ClassDefinitionItem],
        commitments: [CommitmentItem]
    ) {
        ClassCuePersistence.saveFirstSlice(
            alarms: alarms,
            studentProfiles: studentProfiles,
            classDefinitions: classDefinitions,
            commitments: commitments,
            into: modelContext
        )
    }

    private func saveSecondPersistenceSlice(
        todos: [TodoItem],
        subPlans: [SubPlanItem],
        dailySubPlans: [DailySubPlanItem]
    ) {
        ClassCuePersistence.saveSecondSlice(
            todos: todos,
            followUpNotes: decodeLegacyFollowUpNotes(),
            subPlans: subPlans,
            dailySubPlans: dailySubPlans,
            into: modelContext
        )
    }

    private func decodeLegacyAlarms() -> [AlarmItem] {
        guard let decodedAlarms = try? JSONDecoder().decode([AlarmItem].self, from: savedAlarms) else {
            return []
        }
        return decodedAlarms.map {
            AlarmItem(
                id: $0.id,
                dayOfWeek: $0.dayOfWeek,
                className: $0.className,
                location: $0.location,
                gradeLevel: GradeLevelOption.normalized($0.gradeLevel),
                startTime: $0.startTime,
                endTime: $0.endTime,
                type: $0.type,
                classDefinitionID: $0.classDefinitionID,
                linkedStudentIDs: $0.linkedStudentIDs
            )
        }
    }

    private func decodeLegacyCommitments() -> [CommitmentItem] {
        (try? JSONDecoder().decode([CommitmentItem].self, from: savedCommitments)) ?? []
    }

    private func decodeLegacyStudentProfiles() -> [StudentSupportProfile] {
        guard let decoded = try? JSONDecoder().decode([StudentSupportProfile].self, from: savedStudentProfiles) else {
            return []
        }
        return decoded.map {
            StudentSupportProfile(
                id: $0.id,
                name: $0.name,
                className: $0.className,
                gradeLevel: GradeLevelOption.normalized($0.gradeLevel),
                classDefinitionID: $0.classDefinitionID,
                graduationYear: $0.graduationYear,
                parentNames: $0.parentNames,
                parentPhoneNumbers: $0.parentPhoneNumbers,
                parentEmails: $0.parentEmails,
                studentEmail: $0.studentEmail,
                accommodations: $0.accommodations,
                prompts: $0.prompts
            )
        }
    }

    private func decodeLegacyClassDefinitions() -> [ClassDefinitionItem] {
        (try? JSONDecoder().decode([ClassDefinitionItem].self, from: savedClassDefinitions)) ?? []
    }

    private func decodeLegacyTodos() -> [TodoItem] {
        (try? JSONDecoder().decode([TodoItem].self, from: savedTodos)) ?? []
    }

    private func decodeLegacyFollowUpNotes() -> [FollowUpNoteItem] {
        (try? JSONDecoder().decode([FollowUpNoteItem].self, from: savedFollowUpNotes)) ?? []
    }

    private func decodeLegacySubPlans() -> [SubPlanItem] {
        (try? JSONDecoder().decode([SubPlanItem].self, from: savedSubPlans)) ?? []
    }

    private func decodeLegacyDailySubPlans() -> [DailySubPlanItem] {
        (try? JSONDecoder().decode([DailySubPlanItem].self, from: savedDailySubPlans)) ?? []
    }

    private func reconcileClassDefinitionLinks() {
        alarms = alarms.map { alarm in
            var updated = alarm
            if updated.classDefinitionID == nil {
                updated.classDefinitionID = exactClassDefinitionMatch(
                    name: updated.className,
                    gradeLevel: updated.gradeLevel,
                    in: classDefinitions
                )?.id
            }
            return updated
        }

        studentProfiles = studentProfiles.map { profile in
            var updated = profile
            if updated.classDefinitionID == nil {
                updated.classDefinitionID = exactClassDefinitionMatch(
                    name: updated.className,
                    gradeLevel: updated.gradeLevel,
                    in: classDefinitions
                )?.id
            }
            return updated
        }
    }

    private func loadProfiles() {
        if let decodedProfiles = try? JSONDecoder().decode([ScheduleProfile].self, from: savedProfiles) {
            profiles = decodedProfiles
        } else {
            profiles = []
        }
    }

    private func loadOverrides() {
        if let decodedOverrides = try? JSONDecoder().decode([DayOverride].self, from: savedOverrides) {
            overrides = decodedOverrides
        } else {
            overrides = []
        }
    }

    private func refreshNotifications() {
        NotificationManager.shared.refreshNotifications(
            for: alarms,
            activeOverrideSchedule: activeDayOverride?.alarms,
            activeOverrideDate: activeDayOverride?.date,
            overrides: overrides,
            profiles: profiles
        )
    }
}
