import SwiftUI

struct AboutUsView: View {

    @Environment(\.dismiss) private var dismiss

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {

        NavigationStack {

            ZStack {

                AppColors.background
                    .ignoresSafeArea()

                ScrollView {

                    VStack(spacing: 24) {

                        ZStack {

                            Circle()
                                .fill(AppColors.primary.opacity(0.12))
                                .frame(width: 96, height: 96)

                            Image(systemName: "wallet.pass.fill")
                                .font(.system(size: 40, weight: .semibold))
                                .foregroundStyle(AppColors.primary)

                        }
                        .padding(.top, 12)

                        VStack(spacing: 6) {

                            Text("Pocket Ledger")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(AppColors.textPrimary)

                            Text("Version \(appVersion)")
                                .font(.subheadline)
                                .foregroundStyle(AppColors.textSecondary)

                        }

                        Text("A simple personal money notebook — plain, clear, and focused on your money. Track income and expenses, set monthly budgets, and see where your money goes.")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)

                        VStack(spacing: 0) {

                            NavigationLink {

                                PrivacyPolicyView()

                            } label: {

                                SettingsRowView(
                                    icon: "hand.raised.fill",
                                    iconColor: AppColors.primary,
                                    title: "Privacy Policy"
                                )

                            }

                            Divider()
                                .background(AppColors.divider)

                            NavigationLink {

                                TermsConditionsView()

                            } label: {

                                SettingsRowView(
                                    icon: "doc.text.fill",
                                    iconColor: AppColors.primary,
                                    title: "Terms & Conditions"
                                )

                            }

                            Divider()
                                .background(AppColors.divider)

                            NavigationLink {

                                ContactSupportView()

                            } label: {

                                SettingsRowView(
                                    icon: "envelope.fill",
                                    iconColor: AppColors.primary,
                                    title: "Contact Support"
                                )

                            }

                        }
                        .padding(.horizontal, AppColors.cardPadding)
                        .background(AppColors.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppColors.cardCornerRadius)
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AppColors.cardCornerRadius))

                    }
                    .padding(.horizontal, AppColors.pageHorizontalPadding)
                    .padding(.vertical, 20)

                }

            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(placement: .topBarLeading) {

                    Button("Done") {

                        dismiss()

                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.primary)

                }

            }

        }

    }

}

#Preview {
    AboutUsView()
}
