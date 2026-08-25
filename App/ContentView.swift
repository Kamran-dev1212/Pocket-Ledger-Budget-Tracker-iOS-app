import SwiftUI

struct ContentView: View {

    @AppStorage("appLockEnabled") private var isAppLockEnabled = false

    @State private var isUnlocked = false

    var body: some View {

        ZStack {

            HomeView()

            if isAppLockEnabled && !isUnlocked {

                AppLockOverlayView {

                    isUnlocked = true

                }
                .transition(.opacity)

            }

        }

    }

}

#Preview {
    ContentView()
}
