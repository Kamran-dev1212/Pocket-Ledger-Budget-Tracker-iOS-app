
import SwiftUI

struct AboutUsView: View {

    // MARK: - Environment

    @Environment(\.dismiss)
    private var dismiss

    // MARK: - App Information

    private var appVersion: String {
        Bundle.main.infoDictionary?[
            "CFBundleShortVersionString"
        ] as? String ?? "1.0"
    }

    // MARK: - Body

    var body: some View {

        NavigationStack {

            ZStack {

                AppColors.dashboardGradient
                    .ignoresSafeArea()

                VStack(spacing: 0) {

                    topHeader

                    ScrollView {

                        VStack(spacing: 22) {

                            appIdentityCard

                            aboutDescription

                            linksSection

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
    }

    // MARK: - Purple Header

    private var topHeader: some View {

        VStack(alignment: .leading, spacing: 24) {

            HStack {

                Button {
                    dismiss()
                } label: {

                    Text("Done")
                        .font(.system(
                            size: 16,
                            weight: .semibold
                        ))
                        .foregroundStyle(.white)
                }

                Spacer()

                Text("About Us")
                    .font(.system(
                        size: 17,
                        weight: .semibold
                    ))
                    .foregroundStyle(.white)

                Spacer()

                // Balances the centered title.
                Text("Done")
                    .font(.system(
                        size: 16,
                        weight: .semibold
                    ))
                    .hidden()
            }

            VStack(alignment: .leading, spacing: 8) {

                Text("About Pocket Ledger")
                    .font(.system(
                        size: 27,
                        weight: .bold
                    ))
                    .foregroundStyle(.white)

                Text("Simple money management, made for you")
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

    // MARK: - App Identity

    private var appIdentityCard: some View {

        VStack(spacing: 14) {

            Image(systemName: "wallet.pass.fill")
                .font(.system(
                    size: 38,
                    weight: .semibold
                ))
                .foregroundStyle(
                    AppColors.dashboardPurple
                )
                .frame(width: 88, height: 88)
                .background(
                    AppColors.dashboardPurple.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 24)
                )

            Text("Pocket Ledger")
                .font(.system(
                    size: 24,
                    weight: .bold
                ))
                .foregroundStyle(AppColors.textPrimary)

            Text("Budget Tracker")
                .font(.system(
                    size: 15,
                    weight: .medium
                ))
                .foregroundStyle(
                    AppColors.textSecondary
                )

            Text("Version \(appVersion)")
                .font(.system(
                    size: 13,
                    weight: .medium
                ))
                .foregroundStyle(
                    AppColors.dashboardPurple
                )
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    AppColors.dashboardPurple.opacity(0.10),
                    in: Capsule()
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .padding(.horizontal, 16)
        .background(
            AppColors.card,
            in: RoundedRectangle(cornerRadius: 22)
        )
    }

    // MARK: - About Description

    private var aboutDescription: some View {

        VStack(alignment: .leading, spacing: 12) {

            Text("Your Money, Made Simple")
                .font(.system(
                    size: 18,
                    weight: .bold
                ))
                .foregroundStyle(
                    AppColors.textPrimary
                )

            Text(
                "Pocket Ledger is your personal money notebook, designed to make everyday financial tracking simple and clear. Record your income and expenses, manage monthly budgets, and understand where your money goes."
            )
            .font(.system(size: 14))
            .foregroundStyle(
                AppColors.textSecondary
            )
            .fixedSize(
                horizontal: false,
                vertical: true
            )
            .lineSpacing(5)

        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(20)
        .background(
            AppColors.card,
            in: RoundedRectangle(cornerRadius: 20)
        )
    }

    // MARK: - Links

    private var linksSection: some View {

        VStack(alignment: .leading, spacing: 12) {

            Text("Support & Legal")
                .font(.system(
                    size: 17,
                    weight: .bold
                ))
                .foregroundStyle(
                    AppColors.textPrimary
                )
                .padding(.horizontal, 4)

            VStack(spacing: 0) {

                NavigationLink {

                    PrivacyPolicyView()

                } label: {

                    linkRow(
                        icon: "hand.raised.fill",
                        title: "Privacy Policy"
                    )
                }

                Divider()
                    .padding(.leading, 56)

                NavigationLink {

                    TermsConditionsView()

                } label: {

                    linkRow(
                        icon: "doc.text.fill",
                        title: "Terms & Conditions"
                    )
                }

                Divider()
                    .padding(.leading, 56)

                NavigationLink {

                    ContactSupportView()

                } label: {

                    linkRow(
                        icon: "envelope.fill",
                        title: "Contact Support"
                    )
                }
            }
            .background(
                AppColors.card,
                in: RoundedRectangle(cornerRadius: 20)
            )
        }
    }

    // MARK: - Reusable Link Row

    private func linkRow(
        icon: String,
        title: String
    ) -> some View {

        HStack(spacing: 14) {

            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundStyle(
                    AppColors.dashboardPurple
                )
                .frame(width: 38, height: 38)
                .background(
                    AppColors.dashboardPurple.opacity(0.10),
                    in: RoundedRectangle(cornerRadius: 11)
                )

            Text(title)
                .font(.system(
                    size: 15,
                    weight: .medium
                ))
                .foregroundStyle(
                    AppColors.textPrimary
                )

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(
                    size: 12,
                    weight: .semibold
                ))
                .foregroundStyle(
                    AppColors.textSecondary
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    // MARK: - Footer

    private var footerSection: some View {

        VStack(spacing: 8) {

            Text("Pocket Ledger: Budget Tracker")
                .font(.system(
                    size: 13,
                    weight: .semibold
                ))
                .foregroundStyle(
                    AppColors.textSecondary
                )

            Text("Take control of your everyday finances.")
                .font(.system(size: 12))
                .foregroundStyle(
                    AppColors.textSecondary
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 10)
    }
}

// MARK: - Preview

#Preview {
    AboutUsView()
}
