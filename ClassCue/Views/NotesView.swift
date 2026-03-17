import SwiftUI
import SwiftData
import UIKit

struct NotesView: View {
    enum NotesMode: String, CaseIterable {
        case general
        case personal
        case classNotes
        case studentNotes

        var title: String {
            switch self {
            case .general:
                return "School"
            case .personal:
                return "Personal"
            case .classNotes:
                return "Class Notes"
            case .studentNotes:
                return "Student"
            }
        }

        var preferredKind: FollowUpNoteItem.Kind {
            switch self {
            case .general:
                return .generalNote
            case .personal:
                return .personalNote
            case .classNotes:
                return .classNote
            case .studentNotes:
                return .studentNote
            }
        }

        var exportTitle: String {
            switch self {
            case .general:
                return "Class Trax School Notes Export"
            case .personal:
                return "Class Trax Personal Notes Export"
            case .classNotes:
                return "Class Trax Class Notes Export"
            case .studentNotes:
                return "Class Trax Student Notes Export"
            }
        }
    }

    @Binding var studentProfiles: [StudentSupportProfile]
    @Binding var classDefinitions: [ClassDefinitionItem]
    let suggestedContexts: [String]
    let suggestedStudents: [String]
    let onRefresh: @MainActor () -> Void
    let openTodayTab: () -> Void

    @AppStorage("notes_v1") private var notesText: String = ""
    @AppStorage("personal_notes_v1") private var personalNotesText: String = ""
    @AppStorage("follow_up_notes_v1_data") private var savedFollowUpNotes: Data = Data()
    @AppStorage("notes_v2_migrated") private var didMigrateLegacyTextNotes = false

    @State private var showingShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var showClearConfirm = false
    @State private var notesMode: NotesMode = .general
    @State private var selectedContextFilter = ""
    @State private var selectedStudentFilter = ""
    @State private var showingAddFollowUp = false
    @State private var addPreferredKind: FollowUpNoteItem.Kind?
    @State private var editingFollowUp: FollowUpNoteItem?
    @State private var showingStudentDirectory = false
    @State private var showingExportComposer = false

    init(
        studentProfiles: Binding<[StudentSupportProfile]>,
        classDefinitions: Binding<[ClassDefinitionItem]>,
        suggestedContexts: [String] = [],
        suggestedStudents: [String] = [],
        onRefresh: @escaping @MainActor () -> Void,
        openTodayTab: @escaping () -> Void
    ) {
        _studentProfiles = studentProfiles
        _classDefinitions = classDefinitions
        self.suggestedContexts = suggestedContexts
        self.suggestedStudents = suggestedStudents
        self.onRefresh = onRefresh
        self.openTodayTab = openTodayTab
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("View", selection: $notesMode) {
                    ForEach(NotesMode.allCases, id: \.self) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 8)

                currentModeView
            }
            .navigationTitle("Notes")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    if !currentModeNotes.isEmpty {
                        Button("Clear") {
                            showClearConfirm = true
                        }
                        .foregroundColor(.red)
                    }
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Menu("Actions") {
                        Button("Add Note", systemImage: "square.and.pencil") {
                            presentAddNote()
                        }

                        Button("Students", systemImage: "person.3") {
                            showingStudentDirectory = true
                        }

                        Button("Refresh", systemImage: "arrow.clockwise") {
                            onRefresh()
                        }

                        Button("Daily Sub Plan", systemImage: "doc.text") {
                            openTodayTab()
                        }
                    }

                    Button {
                        presentAddNote()
                    } label: {
                        Image(systemName: "plus")
                    }

