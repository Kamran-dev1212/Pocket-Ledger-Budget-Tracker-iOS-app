import SwiftUI

struct AppLockOverlayView: View {

    let onUnlocked: () -> Void

    @State private var isAuthenticating = false

    var body: some View {

        ZStack {

            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 24) {

                ZStack {

                    Circle()
                        .fill(AppColors.primary.opacity(0.12))
                        .frame(width: 96, height: 96)

                    Image(systemName: "lock.fill")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(AppColors.primary)

                }

                Text("Pocket Ledger is Locked")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.textPrimary)

                Button {

                    attemptUnlock()

                } label: {

                    Text("Unlock")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: 220)
                        .frame(height: 50)

                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.primary)
                .disabled(isAuthenticating)

            }

        }
        .onAppear {

            attemptUnlock()

        }

    }

    private func attemptUnlock() {

        guard !isAuthenticating else {
            return
        }

        isAuthenticating = true

        Task {

            let success = await AppLockManager.authenticate()

            isAuthenticating = false

            if success {
                onUnlocked()
            }

        }

    }

}

#Preview {
    AppLockOverlayView(onUnlocked: {})
}
