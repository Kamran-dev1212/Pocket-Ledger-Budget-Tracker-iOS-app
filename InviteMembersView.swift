
import SwiftUI
import CloudKit

struct InviteMembersView: View {

    let group: SharedGroup
    var onChanged: () -> Void

    @Environment(\.dismiss) private var dismiss

    private enum ActiveSheet: Identifiable {
        case sendLink(URL)
        case appleSharing(CKShare)

        var id: String {
            switch self {
            case .sendLink:
                return "send-link"
            case .appleSharing:
                return "apple-sharing"
            }
        }
    }

    // MARK: - State

    @State private var addressText = ""
    @State private var participants: [GroupParticipant] = []

    @State private var isLoading = false
    @State private var isInviting = false
    @State private var isWorking = false
    @State private var isPublicLinkEnabled = false
    @State private var isLoadingLinkPermission = true
    @State private var isUpdatingLinkPermission = false

    @State private var activeSheet: ActiveSheet?

    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false

    @FocusState private var isAddressFocused: Bool

    private var trimmedAddress: String {
        addressText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private var canInvite: Bool {
        trimmedAddress.count >= 5
            && !isInviting
            && !isWorking
            && !isLoading
    }

    private var isBusy: Bool {
        isInviting || isWorking
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
            .sheet(item: $activeSheet) { sheet in

                switch sheet {

                case .sendLink(let url):

                    ActivityView(
                        activityItems: [
                            "Join \"\(group.name)\" on Pocket Ledger to split expenses:",
                            url
                        ]
                    )

                case .appleSharing(let share):

                    CloudSharingView(
                        share: share,
                        container: CKContainer(
                            identifier: "iCloud.com.kamranzaidi.pocketledger.groups"
                        )
                    )

                }

            }
            .task {
                await load()

                if group.isOwnedByCurrentUser {
                    await loadPublicLinkPermission()
                }
            }
            .alert(alertTitle, isPresented: $showAlert) {

                Button("OK", role: .cancel) {}

            } message: {

                Text(alertMessage)

            }

        }

    }

    // MARK: - Purple Header

