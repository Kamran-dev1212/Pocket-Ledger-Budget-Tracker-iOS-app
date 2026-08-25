import SwiftUI
import SwiftData
import UIKit
import StoreKit

enum AppAppearance: String, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"
}

struct ProfileView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @AppStorage("selectedAppearance") private var appearanceRaw: String = AppAppearance.light.rawValue
    @AppStorage("selectedCurrency") private var currency: String = "PKR"
    @AppStorage("appLockEnabled") private var isAppLockEnabled = false

    @AppStorage("incomeExpenseReminder")
    private var reminderFrequencyRaw: String =
        ReminderFrequency.daily.rawValue

    private var reminderFrequency: ReminderFrequency {

        ReminderFrequency(
            rawValue: reminderFrequencyRaw
        ) ?? .daily

    }

    @Query private var profiles: [UserProfile]

    @Query private var allTransactions: [Transaction]
    @Query private var allBudgets: [Budget]

    private var profile: UserProfile? {
        profiles.first
    }

    @State private var showEditProfile = false

    // MARK: - Export State

    @State private var showShareSheet = false
    @State private var exportFileURL: URL?
    @State private var showExportErrorAlert = false
    @State private var exportErrorMessage = ""

    private let currencies = ["PKR", "USD", "EUR", "GBP", "AED", "INR"]

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var displayName: String {

        guard let name = profile?.fullName, !name.isEmpty else {
            return "MyMoney Tracker"
        }

        return name

    }

    var body: some View {

        NavigationStack {

            ZStack {

                AppColors.background
                    .ignoresSafeArea()

                ScrollView {

                    VStack(spacing: 22) {

                        profileHeaderSection
                        generalSection
                        notificationsSection
                        dataSection
                        privacySection
                        aboutSection
                        footerSection

                    }
                    .padding(.horizontal)

                }

            }
            .navigationTitle("Profile")
            .toolbar {

                ToolbarItem(placement: .topBarLeading) {

                    Button("Done") {

                        dismiss()

                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.primary)

                }

            }
            .sheet(isPresented: $showEditProfile) {

                if let profile {

                    EditProfileView(profile: profile)

                }

            }
            .sheet(isPresented: $showShareSheet) {

                if let exportFileURL {

                    ActivityView(activityItems: [exportFileURL])

                }

            }
            .alert("Export Failed", isPresented: $showExportErrorAlert) {

                Button("OK", role: .cancel) { }

            } message: {

                Text(exportErrorMessage)

            }
            .onAppear {

                ensureProfileExists()

            }

        }

    }

    // MARK: - Guarantee a UserProfile exists

    private func ensureProfileExists() {

        guard profiles.isEmpty else {
            return
        }

        let newProfile = UserProfile()
        modelContext.insert(newProfile)

    }

    // MARK: - Profile Header

    @ViewBuilder
    private var profileHeaderSection: some View {

        VStack(spacing: 12) {

            ZStack {

                if let imageData = profile?.profileImageData, let uiImage = UIImage(data: imageData) {

                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 96, height: 96)
                        .clipShape(Circle())

                } else {

                    Circle()
                        .fill(AppColors.primary.opacity(0.12))
                        .frame(width: 96, height: 96)

                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(AppColors.primary)

                }

            }

            VStack(spacing: 4) {

                Text("Welcome back 👋")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)

                Text(displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(AppColors.textPrimary)

                if let occupation = profile?.occupation, !occupation.isEmpty {

                    Text(occupation)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textSecondary)

                }

            }

            Button {

                showEditProfile = true

            } label: {

                Text("Edit Profile")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.textOnPrimary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(AppColors.primary)
                    .clipShape(Capsule())

            }
            .accessibilityLabel("Edit Profile")

        }
        .padding(.top, 12)
        .accessibilityElement(children: .combine)

    }

    // MARK: - General

    @ViewBuilder
    private var generalSection: some View {

        SettingsSectionView(title: "General") {

            VStack(spacing: 4) {

                Text("Appearance")
                    .font(.body)
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Picker("Appearance", selection: $appearanceRaw) {

                    ForEach(AppAppearance.allCases, id: \.self) { option in

                        Text(option.rawValue)
                            .tag(option.rawValue)

                    }

                }
                .pickerStyle(.segmented)
                .padding(.bottom, 8)
                .accessibilityLabel("Appearance")

            }
            .padding(.top, 10)

            Divider()
                .background(AppColors.divider)

            Menu {

                ForEach(currencies, id: \.self) { option in

                    Button {

                        currency = option

                    } label: {

                        Text(option)

                    }

                }

            } label: {

                SettingsRowView(
                    icon: "dollarsign.circle.fill",
                    iconColor: AppColors.success,
                    title: "Currency",
                    trailingText: currency
                )

            }
            .buttonStyle(.plain)
            .accessibilityLabel("Currency")
            .accessibilityValue(currency)
            .accessibilityHint("Double tap to change currency")

        }

    }

    // MARK: - Notifications

    @ViewBuilder
    private var notificationsSection: some View {

        SettingsSectionView(title: "Notifications") {

            Menu {

                ForEach(
                    ReminderFrequency.allCases,
                    id: \.self
                ) { option in

                    Button {

                        reminderFrequencyRaw =
                            option.rawValue

                        updateReminder(
                            frequency: option
                        )

                    } label: {

                        HStack {

                            Text(option.rawValue)

                            if reminderFrequency == option {

                                Image(
                                    systemName: "checkmark"
                                )

                            }

                        }

                    }

                }

            } label: {

                SettingsRowView(
                    icon: "bell.fill",
                    iconColor: AppColors.warning,
                    title: "Income & Expense Reminder",
                    trailingText: reminderFrequency.rawValue
                )

            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                "Income and expense reminder"
            )
            .accessibilityValue(
                reminderFrequency.rawValue
            )
            .accessibilityHint(
                "Double tap to change reminder frequency"
            )

        }

    }

    // MARK: - Data

    @ViewBuilder
    private var dataSection: some View {

        SettingsSectionView(title: "Data") {

            Button {

                exportPDFStatement()

            } label: {

                SettingsRowView(
                    icon: "square.and.arrow.up.fill",
                    iconColor: AppColors.primary,
                    title: "Export Data",
                    subtitle: "Save a PDF statement of your transactions and budgets"
                )

            }
            .buttonStyle(.plain)
            .accessibilityLabel("Export Data")

        }

    }

    // MARK: - Export

    private func exportPDFStatement() {

        do {

            let url = try PDFReportGenerator.createStatement(
                transactions: allTransactions,
                budgets: allBudgets,
                currencyCode: currency
            )

            exportFileURL = url
            showShareSheet = true

        } catch {

            exportErrorMessage = error.localizedDescription
            showExportErrorAlert = true

        }

    }

    // MARK: - Privacy & Security

    @ViewBuilder
    private var privacySection: some View {

        SettingsSectionView(title: "Privacy & Security") {

            HStack {

                ZStack {

                    Circle()
                        .fill(AppColors.primary.opacity(0.12))
                        .frame(width: 36, height: 36)

                    Image(systemName: "faceid")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColors.primary)

                }

                VStack(alignment: .leading, spacing: 2) {

                    Text("App Lock")
                        .font(.body)
                        .foregroundStyle(AppColors.textPrimary)

                    Text("Require Face ID, Touch ID, or your passcode to open Pocket Ledger")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)

                }

                Spacer()

                Toggle("", isOn: $isAppLockEnabled)
                    .labelsHidden()
                    .tint(AppColors.primary)

            }
            .padding(.vertical, 4)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("App Lock")

        }

    }

    // MARK: - About

    @ViewBuilder
    private var aboutSection: some View {

        SettingsSectionView(title: "About") {

            SettingsRowView(
                icon: "info.circle.fill",
                iconColor: AppColors.primary,
                title: "App Version",
                trailingText: appVersion,
                showChevron: false
            )

            Divider()
                .background(AppColors.divider)

            NavigationLink {

                PrivacyPolicyView()

            } label: {

                SettingsRowView(
                    icon: "hand.raised.fill",
                    iconColor: AppColors.primary,
                    title: "Privacy Policy"
                )

            }
            .accessibilityLabel("Privacy Policy")

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
            .accessibilityLabel("Terms & Conditions")

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
            .accessibilityLabel("Contact Support")

            Divider()
                .background(AppColors.divider)

            Button {

                rateApp()

            } label: {

                SettingsRowView(
                    icon: "star.fill",
                    iconColor: AppColors.warning,
                    title: "Rate the App"
                )

            }
            .buttonStyle(.plain)
            .accessibilityLabel("Rate the App")
            .accessibilityHint("Request an App Store review")
        }

    }

    // MARK: - Footer

    @ViewBuilder
    private var footerSection: some View {

        VStack(spacing: 4) {

            Text("Version \(appVersion)")
                .font(.caption2)
                .foregroundStyle(AppColors.textSecondary.opacity(0.7))

        }
        .padding(.top, 8)
        .padding(.bottom, 20)
        .accessibilityElement(children: .combine)

    }
    // MARK: - Rate App

    private func rateApp() {

        // Request Apple's in-app review dialog.
        // Apple decides whether to display it.
        if let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {

            SKStoreReviewController.requestReview(in: scene)        }

        // After the app is live on the App Store,
        // replace the above code with the App Store review URL if desired.
    }

    // MARK: - Update Reminder

    private func updateReminder(
        frequency: ReminderFrequency
    ) {

        switch frequency {

        case .off:

            NotificationManager
                .shared
                .cancelIncomeExpenseReminder()

        case .daily:

            NotificationManager
                .shared
                .scheduleDailyReminder(
                    hour: 20,
                    minute: 0
                )

        case .weekly:

            NotificationManager
                .shared
                .scheduleWeeklyReminder(
                    weekday: 1,
                    hour: 20,
                    minute: 0
                )

        case .monthly:

            NotificationManager
                .shared
                .scheduleMonthlyReminder(
                    day: 1,
                    hour: 20,
                    minute: 0
                )

        }

    }

}

#Preview {
    ProfileView()
}
