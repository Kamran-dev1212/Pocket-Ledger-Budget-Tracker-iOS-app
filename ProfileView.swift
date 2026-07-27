import SwiftUI
import SwiftData
import UIKit

enum AppAppearance: String, CaseIterable {
    case light = "Light"
    case dark = "Dark"
}

struct ProfileView: View {

    @Environment(\.modelContext) private var modelContext

    @AppStorage("selectedAppearance") private var appearanceRaw: String = AppAppearance.light.rawValue
    @AppStorage("selectedCurrency") private var currency: String = "PKR"

    @AppStorage("incomeExpenseReminder")
    private var reminderFrequencyRaw: String =
        ReminderFrequency.daily.rawValue

    private var reminderFrequency: ReminderFrequency {

        ReminderFrequency(
            rawValue: reminderFrequencyRaw
        ) ?? .daily

    }

    @Query private var profiles: [UserProfile]

    private var profile: UserProfile? {
        profiles.first
    }

    @State private var showComingSoonAlert = false
    @State private var showEditProfile = false

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
                        categoriesSection
                        privacySection
                        aboutSection
                        footerSection

                    }
                    .padding(.horizontal)

                }

            }
            .navigationTitle("Profile")
            .alert("Coming Soon", isPresented: $showComingSoonAlert) {

                Button("OK", role: .cancel) { }

            } message: {

                Text("This feature will be available in a future update.")

            }
            .sheet(isPresented: $showEditProfile) {

                if let profile {

                    EditProfileView(profile: profile)

                }

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

            Divider()
                .background(AppColors.divider)

            SettingsRowView(
                icon: "globe",
                iconColor: AppColors.accent,
                title: "Language",
                trailingText: "Coming Soon",
                showChevron: false,
                isDisabled: true
            )

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

                showComingSoonAlert = true

            } label: {

                SettingsRowView(
                    icon: "square.and.arrow.up.fill",
                    iconColor: AppColors.primary,
                    title: "Export Data"
                )

            }
            .buttonStyle(.plain)
            .accessibilityLabel("Export Data")
            .accessibilityHint("Feature not yet available")

            Divider()
                .background(AppColors.divider)

            Button {

                showComingSoonAlert = true

            } label: {

                SettingsRowView(
                    icon: "square.and.arrow.down.fill",
                    iconColor: AppColors.primary,
                    title: "Import Data"
                )

            }
            .buttonStyle(.plain)
            .accessibilityLabel("Import Data")
            .accessibilityHint("Feature not yet available")

            Divider()
                .background(AppColors.divider)

            SettingsRowView(
                icon: "icloud.and.arrow.up.fill",
                iconColor: AppColors.textSecondary,
                title: "Backup",
                trailingText: "Coming Soon",
                showChevron: false,
                isDisabled: true
            )

            Divider()
                .background(AppColors.divider)

            SettingsRowView(
                icon: "icloud.and.arrow.down.fill",
                iconColor: AppColors.textSecondary,
                title: "Restore",
                trailingText: "Coming Soon",
                showChevron: false,
                isDisabled: true
            )

        }

    }

    // MARK: - Categories

    @ViewBuilder
    private var categoriesSection: some View {

        SettingsSectionView(title: "Categories") {

            NavigationLink {

                ManageCategoriesView()

            } label: {

                SettingsRowView(
                    icon: "square.grid.2x2.fill",
                    iconColor: AppColors.warning,
                    title: "Manage Categories"
                )

            }
            .accessibilityLabel("Manage Categories")

        }

    }

    // MARK: - Privacy & Security

    @ViewBuilder
    private var privacySection: some View {

        SettingsSectionView(title: "Privacy & Security") {

            SettingsRowView(
                icon: "faceid",
                iconColor: AppColors.textSecondary,
                title: "Face ID / Touch ID",
                trailingText: "Coming Soon",
                showChevron: false,
                isDisabled: true
            )

            Divider()
                .background(AppColors.divider)

            SettingsRowView(
                icon: "lock.fill",
                iconColor: AppColors.textSecondary,
                title: "Passcode Lock",
                trailingText: "Coming Soon",
                showChevron: false,
                isDisabled: true
            )

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

                showComingSoonAlert = true

            } label: {

                SettingsRowView(
                    icon: "star.fill",
                    iconColor: AppColors.warning,
                    title: "Rate the App"
                )

            }
            .buttonStyle(.plain)
            .accessibilityLabel("Rate the App")
            .accessibilityHint("Feature not yet available")

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
