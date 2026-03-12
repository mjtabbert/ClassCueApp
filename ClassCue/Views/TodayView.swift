//
//  TodayView.swift
//  ClassCue
//
//  Developer: Mr. Mike
//  Last Updated: March 11, 2026
//  Build: ClassCue Dev Build 25
//

import SwiftUI

struct TodayView: View {

    @Binding var alarms: [AlarmItem]
    @Binding var todos: [TodoItem]
    @Binding var commitments: [CommitmentItem]
    let activeOverrideName: String?
    let overrideSchedule: [AlarmItem]?
    let ignoreDate: Date?
    let openScheduleTab: () -> Void
    let openTodoTab: () -> Void
    let openNotesTab: () -> Void
    let openSettingsTab: () -> Void

    @AppStorage("notes_v1") private var notesText: String = ""
    @AppStorage("school_quiet_hours_enabled") private var schoolQuietHoursEnabled = false
    @AppStorage("school_quiet_hour") private var schoolQuietHour = 16
    @AppStorage("school_quiet_minute") private var schoolQuietMinute = 0

    @State private var activeWarning: InAppWarning?
    @State private var lastWarningKey: String?
    @State private var warningDismissTask: Task<Void, Never>?
    @State private var extraTimeByItemID: [UUID: TimeInterval] = [:]
    @State private var heldItemID: UUID?
    @State private var holdStartedAt: Date?
    @State private var skippedBellItemIDs: Set<UUID> = []
    @State private var lastActiveItemID: UUID?
    @State private var showingSessionActions = false
    @State private var showingAddCommitment = false
    @State private var editingCommitment: CommitmentItem?
    @State private var showingQuickCapture = false

