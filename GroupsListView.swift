import SwiftUI
import CloudKit

struct GroupsListView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var groups: [SharedGroup] = []
    @State private var isLoading = false
    @State private var showCreateGroup = false
    @State private var groupToRename: SharedGroup?
    @State private var groupToRemove: SharedGroup?
    @State private var errorMessage = ""
    @State private var showError = false

    var body: some View {

        NavigationStack {

            ZStack {

                AppColors.background
                    .ignoresSafeArea()

                if isLoading {

                    ProgressView()

                } else if groups.isEmpty {

                    VStack(spacing: 16) {

                        Image(systemName: "person.3.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(AppColors.primary)

                        Text("No Groups Yet")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(AppColors.textPrimary)

                        Text("Create a group to share expenses with friends or family.")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                    }

                } else {

                    List(groups) { group in

                        NavigationLink {

                            GroupDetailView(group: group)

                        } label: {

                            VStack(alignment: .leading, spacing: 4) {

                                Text(group.name)
                                    .font(.headline)
                                    .foregroundStyle(AppColors.textPrimary)

                                Text(group.createdAt, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(AppColors.textSecondary)

                            }
                            .padding(.vertical, 4)

                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {

                            Button(role: .destructive) {

                                groupToRemove = group

                            } label: {

                                if group.isOwnedByCurrentUser {

                                    Label("Delete", systemImage: "trash")

                                } else {

                                    Label(
                                        "Leave",
                                        systemImage: "rectangle.portrait.and.arrow.right"
                                    )

                                }

                            }

                            // Renaming changes the name for everyone, so it
                            // stays with whoever created the group.
                            if group.isOwnedByCurrentUser {

                                Button {
                                    groupToRename = group
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(AppColors.primary)

                            }

                        }

                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .refreshable {

                        await loadGroups(showSpinner: false)

                    }

                }

            }
            .navigationTitle("Groups")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(placement: .topBarLeading) {

                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.primary)

                }

                ToolbarItem(placement: .topBarTrailing) {

                    Button {
                        showCreateGroup = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Create Group")

                }

            }
            .sheet(isPresented: $showCreateGroup) {

                CreateGroupView {

                    Task {
                        await loadGroups()
                    }

                }

            }
            .sheet(item: $groupToRename) { group in

                RenameGroupView(group: group) {

                    Task {
                        await loadGroups()
                    }

                }

            }
            .task {
                await loadGroups()
            }
            .onReceive(NotificationCenter.default.publisher(for: .didAcceptGroupShare)) { _ in

                Task {
                    await loadGroups()
                }

            }
            .alert("Error", isPresented: $showError) {

                Button("OK", role: .cancel) { }

            } message: {

                Text(errorMessage)

            }
            .confirmationDialog(
                groupToRemove.map { group in

                    group.isOwnedByCurrentUser
                        ? "Delete \"\(group.name)\"?"
                        : "Leave \"\(group.name)\"?"

                } ?? "",
                isPresented: Binding(
                    get: { groupToRemove != nil },
                    set: { if !$0 { groupToRemove = nil } }
                ),
                titleVisibility: .visible
            ) {

                Button(
                    groupToRemove?.isOwnedByCurrentUser == true ? "Delete" : "Leave",
                    role: .destructive
                ) {

                    if let group = groupToRemove {

                        Task {
                            await remove(group)
                        }

                    }

                }

                Button("Cancel", role: .cancel) {
                    groupToRemove = nil
                }

            } message: {

                if groupToRemove?.isOwnedByCurrentUser == true {

                    Text("This removes the group for everyone, including anyone you've shared it with. This can't be undone.")

                } else {

                    Text("You'll be removed from this group and won't see its expenses any more. The group stays for everyone else.")

                }

            }

        }

    }

    // MARK: - Actions

    private func remove(_ group: SharedGroup) async {

        do {

            if group.isOwnedByCurrentUser {

                try await GroupSharingManager.shared.deleteGroup(group)

            } else {

                try await GroupSharingManager.shared.leaveGroup(group)

            }

            groupToRemove = nil
            await loadGroups()

        } catch {

            groupToRemove = nil
            errorMessage = error.localizedDescription
            showError = true

        }

    }

    private func loadGroups(showSpinner: Bool = true) async {

        if showSpinner {
            isLoading = true
        }

        do {

            groups = try await GroupSharingManager.shared.fetchAllGroups()

        } catch {

            errorMessage = error.localizedDescription
            showError = true

        }

        if showSpinner {
            isLoading = false
        }

    }

}

#Preview {
    GroupsListView()
}
