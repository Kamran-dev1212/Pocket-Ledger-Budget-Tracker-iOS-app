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
    @AppStorage("selectedCurrency") private var currency: String = "USD"
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

    // MARK: - Premium State

    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showPaywall = false
    @State private var paywallReason = ""
    @State private var showManageSubscriptions = false

    /// Set once at first launch (see MyMoney_TrackerApp.init). Reminders
    /// are free for 7 days from this date, then Premium-only.
    @AppStorage("firstLaunchDate")
    private var firstLaunchTimestamp: Double = 0

    /// Days left in the reminder free trial, floored at 0. If the stored
    /// timestamp is somehow missing, treat the trial as just starting
    /// rather than already expired.
    private var reminderTrialDaysRemaining: Int {

        guard firstLaunchTimestamp > 0 else { return 7 }

        let firstLaunch = Date(timeIntervalSince1970: firstLaunchTimestamp)
        let elapsedDays = Int(Date().timeIntervalSince(firstLaunch) / 86400)

        return max(0, 7 - elapsedDays)

    }

    private var isReminderTrialActive: Bool {
        reminderTrialDaysRemaining > 0
    }

    /// "Off" is always free — turning reminders off isn't a Premium ask.
    /// Every other frequency needs either the trial window or Premium.
    private func isLocked(_ option: ReminderFrequency) -> Bool {

        guard option != .off else { return false }

        return !subscriptionManager.isSubscribed && !isReminderTrialActive

    }

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

            // Sits under "Welcome back 👋" where a person's name goes, so
            // the fallback should invite the user to fill it in — not name
            // the app at them.
            return "Add your name"

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
                        premiumSection
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
            .sheet(isPresented: $showPaywall) {

                PaywallView(reason: paywallReason)

            }
            .manageSubscriptionsSheet(isPresented: $showManageSubscriptions)
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

                Task {
                    await subscriptionManager.refreshEntitlementStatus()
                }

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

    // MARK: - Premium

    @ViewBuilder
    private var premiumSection: some View {

        SettingsSectionView(title: "Premium") {

            if subscriptionManager.isSubscribed {

                SettingsRowView(
                    icon: "crown.fill",
                    iconColor: AppColors.warning,
                    title: "Pocket Ledger Premium",
                    subtitle: "Active",
                    showChevron: false
                )

                Divider()
                    .background(AppColors.divider)

                Button {

                    showManageSubscriptions = true

                } label: {

                    SettingsRowView(
                        icon: "creditcard.fill",
                        iconColor: AppColors.primary,
                        title: "Manage Subscription"
                    )

                }
                .buttonStyle(.plain)

            } else {

                Button {

                    paywallReason = "Unlock the full power of Pocket Ledger."
                    showPaywall = true

                } label: {

                    SettingsRowView(
                        icon: "crown.fill",
                        iconColor: AppColors.warning,
                        title: "Upgrade to Premium",
                        subtitle: "Groups, categories, export and reminders"
                    )

                }
                .buttonStyle(.plain)

            }

            Divider()
                .background(AppColors.divider)

            Button {

                Task {
                    await subscriptionManager.restorePurchases()
                }

            } label: {

                SettingsRowView(
                    icon: "arrow.clockwise",
                    iconColor: AppColors.primary,
                    title: "Restore Purchases",
                    showChevron: false
                )

            }
            .buttonStyle(.plain)

        }

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

            if subscriptionManager.isSubscribed {

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

            } else {

                Button {

                    paywallReason = "Changing your currency is a Premium feature."
                    showPaywall = true

                } label: {

                    SettingsRowView(
                        icon: "dollarsign.circle.fill",
                        iconColor: AppColors.success,
                        title: "Currency",
                        trailingText: currency + " 🔒"
                    )

                }
                .buttonStyle(.plain)
                .accessibilityLabel("Currency")
                .accessibilityValue(currency)
                .accessibilityHint("Premium feature. Double tap to upgrade.")

            }

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

                        if isLocked(option) {

                            paywallReason = "Your 7-day free trial of reminders has ended. Upgrade to Premium to keep using them."
                            showPaywall = true
                            return

                        }

                        reminderFrequencyRaw =
                            option.rawValue

                        updateReminder(
                            frequency: option
                        )

                    } label: {

                        HStack {

                            Text(option.rawValue)

                            if isLocked(option) {

                                Image(systemName: "lock.fill")

                            }

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
                    subtitle: reminderSubtitle,
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

    private var reminderSubtitle: String? {

        if subscriptionManager.isSubscribed { return nil }

        if isReminderTrialActive {

            let days = reminderTrialDaysRemaining
            return "Free trial · \(days) day\(days == 1 ? "" : "s") left"

        }

        return "Premium feature"

    }

    // MARK: - Data

    @ViewBuilder
    private var dataSection: some View {

        SettingsSectionView(title: "Data") {

            Button {

                if subscriptionManager.isSubscribed {

                    exportPDFStatement()

                } else {

                    paywallReason = "Export your data as a PDF statement with Premium."
                    showPaywall = true

                }

            } label: {

                SettingsRowView(
                    icon: "square.and.arrow.up.fill",
                    iconColor: AppColors.primary,
                    title: "Export Data",
                    subtitle: subscriptionManager.isSubscribed
                        ? "Save a PDF statement of your transactions and budgets"
                        : "Premium · Save a PDF statement of your transactions and budgets"
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
                transactions: allTransactions.filter { !$0.isArchived },
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
