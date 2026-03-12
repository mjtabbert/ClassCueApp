//
//  TodoListView.swift
//  ClassCue
//
//  Created by Mr. Mike on 3/7/26 at 3:20 PM
//  Version: ClassCue Dev Build 11.2
//

import SwiftUI

struct TodoListView: View {

    @Binding var todos: [TodoItem]
    let suggestedContexts: [String]

    enum CategoryFilter: String, CaseIterable {
        case all
        case prep
        case grading
        case parentContact
        case copies
        case meetingFollowUp
        case admin
        case classroom
        case other

        var displayName: String {
            switch self {
            case .all: return "All"
            case .prep: return TodoItem.Category.prep.displayName
            case .grading: return TodoItem.Category.grading.displayName
            case .parentContact: return TodoItem.Category.parentContact.displayName
            case .copies: return TodoItem.Category.copies.displayName
            case .meetingFollowUp: return TodoItem.Category.meetingFollowUp.displayName
            case .admin: return TodoItem.Category.admin.displayName
            case .classroom: return TodoItem.Category.classroom.displayName
            case .other: return TodoItem.Category.other.displayName
            }
        }

        var category: TodoItem.Category? {
            switch self {
            case .all: return nil
            case .prep: return .prep
            case .grading: return .grading
            case .parentContact: return .parentContact
            case .copies: return .copies
            case .meetingFollowUp: return .meetingFollowUp
            case .admin: return .admin
            case .classroom: return .classroom
            case .other: return .other
            }
        }
    }

    @State private var showAdd = false
    @State private var editingTodo: TodoItem?
    @State private var showingQuickCapture = false
    @State private var categoryFilter: CategoryFilter = .all

    init(
        todos: Binding<[TodoItem]>,
        suggestedContexts: [String] = []
    ) {
        _todos = todos
        self.suggestedContexts = suggestedContexts
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(TodoItem.Bucket.allCases, id: \.self) { bucket in
                    let bucketItems = items(for: bucket)

                    if !bucketItems.isEmpty {
                        Section(bucket.displayName) {
                            ForEach(bucketItems) { item in
                                todoRow(for: item)
                            }
                            .onDelete { offsets in
                                deleteTodo(at: offsets, in: bucketItems)
                            }
                        }
                    }
                }
            }
            .navigationTitle("To Do")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if todos.contains(where: { $0.isCompleted }) {
                        Button("Clear Done") {
                            todos.removeAll { $0.isCompleted }
                        }
                        .foregroundColor(.red)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Menu {
                            Picker("Category", selection: $categoryFilter) {
                                ForEach(CategoryFilter.allCases, id: \.self) { filter in
                                    Text(filter.displayName).tag(filter)
                                }
                            }
                        } label: {
                            Image(systemName: categoryFilter == .all ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                        }

                        Button {
                            showingQuickCapture = true
                        } label: {
                            Image(systemName: "bolt.badge.plus")
                        }

                        Button {
                            showAdd = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddTodoView(todos: $todos, suggestedContexts: suggestedContexts)
            }
            .sheet(isPresented: $showingQuickCapture) {
                QuickCaptureView(todos: $todos, suggestedContexts: suggestedContexts)
            }
            .sheet(item: $editingTodo) { todo in
                AddTodoView(todos: $todos, suggestedContexts: suggestedContexts, existing: todo)
            }
        }
    }

    private func items(for bucket: TodoItem.Bucket) -> [TodoItem] {
        todos
            .filter { $0.bucket == bucket }
            .filter { item in
                guard let category = categoryFilter.category else { return true }
                return item.category == category
            }
            .sorted { a, b in
                if a.isCompleted != b.isCompleted {
                    return !a.isCompleted
                }

                if priorityRank(a.priority) != priorityRank(b.priority) {
                    return priorityRank(a.priority) < priorityRank(b.priority)
                }

                switch (a.dueDate, b.dueDate) {
                case let (lhs?, rhs?):
                    return lhs < rhs
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                case (nil, nil):
                    return a.task.localizedCaseInsensitiveCompare(b.task) == .orderedAscending
                }
            }
    }

    private func todoRow(for item: TodoItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(item.isCompleted ? .green : item.priority.color)
                .font(.title3)
                .onTapGesture {
                    toggleCompletion(for: item)
                }

            VStack(alignment: .leading, spacing: 5) {
                Text(item.task)
                    .strikethrough(item.isCompleted)
                    .foregroundColor(item.isCompleted ? .secondary : .primary)

                HStack(spacing: 6) {
                    Label(item.category.displayName, systemImage: item.category.systemImage)
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(item.category.tint)

                    Text("•")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text("Priority: \(item.priority.rawValue)")
                        .font(.caption2)
                        .foregroundColor(item.priority.color)
                }

                Text(dueDateText(for: item))
                    .font(.caption2)
                    .foregroundColor(.secondary)

                if !item.linkedContext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(item.linkedContext)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button {
                editingTodo = item
            } label: {
                Image(systemName: "pencil.circle")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
    }

    private func toggleCompletion(for item: TodoItem) {
        if let index = todos.firstIndex(where: { $0.id == item.id }) {
            todos[index].isCompleted.toggle()
        }
    }

    private func deleteTodo(at offsets: IndexSet, in bucketItems: [TodoItem]) {
        let idsToDelete = offsets.map { bucketItems[$0].id }
        todos.removeAll { idsToDelete.contains($0.id) }
    }

    private func dueDateText(for item: TodoItem) -> String {
        if let due = item.dueDate {
            return "Due: \(due.formatted(date: .abbreviated, time: .omitted))"
        } else {
            return "No due date"
        }
    }

    private func priorityRank(_ priority: TodoItem.Priority) -> Int {
        switch priority {
        case .high: return 0
        case .med: return 1
        case .low: return 2
        case .none: return 3
        }
    }
}

#Preview {
    TodoListView(
        todos: .constant([
            TodoItem(task: "Prep math lesson", priority: .high, dueDate: Date()),
            TodoItem(task: "Print spelling sheets", isCompleted: true, priority: .low, dueDate: nil),
            TodoItem(task: "Email parent update", priority: .med, dueDate: nil)
        ]),
        suggestedContexts: []
    )
}