                    if !currentModeNotes.isEmpty {
                        Button("Export") {
                            showingExportComposer = true
                        }
                    }
                }
            }
            .confirmationDialog(
                "Clear all notes?",
                isPresented: $showClearConfirm,
                titleVisibility: .visible
            ) {
                Button("Clear Notes", role: .destructive) {
                    clearCurrentNotes()
                }

                Button("Cancel", role: .cancel) { }
            }
            .sheet(isPresented: $showingShareSheet) {
                NotesShareSheet(activityItems: shareItems)
            }
            .sheet(isPresented: $showingAddFollowUp) {
                AddFollowUpNoteView(
                    notes: followUpNotesBinding,
                    suggestedContexts: suggestedContexts,
                    suggestedStudents: suggestedStudents,
                    preferredKind: addPreferredKind
                )
            }
            .sheet(item: $editingFollowUp) { note in
                AddFollowUpNoteView(
                    notes: followUpNotesBinding,
                    suggestedContexts: suggestedContexts,
                    suggestedStudents: suggestedStudents,
                    preferredKind: nil,
                    existing: note
                )
            }
            .sheet(isPresented: $showingStudentDirectory) {
                NavigationStack {
                    StudentDirectoryView(profiles: $studentProfiles, classDefinitions: $classDefinitions)
                }
            }
            .sheet(isPresented: $showingExportComposer) {
                NotesExportComposerView(
                    notes: currentModeNotes,
                    title: notesMode.exportTitle
                ) { items in
                    shareItems = items
                    showingShareSheet = true
                }
            }
            .onAppear {
                migrateLegacyTextNotesIfNeeded()
            }
        }
    }

    @ViewBuilder
    private var currentModeView: some View {
        switch notesMode {
        case .general:
            basicNotesView(
                notes: notes(for: .generalNote),
                emptyTitle: "No School Notes Yet",
                emptySystemImage: "building.2.crop.circle",
                emptyDescription: "Tap + to create a school note."
            )
        case .personal:
            basicNotesView(
                notes: notes(for: .personalNote),
                emptyTitle: "No Personal Notes Yet",
                emptySystemImage: "person.crop.circle.badge.plus",
                emptyDescription: "Tap + to create a personal note."
            )
        case .classNotes:
            classFollowUpView
        case .studentNotes:
            studentNotesView
        }
    }

    private func basicNotesView(
        notes: [FollowUpNoteItem],
        emptyTitle: String,
        emptySystemImage: String,
        emptyDescription: String
    ) -> some View {
        List {
            if notes.isEmpty {
                Section {
                    ContentUnavailableView(
                        emptyTitle,
                        systemImage: emptySystemImage,
                        description: Text(emptyDescription)
                    )
                }
            } else {
                ForEach(notes) { note in
                    noteRow(note)
                }
                .onDelete { offsets in
                    deleteFollowUpNotes(at: offsets, from: notes)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func noteRow(_ note: FollowUpNoteItem) -> some View {
        Button {
            editingFollowUp = note
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(note.kind.title)
                    .font(.subheadline.weight(.semibold))

                Text(note.note)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(5)

                let metadata = noteMetadata(note)
                if !metadata.isEmpty {
                    Text(metadata)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    private var currentModeNotes: [FollowUpNoteItem] {
        switch notesMode {
        case .general:
            return notes(for: .generalNote)
        case .personal:
            return notes(for: .personalNote)
        case .classNotes:
            return followUpNotes
                .filter { $0.kind == .classNote }
                .filter { selectedContextFilter.isEmpty || $0.context == selectedContextFilter }
                .sorted { $0.createdAt > $1.createdAt }
        case .studentNotes:
            return followUpNotes
                .filter { $0.kind == .studentNote || $0.kind == .parentContact }
                .filter { selectedStudentFilter.isEmpty || $0.studentOrGroup == selectedStudentFilter }
                .sorted { $0.createdAt > $1.createdAt }
        }
    }

    private func notes(for kind: FollowUpNoteItem.Kind) -> [FollowUpNoteItem] {
        followUpNotes
            .filter { $0.kind == kind }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private func noteMetadata(_ note: FollowUpNoteItem) -> String {
        var parts: [String] = []

        let context = note.context.trimmingCharacters(in: .whitespacesAndNewlines)
        let student = note.studentOrGroup.trimmingCharacters(in: .whitespacesAndNewlines)

        if !context.isEmpty {
            parts.append(context)
        }

        if !student.isEmpty {
            parts.append(student)
        }

        parts.append(note.createdAt.formatted(date: .abbreviated, time: .shortened))
        return parts.joined(separator: " • ")
    }

    private func presentAddNote() {
        addPreferredKind = notesMode.preferredKind
        showingAddFollowUp = true
    }

    private func clearCurrentNotes() {
        let kindsToRemove: Set<FollowUpNoteItem.Kind>
        switch notesMode {
        case .general:
            kindsToRemove = [.generalNote]
        case .personal:
            kindsToRemove = [.personalNote]
        case .classNotes:
            kindsToRemove = [.classNote]
        case .studentNotes:
            kindsToRemove = [.studentNote, .parentContact]
        }

        var updated = followUpNotes
        updated.removeAll { kindsToRemove.contains($0.kind) }
        persistFollowUpNotes(updated)
    }

    private var classFollowUpView: some View {
        let groups = followUpGroups

        return List {
            if !suggestedContexts.isEmpty {
                Section("Filter") {
                    Picker("Class or Commitment", selection: $selectedContextFilter) {
                        Text("All Classes").tag("")
                        ForEach(suggestedContexts, id: \.self) { context in
                            Text(context).tag(context)
                        }
                    }
                }
            }

            if groups.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No Class Notes Yet",
                        systemImage: "note.text.badge.plus",
                        description: Text("Tap + to create a class note.")
                    )
                }
            } else {
                ForEach(groups, id: \.context) { group in
                    Section(group.context) {
                        if !group.notes.isEmpty {
                            ForEach(group.notes) { note in
                                noteRow(note)
                            }
                            .onDelete { offsets in
                                deleteFollowUpNotes(at: offsets, from: group.notes)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var studentNotesView: some View {
        let groups = studentNoteGroups

        return List {
            if !suggestedStudents.isEmpty {
                Section("Filter") {
                    Picker("Student or Group", selection: $selectedStudentFilter) {
                        Text("All Students").tag("")
                        ForEach(suggestedStudents, id: \.self) { student in
                            Text(student).tag(student)
                        }
                    }
                }
            }

            if groups.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No Student Notes Yet",
                        systemImage: "person.text.rectangle",
                        description: Text("Tap + to create a student note or parent contact.")
                    )
                }
            } else {
                ForEach(groups, id: \.student) { group in
                    Section {
                        if let context = group.context, !context.isEmpty {
                            Text(context)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        ForEach(group.notes) { note in
                            noteRow(note)
                        }
                        .onDelete { offsets in
                            deleteFollowUpNotes(at: offsets, from: group.notes)
                        }
                    } header: {
                        HStack(spacing: 6) {
                            Text(group.student)

                            if let matchedStudent = studentProfile(named: group.student) {
                                gradePill(matchedStudent.gradeLevel)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var followUpGroups: [(context: String, notes: [FollowUpNoteItem])] {
        let notesByContext = Dictionary(grouping: followUpNotes.filter {
            $0.kind == .classNote &&
            !$0.context.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }) { $0.context }

        let contexts = Set(notesByContext.keys).sorted {
            $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
        }

        return contexts
            .filter { selectedContextFilter.isEmpty || $0 == selectedContextFilter }
            .map { context in
                let notes = (notesByContext[context] ?? []).sorted { $0.createdAt > $1.createdAt }
                return (context: context, notes: notes)
            }
    }

    private var followUpNotes: [FollowUpNoteItem] {
        guard !savedFollowUpNotes.isEmpty else { return [] }
        return (try? JSONDecoder().decode([FollowUpNoteItem].self, from: savedFollowUpNotes)) ?? []
    }

    private var studentNoteGroups: [(student: String, context: String?, notes: [FollowUpNoteItem])] {
        let grouped = Dictionary(grouping: followUpNotes.filter {
            ($0.kind == .studentNote || $0.kind == .parentContact) &&
            !$0.studentOrGroup.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }) { $0.studentOrGroup }

        return grouped
            .map { student, notes in
                let sortedNotes = notes.sorted { $0.createdAt > $1.createdAt }
                let context = sortedNotes.first?.context.trimmingCharacters(in: .whitespacesAndNewlines)
                return (student: student, context: context?.isEmpty == true ? nil : context, notes: sortedNotes)
            }
            .filter { selectedStudentFilter.isEmpty || $0.student == selectedStudentFilter }
            .sorted { $0.student.localizedCaseInsensitiveCompare($1.student) == .orderedAscending }
    }

    private var followUpNotesBinding: Binding<[FollowUpNoteItem]> {
        Binding(
            get: { followUpNotes },
            set: { newValue in
                persistFollowUpNotes(newValue)
            }
        )
    }

    private func deleteFollowUpNotes(at offsets: IndexSet, from groupNotes: [FollowUpNoteItem]) {
        let ids = offsets.map { groupNotes[$0].id }
        var updated = followUpNotes
        updated.removeAll { ids.contains($0.id) }
        persistFollowUpNotes(updated)
    }

    private func persistFollowUpNotes(_ notes: [FollowUpNoteItem]) {
        savedFollowUpNotes = (try? JSONEncoder().encode(notes)) ?? Data()
        syncLegacyNoteTextStorage(from: notes, schoolNotesText: &notesText, personalNotesText: &personalNotesText)
    }

    private func migrateLegacyTextNotesIfNeeded() {
        if didMigrateLegacyTextNotes {
            syncLegacyNoteTextStorage(from: followUpNotes, schoolNotesText: &notesText, personalNotesText: &personalNotesText)
            return
        }

        var updated = followUpNotes
        let trimmedSchoolNotes = notesText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPersonalNotes = personalNotesText.trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmedSchoolNotes.isEmpty && !updated.contains(where: { $0.kind == .generalNote }) {
            updated.insert(FollowUpNoteItem(kind: .generalNote, context: "", studentOrGroup: "", note: trimmedSchoolNotes), at: 0)
        }

        if !trimmedPersonalNotes.isEmpty && !updated.contains(where: { $0.kind == .personalNote }) {
            updated.insert(FollowUpNoteItem(kind: .personalNote, context: "", studentOrGroup: "", note: trimmedPersonalNotes), at: 0)
        }

        if updated != followUpNotes {
            persistFollowUpNotes(updated)
        } else {
            syncLegacyNoteTextStorage(from: updated, schoolNotesText: &notesText, personalNotesText: &personalNotesText)
        }

        didMigrateLegacyTextNotes = true
    }

    private func studentProfile(named name: String) -> StudentSupportProfile? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return nil }
        return studentProfiles.first {
            $0.name.trimmingCharacters(in: .whitespacesAndNewlines)
                .localizedCaseInsensitiveCompare(trimmedName) == .orderedSame
        }
    }

    private func gradePill(_ gradeLevel: String) -> some View {
        Text(GradeLevelOption.pillLabel(for: gradeLevel))
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(GradeLevelOption.color(for: gradeLevel))
            )
    }
}

private struct NotesExportComposerView: View {
    enum ExportScope: String, CaseIterable {
        case current
        case currentPlusSelected
        case all

        var title: String {
            switch self {
            case .current:
                return "Current Note"
            case .currentPlusSelected:
                return "Current + Others"
            case .all:
                return "All Notes"
            }
        }
    }

    enum ExportFormat: String, CaseIterable {
        case text
        case pdf

        var title: String {
            rawValue.uppercased()
        }
    }

    let notes: [FollowUpNoteItem]
    let title: String
    let onExport: ([Any]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var currentNoteID: UUID
    @State private var exportScope: ExportScope = .current
    @State private var exportFormat: ExportFormat = .text
    @State private var selectedOtherIDs: Set<UUID> = []

    init(notes: [FollowUpNoteItem], title: String, onExport: @escaping ([Any]) -> Void) {
        self.notes = notes
        self.title = title
        self.onExport = onExport
        _currentNoteID = State(initialValue: notes.first?.id ?? UUID())
    }

    var body: some View {
        NavigationStack {
            Form {
                if !notes.isEmpty {
                    Section("Current Note") {
                        Picker("Current", selection: $currentNoteID) {
                            ForEach(notes) { note in
                                Text(exportSummary(for: note)).tag(note.id)
                            }
                        }
                    }

                    Section("Include") {
                        Picker("Scope", selection: $exportScope) {
                            ForEach(ExportScope.allCases, id: \.self) { scope in
                                Text(scope.title).tag(scope)
                            }
                        }

                        if exportScope == .currentPlusSelected {
                            ForEach(otherNotes) { note in
                                Toggle(isOn: binding(for: note.id)) {
                                    Text(exportSummary(for: note))
                                }
                            }
                        }
                    }

                    Section("Format") {
                        Picker("Export As", selection: $exportFormat) {
                            ForEach(ExportFormat.allCases, id: \.self) { format in
                                Text(format.title).tag(format)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
            }
            .navigationTitle("Export Notes")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Export") {
                        export()
                    }
                    .disabled(notes.isEmpty)
                }
            }
        }
    }

    private var currentNote: FollowUpNoteItem? {
        notes.first(where: { $0.id == currentNoteID }) ?? notes.first
    }

    private var otherNotes: [FollowUpNoteItem] {
        guard let currentNote else { return [] }
        return notes.filter { $0.id != currentNote.id }
    }

    private func binding(for id: UUID) -> Binding<Bool> {
        Binding(
            get: { selectedOtherIDs.contains(id) },
            set: { isSelected in
                if isSelected {
                    selectedOtherIDs.insert(id)
                } else {
                    selectedOtherIDs.remove(id)
                }
            }
        )
    }

    private func export() {
        let selectedNotes = selectedNotesForExport()
        let exportText = classCueNotesExportText(notes: notesExportBody(for: selectedNotes), title: title)

        switch exportFormat {
        case .text:
            onExport([exportText])
        case .pdf:
            if let pdfURL = makeNotesPDF(title: title, body: exportText) {
                onExport([pdfURL])
            } else {
                onExport([exportText])
            }
        }

        dismiss()
    }

    private func selectedNotesForExport() -> [FollowUpNoteItem] {
        switch exportScope {
        case .current:
            return currentNote.map { [$0] } ?? []
        case .currentPlusSelected:
            guard let currentNote else { return [] }
            let extras = notes.filter { selectedOtherIDs.contains($0.id) }
            return [currentNote] + extras
        case .all:
            return notes
        }
    }

    private func exportSummary(for note: FollowUpNoteItem) -> String {
        let trimmed = note.note.trimmingCharacters(in: .whitespacesAndNewlines)
        let firstLine = trimmed.components(separatedBy: .newlines).first ?? note.kind.title
        let cleaned = firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? note.kind.title : String(cleaned.prefix(40))
    }
}

private struct NotesShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
    }
}

func classCueNotesExportText(notes: String, title: String = "Class Trax Notes Export") -> String {
    let dateOnlyFormatter = DateFormatter()
    dateOnlyFormatter.dateStyle = .long
    dateOnlyFormatter.timeStyle = .none

    let timeOnlyFormatter = DateFormatter()
    timeOnlyFormatter.dateStyle = .none
    timeOnlyFormatter.timeStyle = .short

    let now = Date()

    return """
    \(title)
    \(dateOnlyFormatter.string(from: now))
    \(timeOnlyFormatter.string(from: now))

    \(notes)
    """
}

func notesExportBody(for notes: [FollowUpNoteItem]) -> String {
    notes.map { note in
        var lines = [note.kind.title]

        let context = note.context.trimmingCharacters(in: .whitespacesAndNewlines)
        if !context.isEmpty {
            lines.append("Context: \(context)")
        }

        let student = note.studentOrGroup.trimmingCharacters(in: .whitespacesAndNewlines)
        if !student.isEmpty {
            lines.append("Student/Group: \(student)")
        }

        lines.append("Created: \(note.createdAt.formatted(date: .abbreviated, time: .shortened))")
        lines.append("")
        lines.append(note.note)

        return lines.joined(separator: "\n")
    }
    .joined(separator: "\n\n---\n\n")
}

func syncLegacyNoteTextStorage(
    from notes: [FollowUpNoteItem],
    schoolNotesText: inout String,
    personalNotesText: inout String
) {
    schoolNotesText = legacyNoteText(from: notes, kind: .generalNote)
    personalNotesText = legacyNoteText(from: notes, kind: .personalNote)
}

private func legacyNoteText(from notes: [FollowUpNoteItem], kind: FollowUpNoteItem.Kind) -> String {
    notes
        .filter { $0.kind == kind }
        .sorted { $0.createdAt > $1.createdAt }
        .map(\.note)
        .joined(separator: "\n\n")
}

func decodeFollowUpNotes(from data: Data) -> [FollowUpNoteItem] {
    guard !data.isEmpty else { return [] }
    return (try? JSONDecoder().decode([FollowUpNoteItem].self, from: data)) ?? []
}

func decodeFollowUpNotesFromDefaults() -> [FollowUpNoteItem] {
    decodeFollowUpNotes(from: UserDefaults.standard.data(forKey: "follow_up_notes_v1_data") ?? Data())
}

private func makeNotesPDF(title: String, body: String) -> URL? {
    let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("\(title.replacingOccurrences(of: " ", with: "_"))-\(UUID().uuidString).pdf")

    let text = "\(title)\n\n\(body)"
    let paragraph = NSMutableParagraphStyle()
    paragraph.lineBreakMode = .byWordWrapping

    let attributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 14),
        .paragraphStyle: paragraph
    ]

    let attributed = NSAttributedString(string: text, attributes: attributes)
    let printableRect = CGRect(x: 36, y: 36, width: 540, height: 720)

    do {
        try renderer.writePDF(to: url) { context in
            var range = NSRange(location: 0, length: attributed.length)

            while range.location < attributed.length {
                context.beginPage()
                range = drawAttributedString(attributed, in: printableRect, range: range)
            }
        }
        return url
    } catch {
        return nil
    }
}

private func drawAttributedString(_ string: NSAttributedString, in rect: CGRect, range: NSRange) -> NSRange {
    let framesetter = CTFramesetterCreateWithAttributedString(string)
    let path = CGPath(rect: rect, transform: nil)
    let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(range.location, range.length), path, nil)
    CTFrameDraw(frame, UIGraphicsGetCurrentContext()!)
    let visibleRange = CTFrameGetVisibleStringRange(frame)
    return NSRange(location: range.location + visibleRange.length, length: string.length - range.location - visibleRange.length)
}
