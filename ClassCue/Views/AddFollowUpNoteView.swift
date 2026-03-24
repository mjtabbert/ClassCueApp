//
//  AddFollowUpNoteView.swift
//  ClassTrax
//
//  Created by Codex on 3/13/26.
//

import SwiftUI

struct AddFollowUpNoteView: View {
    @Binding var notes: [FollowUpNoteItem]
    let suggestedContexts: [String]
    let suggestedStudents: [String]
    let preferredKind: FollowUpNoteItem.Kind?
    let existing: FollowUpNoteItem?
    let initialNoteText: String

    @Environment(\.dismiss) private var dismiss

    @State private var kind: FollowUpNoteItem.Kind = .generalNote
    @State private var context = ""
    @State private var studentOrGroup = ""
    @State private var note = ""

    init(
        notes: Binding<[FollowUpNoteItem]>,
        suggestedContexts: [String],
        suggestedStudents: [String],
        preferredKind: FollowUpNoteItem.Kind? = nil,
        existing: FollowUpNoteItem? = nil,
        initialNoteText: String = ""
    ) {
        _notes = notes
        self.suggestedContexts = suggestedContexts
        self.suggestedStudents = suggestedStudents
        self.preferredKind = preferredKind
        self.existing = existing
        self.initialNoteText = initialNoteText
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Follow-Up") {
                    if preferredKind == nil {
                        Picker("Type", selection: $kind) {
                            ForEach(FollowUpNoteItem.Kind.allCases, id: \.self) { kind in
                                Text(kind.title).tag(kind)
                            }
                        }
                    } else {
                        LabeledContent("Type", value: kind.title)
                    }

                    if showsContextField {
                        if !suggestedContexts.isEmpty {
                            Picker(contextPickerTitle, selection: $context) {
                                if !contextIsRequired {
                                    Text("None").tag("")
                                }
                                ForEach(suggestedContexts, id: \.self) { context in
                                    Text(context).tag(context)
                                }
                            }
                        }

                        TextField(contextFieldTitle, text: $context)
                    }

                    if showsStudentField {
                        if !suggestedStudents.isEmpty {
                            Picker(studentPickerTitle, selection: $studentOrGroup) {
                                ForEach(suggestedStudents, id: \.self) { student in
                                    Text(student).tag(student)
                                }
                            }
                        }

                        TextField(studentFieldTitle, text: $studentOrGroup)
                    }

                    TextField("Note", text: $note, axis: .vertical)
                        .lineLimit(4...8)
                }
            }
            .navigationTitle(existing == nil ? "Add Follow-Up" : "Edit Follow-Up")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        save()
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear {
                if let existing {
                    kind = existing.kind
                    context = existing.context
                    studentOrGroup = existing.studentOrGroup
                    note = existing.note
                } else {
                    if let preferredKind {
                        kind = preferredKind
                    }
                    note = initialNoteText
                }
            }
            .onChange(of: kind) { _, newKind in
                switch newKind {
                case .classNote:
                    studentOrGroup = ""
                case .generalNote, .personalNote:
                    context = ""
                    studentOrGroup = ""
                case .studentNote, .parentContact:
                    break
                }
            }
        }
    }

    private var canSave: Bool {
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContext = context.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedStudent = studentOrGroup.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedNote.isEmpty else { return false }

        switch kind {
        case .generalNote, .personalNote:
            return true
        case .classNote:
            return !trimmedContext.isEmpty
        case .studentNote, .parentContact:
            return !trimmedStudent.isEmpty
        }
    }

    private var showsContextField: Bool {
        switch kind {
        case .generalNote, .personalNote:
            return false
        case .classNote, .studentNote, .parentContact:
            return true
        }
    }

    private var showsStudentField: Bool {
        switch kind {
        case .generalNote, .personalNote:
            return false
        case .classNote:
            return false
        case .studentNote, .parentContact:
            return true
        }
    }

    private var contextIsRequired: Bool {
        kind == .classNote
    }

    private var contextPickerTitle: String {
        contextIsRequired ? "Class" : "Class (Optional)"
    }

    private var contextFieldTitle: String {
        contextIsRequired ? "Class" : "Class (Optional)"
    }

    private var studentPickerTitle: String {
        switch kind {
        case .parentContact:
            return "Student / Family"
        default:
            return "Student"
        }
    }

    private var studentFieldTitle: String {
        switch kind {
        case .parentContact:
            return "Student / Family"
        default:
            return "Student"
        }
    }

    private func save() {
        let item = FollowUpNoteItem(
            id: existing?.id ?? UUID(),
            kind: kind,
            context: context.trimmingCharacters(in: .whitespacesAndNewlines),
            studentOrGroup: studentOrGroup.trimmingCharacters(in: .whitespacesAndNewlines),
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: existing?.createdAt ?? Date()
        )

        if let existing, let index = notes.firstIndex(where: { $0.id == existing.id }) {
            notes[index] = item
        } else {
            notes.insert(item, at: 0)
        }

        dismiss()
    }
}
