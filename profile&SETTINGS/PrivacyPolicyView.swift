import SwiftUI

struct PrivacyPolicyView: View {

    var body: some View {

        ZStack {

            AppColors.background
                .ignoresSafeArea()

            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: 24
                ) {

                    // MARK: - Introduction

                    policySection(
                        title: "Introduction",
                        icon: "hand.raised.fill"
                    ) {

                        Text(
                            """
                            Welcome to Pocket Ledger: Budget Tracker.

                            Your privacy is important to us. This Privacy Policy explains how Pocket Ledger handles information when you use the app.

                            Pocket Ledger is designed to help you track your personal finances, including income, expenses, budgets, categories, and profile information.
                            """
                        )

                    }

                    // MARK: - Information We Store

                    policySection(
                        title: "Information Stored in the App",
                        icon: "internaldrive.fill"
                    ) {

                        Text(
                            """
                            Pocket Ledger may store information that you choose to enter into the app, including:

                            • Your name
                            • Email address
                            • Phone number
                            • Occupation
                            • Personal bio
                            • Profile photo
                            • Income records
                            • Expense records
                            • Budget information
                            • Custom categories

                            This information is used to provide the features and functionality of the app.
                            """
                        )

                    }

                    // MARK: - Local Data

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

                    // MARK: - Profile Photos

                    policySection(
                        title: "Photos",
                        icon: "photo.fill"
                    ) {

                        Text(
                            """
                            If you choose to add a profile photo, Pocket Ledger requests access to your selected photo through the system photo picker.

                            The selected photo is stored within the app for displaying your profile picture.

                            Pocket Ledger does not access your entire photo library.
                            """
                        )

                    }

                    // MARK: - Data Sharing

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

                    // MARK: - Data Security

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

                    // MARK: - Future Features

                    policySection(
                        title: "Subscriptions",
                        icon: "sparkles"
                    ) {

                        Text(
                            """
                            Premium subscriptions are processed entirely by Apple through the App Store. Pocket Ledger never receives your payment details; it only checks with Apple whether your subscription is active.
                            """
                        )

                    }

                    // MARK: - Changes

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

                    // MARK: - Contact

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

                    // MARK: - Footer

                    VStack(spacing: 6) {

                        Text("Pocket Ledger: Budget Tracker")
                            .font(.headline)
                            .foregroundStyle(
                                AppColors.textPrimary
                            )

                        Text("Privacy Policy")
                            .font(.caption)
                            .foregroundStyle(
                                AppColors.textSecondary
                            )

                        Text(
                            "Last updated: September 2026"
                        )
                        .font(.caption2)
                        .foregroundStyle(
                            AppColors.textSecondary.opacity(0.7)
                        )

                    }
                    .frame(
                        maxWidth: .infinity
                    )
                    .padding(.vertical, 16)

                }
                .padding()

            }

        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)

    }

    // MARK: - Policy Section

    private func policySection<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            HStack(spacing: 10) {

                Image(systemName: icon)
                    .foregroundStyle(
                        AppColors.primary
                    )

                Text(title)
                    .font(.headline)
                    .foregroundStyle(
                        AppColors.textPrimary
                    )

            }

            content()
                .font(.subheadline)
                .foregroundStyle(
                    AppColors.textSecondary
                )
                .lineSpacing(4)

        }
        .padding()
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            AppColors.card
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
        .shadow(
            color: AppColors.shadow,
            radius: 6,
            x: 0,
            y: 2
        )

    }

}

// MARK: - Preview

#Preview {

    NavigationStack {

        PrivacyPolicyView()

    }

}
