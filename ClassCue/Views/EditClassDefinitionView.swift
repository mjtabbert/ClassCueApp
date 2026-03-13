import SwiftUI

struct EditClassDefinitionView: View {
    @Binding var classDefinitions: [ClassDefinitionItem]
    let existing: ClassDefinitionItem?

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var scheduleType: ClassDefinitionItem.ScheduleKind = .other
    @State private var gradeLevel = ""
    @State private var defaultLocation = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Class Details") {
                    TextField("Class Name", text: $name)

                    Picker("Type", selection: $scheduleType) {
                        ForEach(ClassDefinitionItem.ScheduleKind.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }

                    Picker("Grade Level", selection: $gradeLevel) {
                        Text("None").tag("")
                        ForEach(GradeLevelOption.optionsForPicker(), id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }

                    TextField("Default Room / Location", text: $defaultLocation)
                }
            }
            .navigationTitle(existing == nil ? "Add Class" : "Edit Class")
            .navigationBarTitleDisplayMode(.inline)
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
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                guard let existing else { return }
                name = existing.name
                scheduleType = existing.scheduleKind
                gradeLevel = GradeLevelOption.normalized(existing.gradeLevel)
                defaultLocation = existing.defaultLocation
            }
        }
    }

    private func save() {
        let item = ClassDefinitionItem(
            id: existing?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            scheduleType: scheduleType,
            gradeLevel: GradeLevelOption.normalized(gradeLevel),
            defaultLocation: defaultLocation.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        if let existing, let index = classDefinitions.firstIndex(where: { $0.id == existing.id }) {
            classDefinitions[index] = item
        } else {
            classDefinitions.append(item)
        }

        classDefinitions.sort { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
        dismiss()
    }
}
