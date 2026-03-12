//
//  QuickCaptureView.swift
//  ClassCue
//
//  Developer: Mr. Mike
//  Last Updated: March 12, 2026
//

import SwiftUI

struct QuickCaptureView: View {

    enum CaptureTarget: String, CaseIterable {
        case task
        case note

        var title: String {
            switch self {
            case .task: return "Task"
            case .note: return "Note"
            }
        }
    }

    @Binding var todos: [TodoItem]
    let suggestedContexts: [String]
    let preferredContext: String?
    let preferredCategory: TodoItem.Category?
    @AppStorage("notes_v1") private var notesText: String = ""

    @Environment(\.dismiss) private var dismiss

    @State private var target: CaptureTarget = .task
    @State private var text = ""
    @State private var category: TodoItem.Category = .prep
    @State private var linkedContext = ""

    init(
        todos: Binding<[TodoItem]>,
        suggestedContexts: [String] = [],
        preferredContext: String? = nil,
        preferredCategory: TodoItem.Category? = nil
    ) {
        _todos = todos
        self.suggestedContexts = suggestedContexts
        self.preferredContext = preferredContext
        self.preferredCategory = preferredCategory
        _category = State(initialValue: preferredCategory ?? .prep)
        _linkedContext = State(initialValue: preferredContext ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Capture", selection: $target) {
                        ForEach(CaptureTarget.allCases, id: \.self) { target in
                            Text(target.title).tag(target)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(target == .task ? "Task" : "Note") {
                    TextField(
                        target == .task ? "What needs to happen?" : "Quick note",
                        text: $text,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                }

                if target == .task {
                    Section("Teacher Context") {
                        Picker("Category", selection: $category) {
                            ForEach(TodoItem.Category.allCases, id: \.self) { category in
                                Label(category.displayName, systemImage: category.systemImage)
                                    .tag(category)
                            }
                        }

                        TextField("Class or Commitment (Optional)", text: $linkedContext)

                        if !suggestedContexts.isEmpty {
                            Picker("Suggested Link", selection: $linkedContext) {
                                Text("None").tag("")
                                if let preferredContext, !preferredContext.isEmpty {
                                    Text("Current Focus: \(preferredContext)").tag(preferredContext)
                                }
                                ForEach(suggestedContexts, id: \.self) { context in
                                    Text(context).tag(context)
                                }
                            }
                        }
                    }

                    Section("Save To") {
                        Button("Today") {
                            saveTask(bucket: .today)
                        }

                        Button("Tomorrow") {
                            saveTask(bucket: .tomorrow)
                        }

                        Button("This Week") {
                            saveTask(bucket: .thisWeek)
                        }

                        Button("Later") {
                            saveTask(bucket: .later)
                        }
                    }
                } else {
                    Section {
                        Button("Add Note") {
                            saveNote()
                        }
                    }
                }
            }
            .navigationTitle("Quick Capture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func saveTask(bucket: TodoItem.Bucket) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        todos.insert(
            TodoItem(
                task: trimmed,
                priority: .med,
                category: category,
                bucket: bucket,
                linkedContext: linkedContext.trimmingCharacters(in: .whitespacesAndNewlines)
            ),
            at: 0
        )

        dismiss()
    }

    private func saveNote() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if notesText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            notesText = trimmed
        } else {
            notesText = "\(trimmed)\n\n\(notesText)"
        }

        dismiss()
    }
}
