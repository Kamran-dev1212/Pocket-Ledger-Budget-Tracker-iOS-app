import SwiftUI
import CloudKit

struct CreateGroupView: View {

    @Environment(\.dismiss) private var dismiss

    var onCreated: () -> Void

    @State private var groupName = ""
    @State private var isCreating = false
    @State private var pendingShare: CKShare?
    @State private var showShareSheet = false
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
                isPresented: $showShareSheet,
                onDismiss: {

                    onCreated()
                    dismiss()

                }
            ) {

                if let pendingShare {

                    CloudSharingView(
                        share: pendingShare,
                        container: CKContainer(
                            identifier: "iCloud.com.kamranzaidi.pocketledger"
                        )
                    )

                }

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

        print("GroupSharing: create tapped")

        let trimmedName = groupName
            .trimmingCharacters(in: .whitespacesAndNewlines)

        do {

            let result = try await GroupSharingManager.shared.createGroup(
                named: trimmedName
            )

            print("GroupSharing: got share back, presenting sheet")

            pendingShare = result.share
            showShareSheet = true

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
