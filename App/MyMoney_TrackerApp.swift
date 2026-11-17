
import SwiftUI
import SwiftData

@main
struct MyMoney_TrackerApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self)
    private var appDelegate

    @Environment(\.scenePhase)
    private var scenePhase

    @AppStorage("notificationsPermissionRequested")
    private var notificationsPermissionRequested = false

    @AppStorage("selectedAppearance")
    private var appearanceRaw: String =
        AppAppearance.light.rawValue

    /// Set once, the first time the app ever launches.
    /// Used to give free users a 7-day trial of reminders
    /// before that feature becomes Premium-only.
    @AppStorage("firstLaunchDate")
    private var firstLaunchTimestamp: Double = 0

    private var selectedAppearance: AppAppearance {
        AppAppearance(rawValue: appearanceRaw) ?? .light
    }

    // MARK: - SwiftData Model Container

    var sharedModelContainer: ModelContainer = {

        let schema = Schema([
            Transaction.self,
            Budget.self,
            UserProfile.self,
            UserCategory.self
        ])

        // MARK: CloudKit Sync

        // Uses the CloudKit container configured in
        // Signing & Capabilities.
        //
        // Syncs private user data across their devices.
        // Does not enable multi-user group sharing.

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.kamranzaidi.pocketledger")
        )

        do {

            return try ModelContainer(
                for: schema,
                configurations: [
                    modelConfiguration
                ]
            )

        } catch {

            print(
                "CloudKit-backed store failed to open: \(error)"
            )
        }

        // Fallback: Local persistent store

        do {

            return try ModelContainer(
                for: schema,
                configurations: [
                    ModelConfiguration(
                        schema: schema,
                        isStoredInMemoryOnly: false,
                        cloudKitDatabase: .none
                    )
                ]
            )

        } catch {

            print(
                "Local store failed to open: \(error)"
            )
        }

        // MARK: - Persistent Storage Failure

        // Never silently use temporary storage for financial data.
        // If both persistent configurations fail, stop initialization
        // rather than allowing transactions to be saved temporarily.

        fatalError(
            "Pocket Ledger could not open a persistent database. " +
            "Financial data storage is unavailable."
        )

    }()

    // MARK: - Automatic Monthly Archiving

    /// Archives active transactions dated before the
    /// beginning of the current calendar month.
    ///
    /// Current-month transactions remain active.
    /// Previously archived transactions remain unchanged.
    ///
    /// Runs on app launch and when the app becomes active.

    @MainActor
    private func archivePreviousMonths() {

        let context = sharedModelContainer.mainContext
        let calendar = Calendar.current

        guard let startOfCurrentMonth = calendar.dateInterval(
            of: .month,
            for: Date()
        )?.start else {
            return
        }

        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate<Transaction> {
                !$0.isArchived
            }
        )

        do {

            let activeTransactions = try context.fetch(
                descriptor
            )

            var archivedCount = 0

            for transaction in activeTransactions {

                if transaction.date < startOfCurrentMonth {

                    transaction.isArchived = true

                    archivedCount += 1
                }
            }

            guard archivedCount > 0 else {
                return
            }

            try context.save()

            print(
                "Automatic monthly archive completed: \(archivedCount) transactions."
            )

        } catch {

            // Avoid silently discarding a failed save.
            // The next launch or foreground activation
            // will attempt archiving again.

            print(
                "Automatic monthly archive failed: \(error)"
            )
        }
    }

    // MARK: - Init

    /// Runs before the app's first view appears.
    /// Detects currency on fresh installations only.

    init() {

        CurrencyManager.applyDetectedCurrencyIfNeeded()

        if firstLaunchTimestamp == 0 {

            // Existing users who already requested
            // notification permission retain legacy access.

            if notificationsPermissionRequested {

                UserDefaults.standard.set(
                    true,
                    forKey: SubscriptionManager.legacyUserKey
                )
            }

            firstLaunchTimestamp =
                Date().timeIntervalSince1970
        }
    }

    // MARK: - App Scene

    var body: some Scene {

        WindowGroup {

            ContentView()

                // MARK: App Launch

                .onAppear {

                    AppearanceManager.apply(
                        selectedAppearance
                    )

                    // Archive transactions from
                    // previous calendar months.

                    archivePreviousMonths()
                }

                // MARK: Appearance Changes

                .onChange(of: appearanceRaw) { _, _ in

                    AppearanceManager.apply(
                        selectedAppearance
                    )
                }

                // MARK: App Foreground

                .onChange(of: scenePhase) { _, newPhase in

                    if newPhase == .active {

                        // Check whether a new month
                        // has started while the app
                        // was in the background.

                        archivePreviousMonths()

                        // Refresh StoreKit entitlements.

                        Task {

                            await SubscriptionManager
                                .shared
                                .refreshEntitlementStatus()
                        }
                    }
                }

                // MARK: Launch Tasks

                .task {

                    // Initialize subscription management
                    // when the app launches.

                    _ = SubscriptionManager.shared

                    // Request notification permission
                    // only once.

                    if !notificationsPermissionRequested {

                        let granted =
                            await NotificationManager
                                .shared
                                .requestPermission()

                        notificationsPermissionRequested = true

                        print(
                            "Notifications permission: \(granted)"
                        )
                    }

                    // Refresh subscription status.

                    await SubscriptionManager
                        .shared
                        .refreshEntitlementStatus()

                    // MARK: Reminder Trial

                    let trialEnded =
                        firstLaunchTimestamp > 0
                        && Date().timeIntervalSince1970
                            - firstLaunchTimestamp > 7 * 86400

                    if trialEnded &&
                        !SubscriptionManager.shared.hasPremiumFeatures {

                        UserDefaults.standard.set(
                            ReminderFrequency.off.rawValue,
                            forKey: "incomeExpenseReminder"
                        )
                    }

                    // Apply stored reminder preferences.

                    NotificationManager
                        .shared
                        .applyStoredFrequency()
                }
        }
        .modelContainer(
            sharedModelContainer
        )
    }
}
