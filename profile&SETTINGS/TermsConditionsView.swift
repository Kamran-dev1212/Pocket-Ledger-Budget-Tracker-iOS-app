
import SwiftUI

struct TermsConditionsView: View {

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

                        termsSection(
                            title: "Your Data",
                            icon: "internaldrive.fill"
                        ) {
                            Text(
                                """
                                You are responsible for maintaining your own financial records.

                                Pocket Ledger stores your financial information on your device and in your private iCloud account.

                                We recommend keeping your device secure and maintaining separate records of important financial information.
                                """
                            )
                        }

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

                        termsSection(
                            title: "App Availability",
                            icon: "iphone"
                        ) {
                            Text(
                                """
                                We may update, modify, suspend, or discontinue features of Pocket Ledger at any time.

                                Some features require a Premium subscription.
                                """
                            )
                        }

                        termsSection(
                            title: "Subscriptions and Premium Features",
                            icon: "star.fill"
                        ) {
                            Text(
                                """
                                Pocket Ledger Premium is an auto-renewable subscription, available monthly or yearly. The price is shown in the app before purchase.

                                Payment is charged to your Apple ID at confirmation of purchase, or when any free trial ends. The subscription renews automatically unless cancelled at least 24 hours before the end of the current period. You can manage or cancel it in Settings > Apple ID > Subscriptions.

                                Refunds are handled by Apple. Your use of the app is also subject to Apple's Standard Licensed Application End User License Agreement (EULA).
                                """
                            )
                        }

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

                Text("Terms & Conditions")
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

                Text("Terms of Use")
                    .font(.system(
                        size: 27,
                        weight: .bold
                    ))
                    .foregroundStyle(.white)

                Text("Important information about using Pocket Ledger")
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

    // MARK: - Terms Section

    private func termsSection<Content: View>(
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

            Text("Terms & Conditions")
                .font(.system(size: 12))
                .foregroundStyle(
                    AppColors.textSecondary
                )

            Text("Last updated: September 2026")
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
        TermsConditionsView()
    }
}
