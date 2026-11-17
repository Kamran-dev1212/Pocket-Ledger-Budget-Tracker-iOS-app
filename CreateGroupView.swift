
import SwiftUI
import CloudKit

struct CreateGroupView: View {

    @Environment(\.dismiss) private var dismiss

    var onCreated: () -> Void

    // MARK: - State

    @State private var groupName = ""
    @State private var isCreating = false
    @State private var createdGroup: SharedGroup?

    @State private var errorMessage = ""
    @State private var showError = false

    @FocusState private var isNameFocused: Bool

    // MARK: - Validation

    private var trimmedName: String {
        groupName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private var isNameValid: Bool {
        !trimmedName.isEmpty
    }

    private var canCreate: Bool {
        isNameValid && !isCreating && createdGroup == nil
    }

    // MARK: - Body

    var body: some View {

        NavigationStack {

            ZStack {

                AppColors.dashboardGradient
                    .ignoresSafeArea()

                VStack(spacing: 0) {

                    purpleHeader

                    contentArea

                }

            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(
                item: $createdGroup,
                onDismiss: {

                    onCreated()
                    dismiss()

                }
            ) { group in

                InviteMembersView(group: group) {}

            }
            .alert(
                "Could Not Create Group",
                isPresented: $showError
            ) {

                Button("OK", role: .cancel) {}

            } message: {

                Text(errorMessage)

            }

        }

    }

    // MARK: - Purple Header

    private var purpleHeader: some View {

        VStack(alignment: .leading, spacing: 24) {

            HStack {

                Button {

                    isNameFocused = false
                    dismiss()

                } label: {

                    Text("Cancel")
                        .font(
                            .system(
                                size: 16,
                                weight: .medium
                            )
                        )
                        .foregroundStyle(.white)

                }
                .disabled(isCreating)

                Spacer()

                Text("Create New Group")
                    .font(
                        .system(
                            size: 17,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(.white)

                Spacer()

                Button {

                    isNameFocused = false

                    Task {
                        await createGroup()
                    }

                } label: {

                    if isCreating {

                        ProgressView()
                            .tint(.white)

                    } else {

                        Text("Create")
                            .font(
                                .system(
                                    size: 16,
                                    weight: .semibold
                                )
                            )
                            .foregroundStyle(
                                canCreate
                                    ? Color.white
                                    : Color.white.opacity(0.5)
                            )

                    }

                }
                .disabled(!canCreate)

            }

            VStack(alignment: .leading, spacing: 12) {

                HStack(spacing: 12) {

                    Image(systemName: "person.3.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white)
                        .frame(
                            width: 58,
                            height: 58
                        )
                        .background(
                            Color.white.opacity(0.18)
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 17
                            )
                        )

                    VStack(
                        alignment: .leading,
                        spacing: 6
                    ) {

                        Text("New Shared Group")
                            .font(
                                .system(
                                    size: 25,
                                    weight: .bold
                                )
                            )
                            .foregroundStyle(.white)

                        Text("Split expenses together")
                            .font(
                                .system(
                                    size: 14,
                                    weight: .medium
                                )
                            )
                            .foregroundStyle(
                                .white.opacity(0.85)
                            )

                    }

                }

                Text(
                    "Create a group for trips, roommates, family, or any shared expenses."
                )
                .font(.system(size: 13))
                .foregroundStyle(
                    .white.opacity(0.75)
                )
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )

            }

        }
        .padding(.horizontal, 22)
        .padding(.top, 14)
        .padding(.bottom, 30)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )

    }

    // MARK: - Content Area

    private var contentArea: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 24) {

                groupNameSection

                previewSection

                createButton

                informationSection

            }
            .padding(.horizontal, 18)
            .padding(.top, 26)
            .padding(.bottom, 40)

        }
        .scrollDismissesKeyboard(.interactively)
        .background(

            UnevenRoundedRectangle(
                topLeadingRadius: 28,
                topTrailingRadius: 28
            )
            .fill(AppColors.dashboardSurface)
            .ignoresSafeArea(edges: .bottom)

        )

    }

    // MARK: - Group Name

    private var groupNameSection: some View {

        VStack(alignment: .leading, spacing: 12) {

            sectionTitle("Group Details")

            VStack(alignment: .leading, spacing: 16) {

                HStack(spacing: 12) {

                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 23))
                        .foregroundStyle(
                            AppColors.dashboardPurple
                        )

                    VStack(
                        alignment: .leading,
                        spacing: 5
                    ) {

                        Text("Name Your Group")
                            .font(
                                .system(
                                    size: 16,
                                    weight: .semibold
                                )
                            )
                            .foregroundStyle(
                                AppColors.textPrimary
                            )

                        Text("Choose a name everyone will recognize")
                            .font(.system(size: 12))
                            .foregroundStyle(
                                AppColors.textSecondary
                            )

                    }

                }

                Divider()

                VStack(alignment: .leading, spacing: 9) {

                    Text("GROUP NAME")
                        .font(
                            .system(
                                size: 12,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(
                            AppColors.textSecondary
                        )

                    TextField(
                        "e.g. Trip to Switzerland",
                        text: $groupName
                    )
                    .font(.system(size: 16))
                    .foregroundStyle(
                        AppColors.textPrimary
                    )
                    .tint(
                        AppColors.dashboardPurple
                    )
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(false)
                    .focused($isNameFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        isNameFocused = false
                    }
                    .disabled(isCreating)

                }
                .padding(15)
                .background(
                    AppColors.dashboardSurface
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 12
                    )
                )

                Text(
                    "Examples: Apartment, Lahore Trip, Household, Weekend Trip"
                )
                .font(.system(size: 12))
                .foregroundStyle(
                    AppColors.textSecondary
                )
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )

            }
            .padding(18)
            .background(AppColors.card)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 20
                )
            )

        }

    }

    // MARK: - Group Preview

    private var previewSection: some View {

        VStack(alignment: .leading, spacing: 12) {

            sectionTitle("Group Preview")

            HStack(spacing: 14) {

                Image(systemName: "person.2.fill")
                    .font(.system(size: 23))
                    .foregroundStyle(
                        AppColors.dashboardPurple
                    )
                    .frame(
                        width: 54,
                        height: 54
                    )
                    .background(
                        AppColors.dashboardPurple
                            .opacity(0.10)
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 15
                        )
                    )

                VStack(
                    alignment: .leading,
                    spacing: 6
                ) {

                    Text(
                        trimmedName.isEmpty
                            ? "Your Group Name"
                            : trimmedName
                    )
                    .font(
                        .system(
                            size: 16,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        AppColors.textPrimary
                    )
                    .lineLimit(2)

                    HStack(spacing: 6) {

                        Image(
                            systemName: "person.fill"
                        )

                        Text("1 Member")

                    }
                    .font(.system(size: 12))
                    .foregroundStyle(
                        AppColors.textSecondary
                    )

                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(
                        .system(
                            size: 12,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        AppColors.textSecondary
                    )

            }
            .padding(17)
            .background(AppColors.card)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 18
                )
            )

        }

    }

    // MARK: - Create Button

    private var createButton: some View {

        Button {

            isNameFocused = false

            Task {
                await createGroup()
            }

        } label: {

            HStack(spacing: 10) {

                if isCreating {

                    ProgressView()
                        .tint(.white)

                    Text("Creating Group...")

                } else {

                    Image(
                        systemName: "plus.circle.fill"
                    )

                    Text("Create Group")

                }

            }
            .font(
                .system(
                    size: 16,
                    weight: .semibold
                )
            )
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                canCreate
                    ? AppColors.dashboardPurple
                    : AppColors.dashboardPurple.opacity(0.45)
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 16
                )
            )

        }
        .disabled(!canCreate)

    }

    // MARK: - Information

    private var informationSection: some View {

        HStack(
            alignment: .top,
            spacing: 12
        ) {

            Image(
                systemName: "info.circle.fill"
            )
            .font(.system(size: 19))
            .foregroundStyle(
                AppColors.dashboardPurple
            )

            VStack(
                alignment: .leading,
                spacing: 8
            ) {

                Text("What Happens Next?")
                    .font(
                        .system(
                            size: 14,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        AppColors.textPrimary
                    )

                Text(
                    "After creating your group, you can invite members using their Apple Account email or phone number and share an invitation link."
                )
                .font(.system(size: 12))
                .foregroundStyle(
                    AppColors.textSecondary
                )
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )

            }

        }
        .padding(16)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(AppColors.card)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )

    }

    // MARK: - Section Title

    private func sectionTitle(
        _ text: String
    ) -> some View {

        Text(text)
            .font(
                .system(
                    size: 18,
                    weight: .bold
                )
            )
            .foregroundStyle(
                AppColors.textPrimary
            )

    }

    // MARK: - Create Group

    private func createGroup() async {

        guard canCreate else {
            return
        }

        isCreating = true

        do {

            createdGroup = try await GroupSharingManager.shared
                .createGroup(
                    named: trimmedName
                )

        } catch {

            print(
                "GroupSharing: createGroup threw an error: \(error)"
            )

            errorMessage = CloudKitMessage.message(
                for: error
            )

            showError = true

        }

        isCreating = false

    }

}

// MARK: - Preview

#Preview {
    CreateGroupView(onCreated: {})
}