    var body: some View {

        TimelineView(.periodic(from: .now, by: 0.2)) { context in

            let now = context.date
            let schedule = adjustedTodaySchedule(for: now)

            let activeItem = schedule.first {
                now >= startDateToday(for: $0, now: now) && now <= endDateToday(for: $0, now: now)
            }

            let nextItem = schedule.first {
                startDateToday(for: $0, now: now) > now
            }

            let warning = warningForUpcomingBlock(nextItem, now: now)
            let highlightItem = activeItem ?? nextItem
            let activeItemID = activeItem?.id
            let todayCommitments = commitmentsForToday(now: now)

            ZStack(alignment: .top) {

                todayBackground(for: highlightItem)
                    .ignoresSafeArea()

                GeometryReader { geo in

                    let isLandscape = geo.size.width > geo.size.height

                    Group {
                        if isLandscape {
                            landscapeDashboard(
                                now: now,
                                schedule: schedule,
                                activeItem: activeItem,
                                nextItem: nextItem,
                                todayCommitments: todayCommitments
                            )
                        } else {
                            portraitDashboard(
                                now: now,
                                schedule: schedule,
                                activeItem: activeItem,
                                nextItem: nextItem,
                                todayCommitments: todayCommitments
                            )
                        }
                    }
                }

                if let activeWarning {
                    InAppWarningBanner(warning: activeWarning)
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(1)
                }

                if let activeItem {
                    sessionActionButton(for: activeItem)
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .zIndex(1)
                }
            }
            .animation(.spring(response: 0.42, dampingFraction: 0.86), value: activeWarning?.id)
            .onChange(of: warning?.id) { _, newValue in
                handleWarningTrigger(warning, key: newValue)
            }
            .onChange(of: activeItemID) { _, newValue in
                handleActiveItemChange(newValue)
            }
            .onChange(of: activeItemID) { _, _ in
                processBellIfNeeded(activeItem, now: now)
            }
            .onChange(of: now) {
                processBellIfNeeded(activeItem, now: now)
            }
            .onChange(of: liveActivityState(for: activeItem, now: now)) { _, newValue in
                syncLiveActivity(with: newValue)
            }
            .task {
                syncLiveActivity(with: liveActivityState(for: activeItem, now: now))
            }
            .confirmationDialog(
                activeItem == nil ? "Class Controls" : "\(activeItem?.className ?? "Class") Controls",
                isPresented: $showingSessionActions,
                titleVisibility: .visible
            ) {
                if let activeItem {
                    Button(isHeld(activeItem) ? "Resume Class" : "Hold Class") {
                        toggleHold(for: activeItem, now: now)
                    }

                    Button("Extend 1 Minute") {
                        extend(activeItem, byMinutes: 1)
                    }

                    Button("Extend 2 Minutes") {
                        extend(activeItem, byMinutes: 2)
                    }

                    Button("Extend 5 Minutes") {
                        extend(activeItem, byMinutes: 5)
                    }

                    Button(
                        skippedBellItemIDs.contains(activeItem.id) ? "Bell Already Skipped" : "Skip Bell",
                        role: skippedBellItemIDs.contains(activeItem.id) ? .cancel : nil
                    ) {
                        if !skippedBellItemIDs.contains(activeItem.id) {
                            skipBell(for: activeItem)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddCommitment) {
                AddCommitmentView(
                    commitments: $commitments,
                    defaultDay: Calendar.current.component(.weekday, from: now)
                )
            }
            .sheet(item: $editingCommitment) { commitment in
                AddCommitmentView(
                    commitments: $commitments,
                    defaultDay: commitment.dayOfWeek,
                    existing: commitment
                )
            }
            .sheet(isPresented: $showingQuickCapture) {
                QuickCaptureView(
                    todos: $todos,
                    suggestedContexts: suggestedTaskContexts,
                    preferredContext: preferredCaptureContext(for: adjustedTodaySchedule(for: Date())),
                    preferredCategory: preferredCaptureCategory(for: adjustedTodaySchedule(for: Date()), now: Date())
                )
            }
        }
    }

    // MARK: Header

    func header(now: Date) -> some View {

        VStack(spacing: 4) {

            Text(now.formatted(.dateTime.weekday(.wide)))
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.orange)
                .tracking(4)

            Text(now.formatted(.dateTime.month().day()))
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(now.formatted(.dateTime.hour().minute()))
                .foregroundColor(.secondary)
        }
        .padding(.top)
    }

    private func holidayModeBanner(until date: Date) -> some View {

        HStack(spacing: 10) {
            Image(systemName: "bell.slash.fill")
                .foregroundColor(.orange)

            Text("Holiday mode is on until \(date.formatted(date: .abbreviated, time: .shortened)).")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.orange.opacity(0.12))
        )
    }

    @ViewBuilder
    private func todayBackground(for item: AlarmItem?) -> some View {

        let accent = item?.accentColor ?? Color.blue
        let secondary = secondaryBackgroundColor(for: item)

        ZStack {
            LinearGradient(
                colors: [
                    accent.opacity(0.18),
                    secondary.opacity(0.12),
                    Color(.systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(accent.opacity(0.14))
                .frame(width: 320, height: 320)
                .blur(radius: 24)
                .offset(x: 110, y: -180)

            Circle()
                .fill(secondary.opacity(0.14))
                .frame(width: 260, height: 260)
                .blur(radius: 20)
                .offset(x: -140, y: -90)
        }
    }

    private func emptyState(for now: Date) -> some View {

        VStack(alignment: .leading, spacing: 12) {

            Text("No blocks scheduled for today.")
                .font(.headline)

            Text("Add a few test blocks in the Schedule tab and they will appear here right away.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button {
                openScheduleTab()
            } label: {
                Label("Open Schedule", systemImage: "calendar")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemBackground))
        )
    }

    @ViewBuilder
    private func portraitDashboard(
        now: Date,
        schedule: [AlarmItem],
        activeItem: AlarmItem?,
        nextItem: AlarmItem?,
        todayCommitments: [CommitmentItem]
    ) -> some View {

        ScrollView {
            VStack(spacing: 16) {

                header(now: now)

                if let ignoreDate, ignoreDate > now {
                    holidayModeBanner(until: ignoreDate)
                        .padding(.horizontal)
                }

                if let activeOverrideName {
                    overrideBanner(name: activeOverrideName)
                        .padding(.horizontal)
                }

                if shouldShowDayStatus(now: now, schedule: schedule, activeItem: activeItem) {
                    dayStatusCard(now: now, schedule: schedule, activeItem: activeItem)
                        .padding(.horizontal)
                }

                if let active = activeItem {
                    ActiveTimerCard(
                        item: active,
                        now: now,
                        isHeld: isHeld(active),
                        bellSkipped: skippedBellItemIDs.contains(active.id)
                    )
                        .frame(height: 260)
                        .padding(.horizontal)
                } else if let next = nextItem {
                    NextUpSummaryCard(item: next, now: now)
                        .padding(.horizontal)
                }

                dashboardSummaryRow(
                    now: now,
                    schedule: schedule,
                    nextItem: nextItem,
                    todayCommitments: todayCommitments
                )
                .padding(.horizontal)

                if schedule.isEmpty {
                    emptyState(for: now)
                        .padding(.horizontal)
                }
            }
            .padding(.bottom, 96)
        }
    }

    @ViewBuilder
    private func landscapeDashboard(
        now: Date,
        schedule: [AlarmItem],
        activeItem: AlarmItem?,
        nextItem: AlarmItem?,
        todayCommitments: [CommitmentItem]
    ) -> some View {

        VStack(spacing: 12) {

            landscapeHeader(now: now)

            if let ignoreDate, ignoreDate > now {
                holidayModeBanner(until: ignoreDate)
            }

            if let activeOverrideName {
                overrideBanner(name: activeOverrideName)
            }

            HStack(alignment: .top, spacing: 16) {

                Group {
                    if let active = activeItem {
                        ActiveTimerCard(
                            item: active,
                            now: now,
                            isTeacherMode: true,
                            isHeld: isHeld(active),
                            bellSkipped: skippedBellItemIDs.contains(active.id)
                        )
                    } else if let next = nextItem {
                        NextUpSummaryCard(
                            item: next,
                            now: now,
                            isCompact: true
                        )
                    } else {
                        emptyState(for: now)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                VStack(spacing: 12) {
                    dashboardSummaryColumn(
                        now: now,
                        schedule: schedule,
                        nextItem: nextItem,
                        todayCommitments: todayCommitments
                    )

                }
                .frame(width: 320)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private func dashboardSummaryRow(
        now: Date,
        schedule: [AlarmItem],
        nextItem: AlarmItem?,
        todayCommitments: [CommitmentItem]
    ) -> some View {
        VStack(spacing: 12) {
            quickActionsCard()
            commitmentsCard(todayCommitments: todayCommitments, compact: false)
            upcomingStrip(schedule: schedule, now: now, nextItem: nextItem)
            topTasksCard(now: now)
            notesSnapshotCard(compact: false)
            schoolBoundaryCard(now: now, schedule: schedule)
            endOfDayCard(now: now, schedule: schedule)
        }
    }

    @ViewBuilder
    private func dashboardSummaryColumn(
        now: Date,
        schedule: [AlarmItem],
        nextItem: AlarmItem?,
        todayCommitments: [CommitmentItem]
    ) -> some View {
        VStack(spacing: 12) {
            if shouldShowDayStatus(now: now, schedule: schedule, activeItem: schedule.first(where: {
                now >= startDateToday(for: $0, now: now) && now <= endDateToday(for: $0, now: now)
            })) {
                dayStatusCard(now: now, schedule: schedule, activeItem: schedule.first(where: {
                    now >= startDateToday(for: $0, now: now) && now <= endDateToday(for: $0, now: now)
                }), compact: true)
            }

            quickActionsCard(compact: true)
            commitmentsCard(todayCommitments: todayCommitments, compact: true)
            upcomingStrip(schedule: schedule, now: now, nextItem: nextItem, compact: true)
            topTasksCard(now: now, compact: true)
            notesSnapshotCard(compact: true)
            schoolBoundaryCard(now: now, schedule: schedule, compact: true)
            endOfDayCard(now: now, schedule: schedule, compact: true)
        }
    }

    private func dayStatusCard(
        now: Date,
        schedule: [AlarmItem],
        activeItem: AlarmItem?,
        compact: Bool = false
    ) -> some View {
        let remainingCount = schedule.filter { endDateToday(for: $0, now: now) > now }.count
        let finalBlock = schedule.max { startDateToday(for: $0, now: now) < startDateToday(for: $1, now: now) }
        let statusTitle: String
        let statusDetail: String
        let tint: Color

        if let ignoreDate, ignoreDate > now {
            statusTitle = "Holiday Mode Active"
            statusDetail = "Notifications are paused until \(ignoreDate.formatted(date: .abbreviated, time: .shortened))."
            tint = .orange
        } else if let activeItem {
            statusTitle = "School Day In Motion"
            statusDetail = "\(remainingCount) block\(remainingCount == 1 ? "" : "s") left today"
            tint = activeItem.accentColor == .clear ? .blue : activeItem.accentColor
        } else if let next = schedule.first(where: { startDateToday(for: $0, now: now) > now }) {
            statusTitle = "Next Block Ahead"
            statusDetail = "\(next.className) starts at \(startDateToday(for: next, now: now).formatted(date: .omitted, time: .shortened))"
            tint = next.accentColor == .clear ? .blue : next.accentColor
        } else {
            statusTitle = "School Day Wrapped"
            statusDetail = "No more scheduled blocks today."
            tint = .indigo
        }

        return VStack(alignment: .leading, spacing: compact ? 8 : 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: ignoreDate != nil && (ignoreDate ?? now) > now ? "bell.slash.fill" : "sparkles")
                    .foregroundStyle(tint)
                    .font(compact ? .headline : .title3)

                VStack(alignment: .leading, spacing: 4) {
                    Text(statusTitle)
                        .font((compact ? Font.subheadline : .headline).weight(.bold))

                    Text(statusDetail)
                        .font(compact ? .caption : .subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            HStack(spacing: compact ? 8 : 10) {
                statusPill(
                    title: "Blocks Left",
                    value: "\(remainingCount)",
                    compact: compact
                )

                if let finalBlock {
                    statusPill(
                        title: "Dismissal",
                        value: endDateToday(for: finalBlock, now: now).formatted(date: .omitted, time: .shortened),
                        compact: compact
                    )
                }
            }
        }
        .padding(compact ? 12 : 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(tint.opacity(0.18), lineWidth: 1)
        )
    }

    private func statusPill(title: String, value: String, compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(compact ? .caption2 : .caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font((compact ? Font.caption : .subheadline).weight(.bold))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, compact ? 10 : 12)
        .padding(.vertical, compact ? 8 : 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground).opacity(0.9))
        )
    }

    private func quickActionsCard(compact: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Quick Actions", systemImage: "bolt.fill")
                .font((compact ? Font.subheadline : .headline).weight(.bold))

            let columns = [
                GridItem(.flexible(), spacing: compact ? 8 : 10),
                GridItem(.flexible(), spacing: compact ? 8 : 10)
            ]

            LazyVGrid(columns: columns, spacing: compact ? 8 : 10) {
                quickActionButton(
                    title: "Schedule",
                    systemImage: "calendar",
                    tint: .blue,
                    compact: compact,
                    action: openScheduleTab
                )

                quickActionButton(
                    title: "Tasks",
                    systemImage: "checklist",
                    tint: .orange,
                    compact: compact,
                    action: openTodoTab
                )

                quickActionButton(
                    title: "Notes",
                    systemImage: "note.text",
                    tint: .indigo,
                    compact: compact,
                    action: openNotesTab
                )

                quickActionButton(
                    title: "Quick Add",
                    systemImage: "square.and.pencil",
                    tint: .green,
                    compact: compact
                ) {
                    showingQuickCapture = true
                }
            }
        }
        .padding(compact ? 12 : 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func commitmentsCard(todayCommitments: [CommitmentItem], compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Today's Commitments", systemImage: "person.3.sequence.fill")
                    .font((compact ? Font.subheadline : .headline).weight(.bold))

                Spacer()

                Button(todayCommitments.isEmpty ? "Add" : "Manage") {
                    if let first = todayCommitments.first {
                        editingCommitment = first
                    } else {
                        showingAddCommitment = true
                    }
                }
                .font(.caption.weight(.semibold))

                if !todayCommitments.isEmpty {
                    Button {
                        showingAddCommitment = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .font(.headline)
                }
            }

            if todayCommitments.isEmpty {
                Text("Add duties, meetings, conferences, or coverage blocks so Today shows the full shape of your school day.")
                    .font(compact ? .caption : .subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(todayCommitments.prefix(compact ? 3 : 4)) { commitment in
                        Button {
                            editingCommitment = commitment
                        } label: {
                            commitmentRow(for: commitment, compact: compact)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(compact ? 12 : 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func commitmentRow(for commitment: CommitmentItem, compact: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: commitment.kind.systemImage)
                .font(compact ? .subheadline : .headline)
                .foregroundStyle(commitment.kind.tint)
                .frame(width: compact ? 22 : 26, height: compact ? 22 : 26)
                .background(
                    Circle()
                        .fill(commitment.kind.tint.opacity(0.14))
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(commitment.title)
                    .font((compact ? Font.caption : .subheadline).weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(commitmentTimeText(for: commitment))
                    .font(compact ? .caption2 : .caption)
                    .foregroundStyle(.secondary)

                if !commitment.location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(commitment.location)
                        .font(compact ? .caption2 : .caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground).opacity(0.92))
        )
    }

    private func quickActionButton(
        title: String,
        systemImage: String,
        tint: Color,
        compact: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: compact ? 6 : 8) {
                Image(systemName: systemImage)
                    .font(compact ? .headline : .title3)

                Text(title)
                    .font((compact ? Font.caption2 : .caption).weight(.bold))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, compact ? 10 : 12)
            .foregroundStyle(tint)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(tint.opacity(0.12))
            )
        }
        .buttonStyle(.plain)
    }

    private func upcomingStrip(
        schedule: [AlarmItem],
        now: Date,
        nextItem: AlarmItem?,
        compact: Bool = false
    ) -> some View {
        let upcomingItems = laterTodayItems(from: schedule, now: now, nextItem: nextItem)

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Coming Later Today", systemImage: "calendar.badge.clock")
                    .font((compact ? Font.subheadline : .headline).weight(.bold))

                Spacer()

                if !upcomingItems.isEmpty {
                    Button("Schedule") {
                        openScheduleTab()
                    }
                    .font(.caption.weight(.semibold))
                }
            }

            if upcomingItems.isEmpty {
                Text("No more scheduled blocks after next up.")
                    .font(compact ? .caption : .subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(upcomingItems) { item in
                            upcomingChip(for: item, compact: compact)
                        }
                    }
                }
            }
        }
        .padding(compact ? 12 : 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func upcomingChip(for item: AlarmItem, compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Circle()
                    .fill(item.accentColor == .clear ? Color.gray.opacity(0.2) : item.accentColor)
                    .frame(width: 8, height: 8)

                Text(item.className)
                    .font((compact ? Font.caption : .subheadline).weight(.bold))
                    .lineLimit(1)
            }

            Text("\(item.startTime.formatted(date: .omitted, time: .shortened)) - \(item.endTime.formatted(date: .omitted, time: .shortened))")
                .font(compact ? .caption2 : .caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(width: compact ? 140 : 168, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground).opacity(0.92))
        )
    }

    private func topTasksCard(now: Date, compact: Bool = false) -> some View {
        let tasks = topTasks(for: now)

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Top Tasks", systemImage: "checklist")
                    .font((compact ? Font.subheadline : .headline).weight(.bold))

                Spacer()

                Button(tasks.isEmpty ? "Add" : "Open") {
                    openTodoTab()
                }
                .font(.caption.weight(.semibold))
            }

            if tasks.isEmpty {
                Text("No active school tasks. Add a few to make Today your command center.")
                    .font(compact ? .caption : .subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(tasks) { task in
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(task.priority.color)
                                .frame(width: 9, height: 9)
                                .padding(.top, 5)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(task.task)
                                    .font((compact ? Font.caption : .subheadline).weight(.semibold))
                                    .lineLimit(2)

                                Text(taskSubtitle(for: task))
                                    .font(compact ? .caption2 : .caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer(minLength: 0)
                        }
                    }
                }
            }
        }
        .padding(compact ? 12 : 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func notesSnapshotCard(compact: Bool) -> some View {
        let snapshot = notesSnapshot

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Notes Snapshot", systemImage: "note.text")
                    .font((compact ? Font.subheadline : .headline).weight(.bold))

                Spacer()

                Button(snapshot == nil ? "Add" : "Open") {
                    openNotesTab()
                }
                .font(.caption.weight(.semibold))
            }

            if let snapshot {
                Text(snapshot)
                    .font(compact ? .caption : .subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(compact ? 3 : 4)
            } else {
                Text("No school notes yet. Keep a running note here for duties, reminders, and meeting details.")
                    .font(compact ? .caption : .subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(compact ? 12 : 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func schoolBoundaryCard(
        now: Date,
        schedule: [AlarmItem],
        compact: Bool = false
    ) -> some View {
        let afterHours = isAfterSchoolQuietStart(now)
        let quietStart = schoolQuietStart(on: now)
        let unfinishedTasks = todos.filter { !$0.isCompleted }.count
        let remainingBlocks = schedule.filter { endDateToday(for: $0, now: now) > now }.count

        let title: String
        let message: String
        let tint: Color

        if schoolQuietHoursEnabled && afterHours {
            title = "After Hours Boundary"
            message = "School alerts are quiet after \(quietStart.formatted(date: .omitted, time: .shortened)). \(unfinishedTasks) task\(unfinishedTasks == 1 ? "" : "s") can wait until tomorrow unless you choose otherwise."
            tint = .indigo
        } else if schoolQuietHoursEnabled {
            title = "School Boundary Set"
            message = "Routine school alerts quiet at \(quietStart.formatted(date: .omitted, time: .shortened)). \(remainingBlocks) block\(remainingBlocks == 1 ? "" : "s") remain in today's school flow."
            tint = .teal
        } else {
            title = "Protect Personal Time"
            message = "Set an after-hours quiet time so school reminders stop following you home."
            tint = .secondary
        }

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: afterHours ? "moon.stars.fill" : "lock.shield.fill")
                    .font(compact ? .headline : .title3)
                    .foregroundStyle(tint)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font((compact ? Font.subheadline : .headline).weight(.bold))

                    Text(message)
                        .font(compact ? .caption : .subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                Button("Settings") {
                    openSettingsTab()
                }
                .font(.caption.weight(.bold))
            }
        }
        .padding(compact ? 12 : 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(tint.opacity(0.16), lineWidth: 1)
        )
    }

    private func endOfDayCard(now: Date, schedule: [AlarmItem], compact: Bool = false) -> some View {
        let remainingBlocks = schedule.filter { endDateToday(for: $0, now: now) > now }
        let unfinishedTasks = todos.filter { !$0.isCompleted }.count
        let dismissal = remainingBlocks.last.map { endDateToday(for: $0, now: now) }
        let carryoverTasks = todos.filter { !$0.isCompleted && $0.bucket == .today }

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("End of Day", systemImage: "sunset.fill")
                    .font((compact ? Font.subheadline : .headline).weight(.bold))

                Spacer()
            }

            if remainingBlocks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("The teaching day is wrapped. \(unfinishedTasks) task\(unfinishedTasks == 1 ? "" : "s") still open.")
                        .font(compact ? .caption : .subheadline)
                        .foregroundStyle(.secondary)

                    if !carryoverTasks.isEmpty {
                        Text("\(carryoverTasks.count) task\(carryoverTasks.count == 1 ? "" : "s") are still marked for today.")
                            .font(compact ? .caption2 : .caption)
                            .foregroundStyle(.secondary)

                        if !compact {
                            ForEach(carryoverTasks.prefix(3)) { task in
                                Text("• \(task.task)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }

                        Button("Roll Today's Tasks to Tomorrow") {
                            rollTodayTasksToTomorrow()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.indigo)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(remainingBlocks.count) block\(remainingBlocks.count == 1 ? "" : "s") remain, with dismissal around \(dismissal?.formatted(date: .omitted, time: .shortened) ?? "later").")
                        .font(compact ? .caption : .subheadline)
                        .foregroundStyle(.secondary)

                    Text("\(unfinishedTasks) open task\(unfinishedTasks == 1 ? "" : "s") still need attention.")
                        .font(compact ? .caption2 : .caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(compact ? 12 : 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func overrideBanner(name: String) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.14))
                    .frame(width: 34, height: 34)

                Image(systemName: "wand.and.stars")
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Today's Schedule Override")
                    .font(.subheadline.weight(.bold))

                Text(name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("ClassCue is running today from the override schedule.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button("Manage") {
                openScheduleTab()
            }
            .font(.caption.weight(.bold))
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.14),
                            Color.cyan.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blue.opacity(0.18), lineWidth: 1)
        )
    }

    private func adjustedTodaySchedule(for now: Date) -> [AlarmItem] {

        let weekday = Calendar.current.component(.weekday, from: now)

        let todaysItems = (overrideSchedule ?? alarms)
            .filter { $0.dayOfWeek == weekday }
            .sorted { $0.startTime < $1.startTime }

        var cumulativeOffset: TimeInterval = 0
        var adjustedItems: [AlarmItem] = []

        for item in todaysItems {
            var adjusted = item

            adjusted.start = item.start.addingTimeInterval(cumulativeOffset)

            let liveHold = liveHoldDuration(for: item, now: now)
            let extra = (extraTimeByItemID[item.id] ?? 0) + liveHold

            adjusted.end = item.end
                .addingTimeInterval(cumulativeOffset)
                .addingTimeInterval(extra)

            adjustedItems.append(adjusted)
            cumulativeOffset += extra
        }

        return adjustedItems
    }

    private func laterTodayItems(
        from schedule: [AlarmItem],
        now: Date,
        nextItem: AlarmItem?
    ) -> [AlarmItem] {
        let nextID = nextItem?.id

        return schedule
            .filter { startDateToday(for: $0, now: now) > now && $0.id != nextID }
            .prefix(3)
            .map { $0 }
    }

    private func commitmentsForToday(now: Date) -> [CommitmentItem] {
        let weekday = Calendar.current.component(.weekday, from: now)

        return commitments
            .filter { $0.dayOfWeek == weekday }
            .sorted { lhs, rhs in
                let lhsStart = anchoredDate(for: lhs.startTime, now: now)
                let rhsStart = anchoredDate(for: rhs.startTime, now: now)
                return lhsStart < rhsStart
            }
    }

    private func topTasks(for now: Date) -> [TodoItem] {
        todos
            .filter { !$0.isCompleted }
            .sorted { lhs, rhs in
                let lhsBucket = bucketRank(lhs.bucket)
                let rhsBucket = bucketRank(rhs.bucket)

                if lhsBucket != rhsBucket {
                    return lhsBucket < rhsBucket
                }

                let lhsRank = priorityRank(lhs.priority)
                let rhsRank = priorityRank(rhs.priority)

                if lhsRank != rhsRank {
                    return lhsRank < rhsRank
                }

                switch (lhs.dueDate, rhs.dueDate) {
                case let (l?, r?):
                    return l < r
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                default:
                    return lhs.task.localizedCaseInsensitiveCompare(rhs.task) == .orderedAscending
                }
            }
            .prefix(3)
            .map { $0 }
    }

    private func taskSubtitle(for task: TodoItem) -> String {
        var parts = [task.category.displayName, task.bucket.displayName]

        if let due = task.dueDate {
            parts.append("Due \(due.formatted(date: .abbreviated, time: .omitted))")
        }

        if !task.linkedContext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parts.append(task.linkedContext)
        }

        if task.priority != .none {
            parts.append("\(task.priority.rawValue) Priority")
        }

        return parts.joined(separator: " • ")
    }

    private func priorityRank(_ priority: TodoItem.Priority) -> Int {
        switch priority {
        case .high: return 0
        case .med: return 1
        case .low: return 2
        case .none: return 3
        }
    }

    private func bucketRank(_ bucket: TodoItem.Bucket) -> Int {
        switch bucket {
        case .today: return 0
        case .tomorrow: return 1
        case .thisWeek: return 2
        case .later: return 3
        }
    }

    private func shouldShowDayStatus(now: Date, schedule: [AlarmItem], activeItem: AlarmItem?) -> Bool {
        if let ignoreDate, ignoreDate > now {
            return true
        }

        if activeItem != nil {
            return false
        }

        return schedule.isEmpty || schedule.contains { startDateToday(for: $0, now: now) > now }
    }

    private var notesSnapshot: String? {
        let trimmed = notesText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let normalized = trimmed
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(3)
            .joined(separator: " • ")

        return normalized.isEmpty ? nil : normalized
    }

    private var suggestedTaskContexts: [String] {
        let classContexts = (overrideSchedule ?? alarms)
            .map(\.className)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        let commitmentContexts = commitments
            .map(\.title)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        return Array(Set((classContexts + commitmentContexts).filter { !$0.isEmpty }))
            .sorted()
    }

    private func preferredCaptureContext(for schedule: [AlarmItem]) -> String? {
        let now = Date()
        if let active = schedule.first(where: {
            now >= startDateToday(for: $0, now: now) && now <= endDateToday(for: $0, now: now)
        }) {
            return active.className
        }

        return schedule.first(where: {
            startDateToday(for: $0, now: now) > now
        })?.className
    }

    private func preferredCaptureCategory(for schedule: [AlarmItem], now: Date) -> TodoItem.Category? {
        let item = schedule.first(where: {
            now >= startDateToday(for: $0, now: now) && now <= endDateToday(for: $0, now: now)
        }) ?? schedule.first(where: {
            startDateToday(for: $0, now: now) > now
        })

        guard let item else { return nil }

        switch item.type {
        case .math, .ela, .science, .socialStudies:
            return .prep
        case .prep:
            return .admin
        case .recess, .lunch, .transition:
            return .classroom
        case .other, .blank:
            return .other
        }
    }

    private func rollTodayTasksToTomorrow() {
        for index in todos.indices {
            if !todos[index].isCompleted && todos[index].bucket == .today {
                todos[index].bucket = .tomorrow
            }
        }
    }

    private func commitmentTimeText(for commitment: CommitmentItem) -> String {
        "\(commitment.startTime.formatted(date: .omitted, time: .shortened)) - \(commitment.endTime.formatted(date: .omitted, time: .shortened)) • \(commitment.kind.displayName)"
    }

    private func schoolQuietStart(on date: Date) -> Date {
        Calendar.current.date(
            bySettingHour: schoolQuietHour,
            minute: schoolQuietMinute,
            second: 0,
            of: date
        ) ?? date
    }

    private func isAfterSchoolQuietStart(_ now: Date) -> Bool {
        guard schoolQuietHoursEnabled else { return false }
        return now >= schoolQuietStart(on: now)
    }

    private func anchoredDate(for date: Date, now: Date) -> Date {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return Calendar.current.date(
            bySettingHour: components.hour ?? 0,
            minute: components.minute ?? 0,
            second: 0,
            of: now
        ) ?? now
    }

    private func startDateToday(for item: AlarmItem, now: Date) -> Date {

        let components = Calendar.current.dateComponents([.hour, .minute], from: item.startTime)

        return Calendar.current.date(
            bySettingHour: components.hour ?? 0,
            minute: components.minute ?? 0,
            second: 0,
            of: now
        ) ?? now
    }

    private func endDateToday(for item: AlarmItem, now: Date) -> Date {

        let components = Calendar.current.dateComponents([.hour, .minute], from: item.endTime)

        return Calendar.current.date(
            bySettingHour: components.hour ?? 0,
            minute: components.minute ?? 0,
            second: 0,
            of: now
        ) ?? now
    }

    private func warningForUpcomingBlock(_ item: AlarmItem?, now: Date) -> InAppWarning? {

        guard let item else { return nil }
        guard item.type != .blank else { return nil }

        let start = startDateToday(for: item, now: now)
        let secondsRemaining = Int(start.timeIntervalSince(now))

        switch secondsRemaining {
        case 300:
            return InAppWarning(item: item, minutesRemaining: 5)
        case 120:
            return InAppWarning(item: item, minutesRemaining: 2)
        case 60:
            return InAppWarning(item: item, minutesRemaining: 1)
        default:
            return nil
        }
    }

    private func secondaryBackgroundColor(for item: AlarmItem?) -> Color {

        guard let item else { return Color.cyan }

        switch item.type {
        case .math:
            return .orange
        case .ela:
            return .yellow
        case .science:
            return .green
        case .socialStudies:
            return .mint
        case .prep:
            return .cyan
        case .recess:
            return .teal
        case .lunch:
            return .pink
        case .transition:
            return Color(.systemGray5)
        case .other:
            return Color(.systemGray3)
        case .blank:
            return Color(.systemBackground)
        }
    }

    private func handleWarningTrigger(_ warning: InAppWarning?, key: String?) {

        guard let warning, let key else { return }
        guard lastWarningKey != key else { return }

        lastWarningKey = key
        warningDismissTask?.cancel()

        BellFeedbackManager.shared.playSelectedBellFeedback()

        withAnimation {
            activeWarning = warning
        }

        warningDismissTask = Task {
            try? await Task.sleep(for: .seconds(4))

            guard !Task.isCancelled else { return }

            await MainActor.run {
                withAnimation {
                    activeWarning = nil
                }
            }
        }
    }

    private func extend(_ item: AlarmItem, byMinutes minutes: Int) {
        extraTimeByItemID[item.id, default: 0] += TimeInterval(minutes * 60)
        skippedBellItemIDs.remove(item.id)
    }

    private func toggleHold(for item: AlarmItem, now: Date) {
        if heldItemID == item.id {
            let additionalHold = liveHoldDuration(for: item, now: now)
            extraTimeByItemID[item.id, default: 0] += additionalHold
            heldItemID = nil
            holdStartedAt = nil
        } else {
            heldItemID = item.id
            holdStartedAt = now
        }
    }

    private func skipBell(for item: AlarmItem) {
        skippedBellItemIDs.insert(item.id)
        BellCountdownEngine.shared.reset()
    }

    private func isHeld(_ item: AlarmItem) -> Bool {
        heldItemID == item.id
    }

    private func liveHoldDuration(for item: AlarmItem, now: Date) -> TimeInterval {
        guard heldItemID == item.id, let holdStartedAt else { return 0 }
        return max(now.timeIntervalSince(holdStartedAt), 0)
    }

    private func handleActiveItemChange(_ newValue: UUID?) {
        if lastActiveItemID != newValue {
            BellCountdownEngine.shared.reset()
            lastActiveItemID = newValue
        }

        if let heldItemID, heldItemID != newValue {
            self.heldItemID = nil
            holdStartedAt = nil
        }
    }

    private func processBellIfNeeded(_ activeItem: AlarmItem?, now: Date) {
        guard let activeItem else {
            BellCountdownEngine.shared.reset()
            return
        }

        guard !skippedBellItemIDs.contains(activeItem.id) else { return }

        let secondsRemaining = Int(ceil(endDateToday(for: activeItem, now: now).timeIntervalSince(now)))
        BellCountdownEngine.shared.process(secondsRemaining: secondsRemaining)
    }

    private func liveActivityState(for activeItem: AlarmItem?, now: Date) -> LiveActivitySnapshot? {
        guard let activeItem else { return nil }

        let room = activeItem.location.trimmingCharacters(in: .whitespacesAndNewlines)
        let liveHold = liveHoldDuration(for: activeItem, now: now)
        let stableEndTime = endDateToday(for: activeItem, now: now).addingTimeInterval(-liveHold)

        return LiveActivitySnapshot(
            className: activeItem.className,
            room: room,
            endTime: stableEndTime,
            isHeld: isHeld(activeItem)
        )
    }

    private func sessionActionButton(for item: AlarmItem) -> some View {
        Button {
            showingSessionActions = true
        } label: {
            Label(isHeld(item) ? "Controls • On Hold" : "Class Controls", systemImage: "slider.horizontal.3")
                .font(.subheadline.weight(.bold))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(item.accentColor.opacity(0.35), lineWidth: 1)
                )
        }
        .foregroundStyle(.primary)
        .shadow(color: item.accentColor.opacity(0.18), radius: 14, y: 8)
    }

    private func syncLiveActivity(with snapshot: LiveActivitySnapshot?) {
        guard let snapshot else {
            LiveActivityManager.stop()
            return
        }

        LiveActivityManager.sync(
            className: snapshot.className,
            room: snapshot.room,
            endTime: snapshot.endTime,
            isHeld: snapshot.isHeld
        )
    }

    private func landscapeHeader(now: Date) -> some View {

        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(now.formatted(.dateTime.weekday(.wide)).uppercased())
                    .font(.caption.weight(.bold))
                    .tracking(2.4)
                    .foregroundStyle(.orange)

                Text(now.formatted(.dateTime.month().day()))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
            }

            Spacer()

            Text(now.formatted(.dateTime.hour().minute().second()))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 4)
    }
}

private struct InAppWarning: Identifiable, Equatable {
    let item: AlarmItem
    let minutesRemaining: Int

    var id: String {
        "\(item.id.uuidString)-\(minutesRemaining)"
    }

    var title: String {
        switch minutesRemaining {
        case 5:
            return "5 Minute Warning"
        case 2:
            return "2 Minute Warning"
        default:
            return "1 Minute Warning"
        }
    }

    var accentColor: Color {
        switch minutesRemaining {
        case 5:
            return .yellow
        case 2:
            return .orange
        default:
            return .red
        }
    }

    var roomText: String {
        let trimmed = item.location.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Room not set" : trimmed
    }

    var timeText: String {
        "\(item.start.formatted(date: .omitted, time: .shortened)) - \(item.end.formatted(date: .omitted, time: .shortened))"
    }
}

private struct LiveActivitySnapshot: Equatable {
    let className: String
    let room: String
    let endTime: Date
    let isHeld: Bool
}

private struct InAppWarningBanner: View {
    let warning: InAppWarning

    @State private var pulse = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(warning.accentColor.opacity(0.18))
                    .frame(width: 52, height: 52)
                    .scaleEffect(pulse ? 1.18 : 0.92)
                    .opacity(pulse ? 0.15 : 0.45)

                Image(systemName: "bell.badge.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(warning.accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(warning.title.uppercased())
                    .font(.caption.weight(.black))
                    .tracking(1.2)
                    .foregroundStyle(warning.accentColor)

                Text(warning.item.className)
                    .font(.headline.weight(.bold))
                    .lineLimit(1)

                Text("\(warning.timeText) • \(warning.roomText)")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(warning.accentColor.opacity(0.55), lineWidth: 1.5)
                )
                .shadow(color: warning.accentColor.opacity(0.18), radius: 18, y: 8)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
