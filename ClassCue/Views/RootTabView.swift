//
//  RootTabView.swift
//  ClassCue
//
//  Developer: Mr. Mike
//  Last Updated: March 12, 2026
//

import SwiftUI

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

    @State private var selectedTab: AppTab = .today
    @State private var selectedScheduleDay: WeekdayTab = .today

    @AppStorage("timer_v6_data") private var savedAlarms: Data = Data()
    @AppStorage("todo_v6_data") private var savedTodos: Data = Data()
    @AppStorage("commitments_v1_data") private var savedCommitments: Data = Data()
    @AppStorage("profiles_v1_data") private var savedProfiles: Data = Data()
    @AppStorage("day_overrides_v1_data") private var savedOverrides: Data = Data()
    @AppStorage("ignore_until_v1") private var ignoreUntil: Double = 0

    @State private var alarms: [AlarmItem] = []
    @State private var todos: [TodoItem] = []
    @State private var commitments: [CommitmentItem] = []
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

    var body: some View {

        TabView(selection: $selectedTab) {

            // TODAY TAB

            TodayView(
                alarms: $alarms,
                todos: $todos,
                commitments: $commitments,
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
            .tabItem {
                Label("Today", systemImage: "clock")
            }
            .tag(AppTab.today)

            // SCHEDULE TAB

            ScheduleView(
                selectedDay: $selectedScheduleDay,
                alarms: $alarms,
                activeOverrideName: activeDayOverride?.displayName,
                overrideSchedule: activeDayOverride?.alarms
            )
            .tabItem {
                Label("Schedule", systemImage: "calendar")
            }
            .tag(AppTab.schedule)

            // TODO TAB

            TodoListView(todos: $todos, suggestedContexts: suggestedTaskContexts)
                .tabItem {
                    Label("To Do", systemImage: "checklist")
                }
                .tag(AppTab.todo)

            // NOTES TAB

            NotesView(todos: $todos, suggestedContexts: suggestedTaskContexts)
                .tabItem {
                    Label("Notes", systemImage: "note.text")
                }
                .tag(AppTab.notes)

            // SETTINGS TAB

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(AppTab.settings)
        }
        .onAppear {

            loadSavedData()

            selectedScheduleDay = .today

            refreshNotifications()
        }
        .onChange(of: selectedTab) { _, newTab in

            if newTab == .schedule {
                selectedScheduleDay = .today
            }
        }
        .onChange(of: alarms) { _, newValue in

            saveAlarms(newValue)

            refreshNotifications()
        }
        .onChange(of: todos) { _, newValue in
            saveTodos(newValue)
        }
        .onChange(of: commitments) { _, newValue in
            saveCommitments(newValue)
        }
        .onChange(of: savedProfiles) { _, _ in
            loadProfiles()
            refreshNotifications()
        }
        .onChange(of: savedOverrides) { _, _ in
            loadOverrides()
            refreshNotifications()
        }
    }

    // MARK: - Data Loading

    private func loadSavedData() {

        if let decodedAlarms = try? JSONDecoder().decode([AlarmItem].self, from: savedAlarms) {
            alarms = decodedAlarms
        }

        if let decodedTodos = try? JSONDecoder().decode([TodoItem].self, from: savedTodos) {
            todos = decodedTodos
        }

        if let decodedCommitments = try? JSONDecoder().decode([CommitmentItem].self, from: savedCommitments) {
            commitments = decodedCommitments
        }

        loadProfiles()
        loadOverrides()
    }

    // MARK: - Save Alarms

    private func saveAlarms(_ alarms: [AlarmItem]) {

        if let encoded = try? JSONEncoder().encode(alarms) {
            savedAlarms = encoded
        }
    }

    // MARK: - Save Todos

    private func saveTodos(_ todos: [TodoItem]) {

        if let encoded = try? JSONEncoder().encode(todos) {
            savedTodos = encoded
        }
    }

    private func saveCommitments(_ commitments: [CommitmentItem]) {

        if let encoded = try? JSONEncoder().encode(commitments) {
            savedCommitments = encoded
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
            activeOverrideDate: activeDayOverride?.date
        )
    }
}
