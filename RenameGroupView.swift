import SwiftUI

struct RenameGroupView: View {

    let group: SharedGroup
    var onRenamed: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var isSaving = false
    @State private var errorMessage = ""
    @State private var showError = false

    init(group: SharedGroup, onRenamed: @escaping () -> Void) {

        self.group = group
        self.onRenamed = onRenamed
        _name = State(initialValue: group.name)

    }

    private var isNameValid: Bool {

        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

    }

    var body: some View {

        NavigationStack {

            Form {

                Section("Group Name") {

                    TextField("Group name", text: $name)

                }

            }
            .navigationTitle("Rename Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(placement: .topBarLeading) {

                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(AppColors.textSecondary)

                }

                ToolbarItem(placement: .topBarTrailing) {

                    Button {

                        Task {
                            await save()
                        }

                    } label: {

                        if isSaving {

                            ProgressView()

                        } else {

                            Text("Save")
                                .fontWeight(.semibold)

                        }

                    }
                    .disabled(!isNameValid || isSaving)

                }

            }
            .alert("Could Not Rename Group", isPresented: $showError) {

                Button("OK", role: .cancel) { }

            } message: {

                Text(errorMessage)

            }

        }

    }

    private func save() async {

        isSaving = true

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        do {

            try await GroupSharingManager.shared.renameGroup(group, to: trimmedName)

            onRenamed()
            dismiss()

        } catch {

            errorMessage = error.localizedDescription
            showError = true

        }

        isSaving = false

    }

}
