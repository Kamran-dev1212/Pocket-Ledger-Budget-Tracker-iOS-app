import SwiftUI

struct DashboardEmptyStateView: View {
    var icon: String = "tray.fill"
    var title: String = "No Transactions Yet"
    var message: String =
        "Start tracking your income and expenses to see them appear here."
    var buttonTitle: String = "Add Transaction"
    var tintColor: Color = AppColors.primary
    var onPrimaryAction: () -> Void

    var body: some View {
        VStack(spacing: 12) {

            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(tintColor)
                .frame(width: 52, height: 52)
                .background(
                    tintColor.opacity(0.10),
                    in: Circle()
                )
                .accessibilityHidden(true)

            VStack(spacing: 5) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)

                Text(message)
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: onPrimaryAction) {
                Text(buttonTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.textOnPrimary)
                    .padding(.horizontal, 18)
                    .frame(minHeight: 44)
                    .background(tintColor, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
    }
}
