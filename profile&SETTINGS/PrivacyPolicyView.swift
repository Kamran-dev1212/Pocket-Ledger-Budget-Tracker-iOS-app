
import SwiftUI

struct PrivacyPolicyView: View {

    // MARK: - Environment

    @Environment(\.dismiss)
    private var dismiss

    // MARK: - Body

    var body: some View {

        ZStack {

            AppColors.dashboardGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {

                topHeader

                ScrollView {

                    VStack(
                        alignment: .leading,
                        spacing: 18
                    ) {

                        policySection(
                            title: "Introduction",
                            icon: "hand.raised.fill"
                        ) {
                            Text(
                                """
                                Pocket Ledger does not sell or rent your personal information. The app does not contain advertising or third-party analytics.

                                When you create or join a shared group, information such as the group name, shared expenses, member display names, contributions, and settlement details may be shared with other group participants through Apple's iCloud and CloudKit services.

                                New groups are invite-only by default. The group owner can invite participants using the email address or phone number associated with their Apple Account.

                                The group owner may optionally enable public-link sharing. When enabled, people who obtain the group's sharing link may be able to access and modify shared group information, subject to Apple's CloudKit sharing requirements.

                                Group owners can disable public-link access at any time. Disabling public-link access does not necessarily remove people who have already joined the group.

                                Personal transactions, personal budgets, and private profile information are not intentionally included in shared group records.
                                """
                            )
                        }

                        policySection(
                            title: "Information Stored in the App",
                            icon: "internaldrive.fill"
                        ) {
                            Text(
                                """
                                Pocket Ledger stores your personal financial records on your device using Apple's SwiftData framework.

                                When iCloud synchronization is available and enabled, the app is configured to synchronize your personal financial records through your private iCloud database using Apple's CloudKit service.

                                If iCloud synchronization is unavailable, the app may continue using local device storage. Synchronization depends on your device settings, iCloud account, network availability, and Apple's services.

                                Pocket Ledger does not operate its own servers for storing your personal financial records. Personal financial information is not intentionally shared with other Pocket Ledger users, except for information you choose to include in shared groups.

                                Information stored in iCloud is handled through Apple's services and is subject to Apple's applicable privacy and security policies.
                                """
                            )
                        }

                        policySection(
                            title: "Your Financial Data",
                            icon: "lock.shield.fill"
                        ) {
                            Text(
                                """
                                Your records are stored on your device and synced to your own private iCloud account using Apple's CloudKit, so they appear on your other devices signed in to the same Apple ID.

                                Pocket Ledger has no servers of its own. The developer cannot see, access, or read your data in iCloud. If iCloud is turned off for the app, your data stays on your device only.

                                Data in iCloud is handled by Apple under Apple's Privacy Policy.
                                """
                            )
                        }

                        policySection(
                            title: "Data Sharing",
                            icon: "person.2.fill"
                        ) {
                            Text(
                                """
                                Pocket Ledger does not sell, rent, or share your personal information with third parties, and contains no advertising or third-party analytics.

                                If you create or join a shared group, the group's name, its expenses, and the display name of each member are shared through iCloud with the people you invite. Only group data is shared — never your personal transactions, budgets, or profile.
                                """
                            )
                        }

                        policySection(
                            title: "Data Security",
                            icon: "shield.fill"
                        ) {
                            Text(
                                """
                                We take reasonable steps to protect the information stored within the app.

                                However, no electronic storage system can be guaranteed to be completely secure. You should also protect your device with a secure passcode and use the security features provided by your device.
                                """
                            )
                        }

                        policySection(
                            title: "Subscriptions",
                            icon: "sparkles"
                        ) {
                            Text(
                                """
                                Pocket Ledger offers optional Premium subscriptions through Apple's App Store.

                                Subscription purchases, renewals, and payment processing are handled by Apple using StoreKit.

                                Pocket Ledger uses Apple's verified transaction and entitlement information to determine access to Premium features.

                                The app does not directly collect or store your payment card details.

                                Certain reminder features may be available during a limited introductory access period. This app-managed access period is separate from any subscription free trial offered through the App Store.

                                Subscription pricing, billing periods, and any available introductory offers are displayed before purchase.
                                """
                            )
                        }
                        policySection(
                            title: "Changes to This Policy",
                            icon: "arrow.triangle.2.circlepath"
                        ) {
                            Text(
                                """
                                This Privacy Policy may be updated from time to time.

                                Any changes will be reflected in an updated version of this policy within the app.
                                """
                            )
                        }

                        policySection(
                            title: "Contact",
                            icon: "envelope.fill"
                        ) {
                            Text(
                                """
                                If you have questions about this Privacy Policy, contact us at kamranzaidi79@gmail.com or through Contact Support in the app.
                                """
                            )
                        }

                        footerSection

                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 24)
                    .padding(.bottom, 36)
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
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Purple Header

    private var topHeader: some View {

        VStack(
            alignment: .leading,
            spacing: 24
        ) {

            HStack {

                Button {
                    dismiss()
                } label: {

                    HStack(spacing: 5) {

                        Image(systemName: "chevron.left")
                            .font(.system(
                                size: 15,
                                weight: .semibold
                            ))

                        Text("Back")
                            .font(.system(
                                size: 16,
                                weight: .semibold
                            ))
                    }
                    .foregroundStyle(.white)
                }

                Spacer()

                Text("Privacy Policy")
                    .font(.system(
                        size: 17,
                        weight: .semibold
                    ))
                    .foregroundStyle(.white)

                Spacer()

                Text("Back")
                    .font(.system(
                        size: 16,
                        weight: .semibold
                    ))
                    .hidden()
            }

            VStack(
                alignment: .leading,
                spacing: 8
            ) {

                Text("Your Privacy Matters")
                    .font(.system(
                        size: 27,
                        weight: .bold
                    ))
                    .foregroundStyle(.white)

                Text("Learn how your information is handled")
                    .font(.system(size: 14))
                    .foregroundStyle(
                        .white.opacity(0.85)
                    )
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 14)
        .padding(.bottom, 28)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    // MARK: - Policy Section

    private func policySection<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            HStack(spacing: 12) {

                Image(systemName: icon)
                    .font(.system(size: 17))
                    .foregroundStyle(
                        AppColors.dashboardPurple
                    )
                    .frame(
                        width: 38,
                        height: 38
                    )
                    .background(
                        AppColors.dashboardPurple.opacity(0.10),
                        in: RoundedRectangle(
                            cornerRadius: 11
                        )
                    )

                Text(title)
                    .font(.system(
                        size: 17,
                        weight: .semibold
                    ))
                    .foregroundStyle(
                        AppColors.textPrimary
                    )
            }

            content()
                .font(.system(size: 14))
                .foregroundStyle(
                    AppColors.textSecondary
                )
                .lineSpacing(5)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
        }
        .padding(18)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            AppColors.card,
            in: RoundedRectangle(
                cornerRadius: 20
            )
        )
    }

    // MARK: - Footer

    private var footerSection: some View {

        VStack(spacing: 8) {

            Text("Pocket Ledger: Budget Tracker")
                .font(.system(
                    size: 14,
                    weight: .semibold
                ))
                .foregroundStyle(
                    AppColors.textPrimary
                )

            Text("Privacy Policy")
                .font(.system(size: 12))
                .foregroundStyle(
                    AppColors.textSecondary
                )

            Text("Last updated: November 2026")
                .font(.system(size: 12))
                .foregroundStyle(
                    AppColors.textSecondary
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 14)
        .padding(.bottom, 8)
    }
}

// MARK: - Preview

#Preview {

    NavigationStack {
        PrivacyPolicyView()
    }
}
