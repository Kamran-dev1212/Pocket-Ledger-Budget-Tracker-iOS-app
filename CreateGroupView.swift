import SwiftUI
import CloudKit

struct CreateGroupView: View {

    @Environment(\.dismiss) private var dismiss

    var onCreated: () -> Void

    @State private var groupName = ""
    @State private var isCreating = false
    @State private var createdGroup: SharedGroup?
    @State private var errorMessage = ""
    @State private var showError = false

    private var isNameValid: Bool {

        !groupName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty

    }

    var body: some View {

        NavigationStack {

            Form {

                Section("Group Name") {

                    TextField("e.g. Trip to Switzerland", text: $groupName)

                }

            }
            .navigationTitle("New Group")
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
                            await createGroup()
                        }

                    } label: {

                        if isCreating {

                            ProgressView()

                        } else {

                            Text("Create")
                                .fontWeight(.semibold)

                        }

                    }
                    .disabled(!isNameValid || isCreating)

                }

            }
            .sheet(
                item: $createdGroup,
                onDismiss: {

                    onCreated()
                    dismiss()

                }
            ) { group in

                InviteMembersView(group: group) { }

            }
            .alert("Could Not Create Group", isPresented: $showError) {

                Button("OK", role: .cancel) { }

            } message: {

                Text(errorMessage)

            }

        }

    }

    // MARK: - Create

    private func createGroup() async {

        isCreating = true

        let trimmedName = groupName
            .trimmingCharacters(in: .whitespacesAndNewlines)

        do {

            createdGroup = try await GroupSharingManager.shared.createGroup(
                named: trimmedName
            )

        } catch {

            print("GroupSharing: createGroup threw an error: \(error)")

            errorMessage = error.localizedDescription
            showError = true

        }

        isCreating = false

    }

}

#Preview {
    CreateGroupView(onCreated: {})
}
