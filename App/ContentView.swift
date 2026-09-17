import SwiftUI

struct ContentView: View {

    @Environment(\.scenePhase)
    private var scenePhase

    @Environment(\.modelContext)
    private var modelContext

    @AppStorage("appLockEnabled")
    private var isAppLockEnabled = false

    @State private var isUnlocked = false

    @ObservedObject private var saveReporter = SaveReporter.shared

    var body: some View {

        ZStack {

            HomeView()

            // iOS takes the app-switcher snapshot while the scene is
            // inactive. Without this cover, anyone who opens the switcher
            // sees the balance and recent transactions of a "locked" app.
            if isAppLockEnabled && scenePhase != .active {

                privacyCover

            }

            if isAppLockEnabled && !isUnlocked {

                AppLockOverlayView {

                    isUnlocked = true

                }
                .transition(.opacity)

            }

        }
        .task {

            CategorySeeder.run(in: modelContext)

        }
        .onChange(of: scenePhase) { _, newPhase in

            // Re-lock only when the app actually leaves the screen.
            // Deliberately not on .inactive — presenting the Face ID sheet
            // makes the scene inactive, so locking there would cancel the
            // unlock at the moment it succeeded.
            if newPhase == .background {

                isUnlocked = false

            }

        }
        .alert(
            "Couldn't Save",
            isPresented: Binding(
                get: { saveReporter.message != nil },
                set: { if !$0 { saveReporter.message = nil } }
            )
        ) {

            Button("OK", role: .cancel) { }

        } message: {

            Text(saveReporter.message ?? "")

        }
        .onChange(of: isAppLockEnabled) { _, enabled in

            if enabled {

                // Switched on from inside Settings — don't throw the user
                // out of the session they're already in.
                isUnlocked = true

            }

        }

    }

    // MARK: - Privacy Cover

    private var privacyCover: some View {

        ZStack {

            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 14) {

                Image(systemName: "lock.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(AppColors.primary)

                Text("Pocket Ledger")
                    .font(.headline)
                    .foregroundStyle(AppColors.textSecondary)

            }

        }

    }

}

#Preview {
    ContentView()
}
