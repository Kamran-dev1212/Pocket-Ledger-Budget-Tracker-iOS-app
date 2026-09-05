import SwiftUI
import SwiftData

@main
struct MyMoney_TrackerApp: App {
@UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @AppStorage("notificationsPermissionRequested")
    private var notificationsPermissionRequested = false

    @AppStorage("selectedAppearance")
    private var appearanceRaw: String =
        AppAppearance.light.rawValue

    private var selectedAppearance: AppAppearance {

        AppAppearance(rawValue: appearanceRaw) ?? .light

    }

    var sharedModelContainer: ModelContainer = {

        let schema = Schema([

            Transaction.self,
            Budget.self,
            UserProfile.self,
            UserCategory.self

        ])

        // MARK: CloudKit Sync
        //
        // .automatic resolves to whichever CloudKit container is
        // configured in this target's Signing & Capabilities — no
        // container identifier is hard-coded here, so there's nothing
        // to keep in sync if that ever changes. This syncs to each
        // user's own private CloudKit database (their data, across
        // their own devices) — it does not yet enable sharing data
        // between different people's accounts. That's a separate,
        // later step (CKShare-based group sharing), built on top of
        // this once it's confirmed working.

        let modelConfiguration = ModelConfiguration(

            schema: schema,

            isStoredInMemoryOnly: false,

            cloudKitDatabase: .automatic

        )

        do {

            return try ModelContainer(

                for: schema,

                configurations: [
                    modelConfiguration
                ]

            )

        } catch {

            fatalError(
                "Could not create ModelContainer: \(error)"
            )

        }

    }()

    // MARK: - Init
    //
    // Runs once, before any view in the app ever renders. If this
    // install has never had a currency set, detects one from the
    // device's region. Every screen that reads "selectedCurrency"
    // will see the correct value from its very first appearance —
    // this only ever does something on a genuinely fresh install,
    // and never overwrites a currency the user has since chosen.

    init() {

        CurrencyManager.applyDetectedCurrencyIfNeeded()

    }

    var body: some Scene {

        WindowGroup {

            ContentView()
                .onAppear {

                    AppearanceManager.apply(selectedAppearance)

                }
                .onChange(of: appearanceRaw) { _, _ in

                    AppearanceManager.apply(selectedAppearance)

                }
                .task {

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

                }

        }
        .modelContainer(
            sharedModelContainer
        )

    }

}
