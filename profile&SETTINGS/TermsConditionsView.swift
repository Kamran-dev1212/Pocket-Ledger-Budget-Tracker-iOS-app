import SwiftUI

struct TermsConditionsView: View {

    var body: some View {

        ZStack {

            AppColors.background
                .ignoresSafeArea()

            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: 24
                ) {

                    // MARK: - Acceptance

                    termsSection(
                        title: "Acceptance of Terms",
                        icon: "checkmark.seal.fill"
                    ) {

                        Text(
                            """
                            By downloading, installing, or using Pocket Ledger: Budget Tracker, you agree to these Terms & Conditions.

                            If you do not agree with these terms, please do not use the application.
                            """
                        )

                    }

                    // MARK: - App Purpose

                    termsSection(
                        title: "Use of the App",
                        icon: "chart.bar.fill"
                    ) {

                        Text(
                            """
                            Pocket Ledger is a personal finance and budgeting tool designed to help you record and organize your income, expenses, budgets, and financial categories.

                            The app is intended for personal financial tracking and organization.
                            """
                        )

                    }

                    // MARK: - No Financial Advice

                    termsSection(
                        title: "Not Financial Advice",
                        icon: "exclamationmark.triangle.fill"
                    ) {

                        Text(
                            """
                            Pocket Ledger does not provide financial, investment, tax, legal, or professional financial advice.

                            Information entered into or displayed by the app should not be considered professional advice.

                            You are responsible for your own financial decisions.
                            """
                        )

                    }

                    // MARK: - User Responsibility

                    termsSection(
                        title: "Your Responsibility",
                        icon: "person.fill.checkmark"
                    ) {

                        Text(
                            """
                            You are responsible for the accuracy of the information you enter into Pocket Ledger.

                            You should regularly review your financial records and ensure that the information stored in the app is accurate.

                            You are also responsible for protecting access to your device.
                            """
                        )

                    }

                    // MARK: - Data

                    termsSection(
                        title: "Your Data",
                        icon: "internaldrive.fill"
                    ) {

                        Text(
                            """
                            You are responsible for maintaining your own financial records.

                            Pocket Ledger currently stores your financial information locally on your device.

                            We recommend keeping your device secure and maintaining separate records of important financial information.
                            """
                        )

                    }

                    // MARK: - Accuracy

                    termsSection(
                        title: "Accuracy of Information",
                        icon: "checkmark.circle.fill"
                    ) {

                        Text(
                            """
                            While we aim to provide reliable functionality, Pocket Ledger does not guarantee that all calculations, displays, or information will always be completely free from errors.

                            You should verify important financial information independently.
                            """
                        )

                    }

                    // MARK: - Availability

                    termsSection(
                        title: "App Availability",
                        icon: "iphone"
                    ) {

                        Text(
                            """
                            We may update, modify, suspend, or discontinue features of Pocket Ledger at any time.

                            Some features may be introduced as premium or subscription-based features in future versions.
                            """
                        )

                    }

                    // MARK: - Subscriptions

                    termsSection(
                        title: "Subscriptions and Premium Features",
                        icon: "star.fill"
                    ) {

                        Text(
                            """
                            Future versions of Pocket Ledger may include subscription-based features.

                            Any subscription terms, pricing, billing information, renewal conditions, and cancellation policies will be clearly presented before purchase.
                            """
                        )

                    }

                    // MARK: - Intellectual Property

                    termsSection(
                        title: "Intellectual Property",
                        icon: "c.circle.fill"
                    ) {

                        Text(
                            """
                            Pocket Ledger, including its design, branding, software, graphics, and original content, is protected by applicable intellectual property laws.

                            You may not copy, modify, distribute, sell, or reverse engineer the application without permission.
                            """
                        )

                    }

                    // MARK: - Limitation of Liability

                    termsSection(
                        title: "Limitation of Liability",
                        icon: "shield.lefthalf.filled"
                    ) {

                        Text(
                            """
                            To the extent permitted by applicable law, Pocket Ledger and its developers are not responsible for financial losses, data loss, inaccurate records, or other damages resulting from the use of the application.

                            You use the application at your own discretion and responsibility.
                            """
                        )

                    }

                    // MARK: - Changes

                    termsSection(
                        title: "Changes to These Terms",
                        icon: "arrow.triangle.2.circlepath"
                    ) {

                        Text(
                            """
                            These Terms & Conditions may be updated from time to time.

                            Updated terms will be reflected within the application when appropriate.
                            """
                        )

                    }

                    // MARK: - Contact

                    termsSection(
                        title: "Contact",
                        icon: "envelope.fill"
                    ) {

                        Text(
                            """
                            If you have questions about these Terms & Conditions, you may contact the Pocket Ledger support team.
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

                        Text("Terms & Conditions")
                            .font(.caption)
                            .foregroundStyle(
                                AppColors.textSecondary
                            )

                        Text(
                            "Last updated: July 2026"
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
        .navigationTitle("Terms & Conditions")
        .navigationBarTitleDisplayMode(.inline)

    }

    // MARK: - Section

    private func termsSection<Content: View>(
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

        TermsConditionsView()

    }

}
