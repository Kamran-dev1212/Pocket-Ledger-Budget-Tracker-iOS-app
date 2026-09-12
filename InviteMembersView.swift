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
            case .sendLink: return "send-link"
            case .appleSharing: return "apple-sharing"
            }

        }

    }

    @State private var addressText = ""
    @State private var participants: [GroupParticipant] = []
    @State private var linkSharingEnabled = false
    @State private var isLoading = false
    @State private var isInviting = false
    @State private var isWorking = false
    @State private var activeSheet: ActiveSheet?
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false

    private var trimmedAddress: String {

        addressText.trimmingCharacters(in: .whitespacesAndNewlines)

    }

    private var canInvite: Bool {

        trimmedAddress.count >= 5 && !isInviting && !isWorking

    }

    var body: some View {

        NavigationStack {

            Form {

                // MARK: Invite

                Section {

                    TextField("Apple ID email or phone number", text: $addressText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)

                    Button {

                        Task {
                            await invite()
                        }

                    } label: {

                        if isInviting {

                            ProgressView()

                        } else {

                            Text("Add to Group")
                                .fontWeight(.semibold)

                        }

                    }
                    .disabled(!canInvite)

                } header: {

                    Text("Invite Someone")

                } footer: {

                    Text("Use the email address or phone number their iPhone's Apple ID is signed in with — not just any address they use. Once added, the invite link will open for them in any app you send it through.")

                }

                // MARK: Members

                Section("Members") {

                    if isLoading {

                        ProgressView()

                    } else {

                        ForEach(participants) { participant in

                            Text(participant.displayName)
                                .font(.subheadline)
                                .foregroundStyle(AppColors.textPrimary)

                        }

                    }

                }

                // MARK: Send

                Section {

                    Button {

                        Task {
                            await sendLink()
                        }

                    } label: {

                        Label("Send Invite Link", systemImage: "square.and.arrow.up")
                            .foregroundStyle(AppColors.primary)

                    }
                    .disabled(isWorking)

                    Button {

                        Task {
                            await openAppleSharing()
                        }

                    } label: {

                        Label("Apple Sharing Options", systemImage: "person.crop.circle.badge.plus")
                            .foregroundStyle(AppColors.primary)

                    }
                    .disabled(isWorking)

                } header: {

                    Text("Send the Link")

                } footer: {

                    Text("Send Invite Link opens the normal iOS share sheet, so you can send it via WhatsApp, email, Telegram, or copy it anywhere.")

                }

                // MARK: Open link

                Section {

                    Toggle(
                        "Anyone with the link can join",
                        isOn: Binding(
                            get: { linkSharingEnabled },
                            set: { newValue in

                                linkSharingEnabled = newValue

                                Task {
                                    await setLinkSharing(newValue)
                                }

                            }
                        )
                    )
                    .disabled(isWorking)

                } footer: {

                    Text("Off — only people you've added above can open the link. This is the safer setting for shared money.\n\nOn — anyone who receives the link can join and edit this group's expenses, including someone it gets forwarded to.")

                }

            }
            .navigationTitle("Members")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(placement: .topBarTrailing) {

                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.primary)

                }

            }
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
                            identifier: "iCloud.com.kamranzaidi.pocketledger"
                        )
                    )

                }

            }
            .task {
                await load()
            }
            .alert(alertTitle, isPresented: $showAlert) {

                Button("OK", role: .cancel) { }

            } message: {

                Text(alertMessage)

            }

        }

    }

    // MARK: - Actions

    private func load() async {

        isLoading = true

        do {

            async let fetchedParticipants =
                GroupSharingManager.shared.fetchParticipants(for: group)

            async let fetchedLinkSharing =
                GroupSharingManager.shared.isLinkSharingEnabled(for: group)

            let (loadedParticipants, loadedLinkSharing) =
                try await (fetchedParticipants, fetchedLinkSharing)

            participants = loadedParticipants
            linkSharingEnabled = loadedLinkSharing

        } catch {

            show(title: "Couldn't Load Members", message: error.localizedDescription)

        }

        isLoading = false

    }

    private func invite() async {

        isInviting = true

        do {

            let name = try await GroupSharingManager.shared.inviteParticipant(
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

            show(title: "Couldn't Add Them", message: message(for: error))

        }

        isInviting = false

    }

    private func sendLink() async {

        isWorking = true

        do {

            let url = try await GroupSharingManager.shared.shareURL(for: group)

            activeSheet = .sendLink(url)

        } catch {

            show(title: "Couldn't Get the Link", message: error.localizedDescription)

        }

        isWorking = false

    }

    private func openAppleSharing() async {

        isWorking = true

        do {

            let share = try await GroupSharingManager.shared.share(for: group)

            activeSheet = .appleSharing(share)

        } catch {

            show(title: "Couldn't Open Sharing", message: error.localizedDescription)

        }

        isWorking = false

    }

    private func setLinkSharing(_ enabled: Bool) async {

        isWorking = true

        do {

            try await GroupSharingManager.shared.setLinkSharingEnabled(
                enabled,
                for: group
            )

        } catch {

            // Put the switch back where it was — the change didn't stick.
            linkSharingEnabled = !enabled

            show(title: "Couldn't Change Link Setting", message: error.localizedDescription)

        }

        isWorking = false

    }

    // MARK: - Helpers

    private func message(for error: Error) -> String {

        guard let ckError = error as? CKError else {
            return error.localizedDescription
        }

        switch ckError.code {

        case .unknownItem:
            return "No iCloud account is registered to that email or phone number. Ask them to check Settings → their name on their iPhone, and use the address shown there."

        case .participantMayNeedVerification:
            return "They need to sign in to iCloud on their device before they can be added to a shared group."

        case .notAuthenticated:
            return "You're not signed in to iCloud on this device."

        case .networkUnavailable, .networkFailure:
            return "No internet connection."

        default:
            return error.localizedDescription

        }

    }

    private func show(title: String, message: String) {

        alertTitle = title
        alertMessage = message
        showAlert = true

    }

}
