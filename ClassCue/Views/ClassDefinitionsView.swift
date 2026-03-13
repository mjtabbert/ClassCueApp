import SwiftUI

struct ClassDefinitionsView: View {
    @Binding var classDefinitions: [ClassDefinitionItem]

    @State private var showingAdd = false
    @State private var editingDefinition: ClassDefinitionItem?

    var body: some View {
        List {
            Section {
                Text("Save your recurring classes here so schedule blocks and student profiles can link to the same exact class definition instead of relying only on text matching.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if classDefinitions.isEmpty {
                Section("Saved Classes") {
                    ContentUnavailableView(
                        "No Saved Classes Yet",
                        systemImage: "books.vertical",
                        description: Text("Add your classes once, then reuse them in schedules and student supports.")
                    )
                }
            } else {
                Section("Saved Classes") {
                    ForEach(classDefinitions) { definition in
                        Button {
                            editingDefinition = definition
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: definition.symbolName)
                                    .foregroundStyle(definition.themeColor)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(definition.name)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.primary)

                                    let detail = [
                                        definition.typeDisplayName,
                                        definition.gradeLevel,
                                        definition.defaultLocation
                                    ]
                                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                        .filter { !$0.isEmpty }
                                        .joined(separator: " • ")

                                    if !detail.isEmpty {
                                        Text(detail)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("Edit") {
                                editingDefinition = definition
                            }
                            .tint(.orange)

                            Button("Delete", role: .destructive) {
                                deleteDefinition(definition)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Saved Classes")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAdd = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            EditClassDefinitionView(classDefinitions: $classDefinitions, existing: nil)
        }
        .sheet(item: $editingDefinition) { definition in
            EditClassDefinitionView(classDefinitions: $classDefinitions, existing: definition)
        }
    }

    private func deleteDefinition(_ definition: ClassDefinitionItem) {
        classDefinitions.removeAll { $0.id == definition.id }
    }
}
