import SwiftUI
import SwiftData

@main
struct MyMoney_TrackerApp: App {
    @AppStorage("notificationsPermissionRequested")
    private var notificationsPermissionRequested = false

    @AppStorage("selectedAppearance")
    private var appearanceRaw: String =
        AppAppearance.light.rawValue

    private var preferredColorScheme: ColorScheme? {

        switch AppAppearance(
            rawValue: appearanceRaw
        ) ?? .light {

        case .light:
            return .light

        case .dark:
            return .dark

        }

    }

    var sharedModelContainer: ModelContainer = {

        let schema = Schema([

            Transaction.self,
            Budget.self,
            UserProfile.self,
            UserCategory.self

        ])

        let modelConfiguration = ModelConfiguration(

            schema: schema,

            isStoredInMemoryOnly: false

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

    var body: some Scene {

        WindowGroup {

            ContentView()
                .preferredColorScheme(
                    preferredColorScheme
                )
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