    private var purpleHeader: some View {

        VStack(alignment: .leading, spacing: 24) {

            HStack {

                Button {
                    isAddressFocused = false
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

                Spacer()

                Text("Add Members")
                    .font(
                        .system(
                            size: 17,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    isAddressFocused = false
                    dismiss()
                } label: {

                    Text("Done")
                        .font(
                            .system(
                                size: 16,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(.white)

                }

            }

            VStack(alignment: .leading, spacing: 10) {

                Text(group.name)
                    .font(
                        .system(
                            size: 27,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(.white)
                    .lineLimit(2)

                HStack(spacing: 8) {

                    Image(systemName: "person.2.fill")

                    Text(
                        "\(participants.count) \(participants.count == 1 ? "Member" : "Members")"
                    )

                }
                .font(
                    .system(
                        size: 14,
                        weight: .medium
                    )
                )
                .foregroundStyle(
                    .white.opacity(0.85)
                )

                Text("Invite people to share expenses together.")
                    .font(.system(size: 13))
                    .foregroundStyle(
                        .white.opacity(0.75)
                    )

            }

        }
        .padding(.horizontal, 22)
        .padding(.top, 14)
        .padding(.bottom, 28)

    }

    // MARK: - Content

    private var contentArea: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 24) {

                if group.isOwnedByCurrentUser {
                    inviteSection
                }

                membersSection

                if group.isOwnedByCurrentUser {
                    publicLinkSection
                    sharingSection
                    informationSection
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 24)
            .padding(.bottom, 40)

        }
        .scrollDismissesKeyboard(.interactively)
        .refreshable {
            await load()
        }
        .background(

            UnevenRoundedRectangle(
                topLeadingRadius: 28,
                topTrailingRadius: 28
            )
            .fill(AppColors.dashboardSurface)
            .ignoresSafeArea(edges: .bottom)

        )

    }

    // MARK: - Invite Section

    private var inviteSection: some View {

        VStack(alignment: .leading, spacing: 12) {

            sectionTitle("Invite Someone")

            VStack(alignment: .leading, spacing: 16) {

                HStack(spacing: 12) {

                    Image(
                        systemName: "person.crop.circle.badge.plus"
                    )
                    .font(.system(size: 25))
                    .foregroundStyle(
                        AppColors.dashboardPurple
                    )

                    VStack(
                        alignment: .leading,
                        spacing: 5
                    ) {

                        Text("Add a Group Member")
                            .font(
                                .system(
                                    size: 16,
                                    weight: .semibold
                                )
                            )
                            .foregroundStyle(
                                AppColors.textPrimary
                            )

                        Text("Enter their Apple ID details")
                            .font(.system(size: 12))
                            .foregroundStyle(
                                AppColors.textSecondary
                            )

                    }

                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {

                    Text("Apple ID Email or Phone")
                        .font(
                            .system(
                                size: 12,
                                weight: .medium
                            )
                        )
                        .foregroundStyle(
                            AppColors.textSecondary
                        )

                    TextField(
                        "Email address or phone number",
                        text: $addressText
                    )
                    .font(.system(size: 15))
                    .foregroundStyle(
                        AppColors.textPrimary
                    )
                    .tint(
                        AppColors.dashboardPurple
                    )
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .focused($isAddressFocused)
                    .submitLabel(.done)

                }
                .padding(14)
                .background(
                    AppColors.dashboardSurface
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 12
                    )
                )

                Button {

                    isAddressFocused = false

                    Task {
                        await invite()
                    }

                } label: {

                    HStack(spacing: 10) {

                        if isInviting {

                            ProgressView()
                                .tint(.white)

                        } else {

                            Image(
                                systemName: "person.badge.plus"
                            )

                            Text("Add to Group")

                        }

                    }
                    .font(
                        .system(
                            size: 15,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        canInvite
                            ? AppColors.dashboardPurple
                            : AppColors.dashboardPurple.opacity(0.45)
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 14
                        )
                    )

                }
                .disabled(!canInvite)

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

    // MARK: - Members

    private var membersSection: some View {

        VStack(alignment: .leading, spacing: 12) {

            HStack {

                sectionTitle("Group Members")

                Spacer()

                Text("\(participants.count)")
                    .font(
                        .system(
                            size: 13,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        AppColors.textSecondary
                    )

            }

            VStack(spacing: 0) {

                if isLoading {

                    HStack(spacing: 12) {

                        ProgressView()
                            .tint(
                                AppColors.dashboardPurple
                            )

                        Text("Loading members...")
                            .font(.subheadline)
                            .foregroundStyle(
                                AppColors.textSecondary
                            )

                        Spacer()

                    }
                    .padding(18)

                } else if participants.isEmpty {

                    VStack(spacing: 12) {

                        Image(
                            systemName: "person.2.slash"
                        )
                        .font(.system(size: 28))
                        .foregroundStyle(
                            AppColors.dashboardPurple
                        )

                        Text("No Members Available")
                            .font(
                                .system(
                                    size: 15,
                                    weight: .semibold
                                )
                            )
                            .foregroundStyle(
                                AppColors.textPrimary
                            )

                        Text("Pull down to refresh the member list.")
                            .font(.system(size: 12))
                            .foregroundStyle(
                                AppColors.textSecondary
                            )

                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)

                } else {

                    ForEach(
                        Array(participants.enumerated()),
                        id: \.element.id
                    ) { index, participant in

                        HStack(spacing: 12) {

                            Image(
                                systemName: "person.crop.circle.fill"
                            )
                            .font(.system(size: 30))
                            .foregroundStyle(
                                AppColors.dashboardPurple
                            )

                            VStack(
                                alignment: .leading,
                                spacing: 4
                            ) {

                                Text(
                                    participant.displayName
                                )
                                .font(
                                    .system(
                                        size: 15,
                                        weight: .semibold
                                    )
                                )
                                .foregroundStyle(
                                    AppColors.textPrimary
                                )

                                if participant.isCurrentUser {

                                    Text("You")
                                        .font(
                                            .system(size: 12)
                                        )
                                        .foregroundStyle(
                                            AppColors.textSecondary
                                        )

                                }

                            }

                            Spacer()

                            Image(
                                systemName: "checkmark.circle.fill"
                            )
                            .font(.system(size: 18))
                            .foregroundStyle(
                                AppColors.success
                            )

                        }
                        .padding(16)

                        if index < participants.count - 1 {

                            Divider()
                                .padding(
                                    .leading,
                                    58
                                )

                        }

                    }

                }

            }
            .background(AppColors.card)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 18
                )
            )

        }

    }
    // MARK: - Public Link Settings

    private var publicLinkSection: some View {

        VStack(alignment: .leading, spacing: 12) {

            sectionTitle("Link Access")

            VStack(alignment: .leading, spacing: 12) {

                Toggle(
                    "Allow Anyone With Link",
                    isOn: Binding(
                        get: { isPublicLinkEnabled },
                        set: { newValue in
                            Task {
                                await updatePublicLinkPermission(newValue)
                            }
                        }
                    )
                )
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
                .tint(AppColors.dashboardPurple)
                .disabled(
                    isLoadingLinkPermission ||
                    isUpdatingLinkPermission ||
                    isBusy
                )

                if isLoadingLinkPermission ||
                    isUpdatingLinkPermission {

                    ProgressView(
                        isLoadingLinkPermission
                            ? "Checking link access..."
                            : "Updating link access..."
                    )
                    .font(.system(size: 12))

                } else {

                    Text(
                        isPublicLinkEnabled
                            ? "Anyone with this group's invitation link can request access and edit shared group data."
                            : "Only people explicitly invited through their Apple Account can join this group."
                    )
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
                }
            }
            .padding(18)
            .background(AppColors.card)
            .clipShape(
                RoundedRectangle(cornerRadius: 18)
            )
        }
    }
    // MARK: - Sharing Options

    private var sharingSection: some View {

        VStack(alignment: .leading, spacing: 12) {

            sectionTitle("Share Invitation")

            VStack(spacing: 0) {

                Button {

                    isAddressFocused = false

                    Task {
                        await sendLink()
                    }

                } label: {

                    sharingRow(
                        icon: "square.and.arrow.up",
                        title: "Send Invite Link",
                        subtitle: "WhatsApp, Messages, Email & more"
                    )

                }
                .disabled(isBusy)

                Divider()
                    .padding(.leading, 60)

                Button {

                    isAddressFocused = false

                    Task {
                        await openAppleSharing()
                    }

                } label: {

                    sharingRow(
                        icon: "person.crop.circle.badge.plus",
                        title: "Apple Sharing Options",
                        subtitle: "Manage sharing through iCloud"
                    )

                }
                .disabled(isBusy)

            }
            .background(AppColors.card)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 18
                )
            )

        }

    }

    // MARK: - Sharing Row

    private func sharingRow(
        icon: String,
        title: String,
        subtitle: String
    ) -> some View {

        HStack(spacing: 12) {

            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(
                    AppColors.dashboardPurple
                )
                .frame(
                    width: 42,
                    height: 42
                )
                .background(
                    AppColors.dashboardPurple.opacity(0.10)
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 12
                    )
                )

            VStack(
                alignment: .leading,
                spacing: 5
            ) {

                Text(title)
                    .font(
                        .system(
                            size: 15,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        AppColors.textPrimary
                    )

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(
                        AppColors.textSecondary
                    )

            }

            Spacer()

            Image(
                systemName: "chevron.right"
            )
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
        .padding(16)
        .contentShape(Rectangle())

    }

    // MARK: - Information

    private var informationSection: some View {

        HStack(alignment: .top, spacing: 12) {

            Image(
                systemName: "info.circle.fill"
            )
            .font(.system(size: 18))
            .foregroundStyle(
                AppColors.dashboardPurple
            )

            VStack(
                alignment: .leading,
                spacing: 8
            ) {

                Text("How Invitations Work")
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
                    "Enter the email address or phone number associated with the person's Apple Account. After adding them, send the invitation link using your preferred messaging app."
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
    // MARK: - Link Permission Management

    private func loadPublicLinkPermission() async {

        guard group.isOwnedByCurrentUser else {
            return
        }

        isLoadingLinkPermission = true

        do {
            isPublicLinkEnabled = try await
                GroupSharingManager.shared
                    .isLinkSharingEnabled(for: group)

        } catch {
            show(
                title: "Couldn't Check Link Access",
                message: message(for: error)
            )
        }

        isLoadingLinkPermission = false
    }

    private func updatePublicLinkPermission(
        _ enabled: Bool
    ) async {

        guard group.isOwnedByCurrentUser,
              !isUpdatingLinkPermission,
              !isLoadingLinkPermission else {
            return
        }

        isUpdatingLinkPermission = true

        do {
            try await GroupSharingManager.shared
                .setLinkSharingEnabled(
                    enabled,
                    for: group
                )

            // Read back the actual saved permission.
            isPublicLinkEnabled = try await
                GroupSharingManager.shared
                    .isLinkSharingEnabled(for: group)

            onChanged()

        } catch {
            show(
                title: "Couldn't Update Link Access",
                message: message(for: error)
            )

            // Attempt to restore the current server value.
            if let currentValue = try? await
                GroupSharingManager.shared
                    .isLinkSharingEnabled(for: group) {

                isPublicLinkEnabled = currentValue
            }
        }

        isUpdatingLinkPermission = false
    }
    // MARK: - Load Members

    private func load() async {

        isLoading = true

        do {

            participants = try await GroupSharingManager.shared
                .fetchParticipants(for: group)

        } catch {

            show(
                title: "Couldn't Load Members",
                message: message(for: error)
            )

        }

        isLoading = false

    }

    // MARK: - Invite Member

    private func invite() async {

        guard canInvite else {
            return
        }

        isInviting = true

        do {

            let name = try await GroupSharingManager.shared
                .inviteParticipant(
                    emailOrPhone: trimmedAddress,
                    to: group
                )

            addressText = ""

            show(
                title: "\(name) Added",
                message: "Now send them the invite link and they can join the group."
            )

            await load()

            onChanged()

        } catch {

            show(
                title: "Couldn't Add Them",
                message: message(for: error)
            )

        }

        isInviting = false

    }

    // MARK: - Send Invite Link

    private func sendLink() async {

        guard !isBusy else {
            return
        }

        isWorking = true

        do {

            let url = try await GroupSharingManager.shared
                .shareURL(for: group)

            activeSheet = .sendLink(url)

        } catch {

            show(
                title: "Couldn't Get the Link",
                message: message(for: error)
            )

        }

        isWorking = false

    }

    // MARK: - Apple Sharing

    private func openAppleSharing() async {

        guard !isBusy else {
            return
        }

        isWorking = true

        do {

            let share = try await GroupSharingManager.shared
                .share(for: group)

            activeSheet = .appleSharing(share)

        } catch {

            show(
                title: "Couldn't Open Sharing",
                message: message(for: error)
            )

        }

        isWorking = false

    }

    // MARK: - Error Messages

    private func message(
        for error: Error
    ) -> String {

        CloudKitMessage.message(
            for: error,
            context: .invite
        )

    }

    private func show(
        title: String,
        message: String
    ) {

        alertTitle = title
        alertMessage = message
        showAlert = true

    }

}
