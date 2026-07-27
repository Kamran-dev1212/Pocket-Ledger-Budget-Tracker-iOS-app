import SwiftUI

struct DashboardEmptyStateView: View {

    var icon: String = "tray.fill"
    var title: String = "No Transactions Yet"
    var message: String = "Start tracking your income and expenses to see them appear here."
    var buttonTitle: String = "Add Transaction"
    var tintColor: Color = AppColors.primary
    var onPrimaryAction: () -> Void

    var body: some View {

        VStack(spacing: 16) {

            ZStack {

                Circle()
                    .fill(tintColor.opacity(0.12))
                    .frame(width: 96, height: 96)

                Image(systemName: icon)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(tintColor)

            }

            VStack(spacing: 6) {

                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(AppColors.textPrimary)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)

            }

            Button(action: onPrimaryAction) {

                Text(buttonTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.textOnPrimary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(tintColor)
                    .clipShape(Capsule())

            }
            .padding(.top, 4)

        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
        .background(AppColors.card)
        .overlay(
            RoundedRectangle(cornerRadius: AppColors.cardCornerRadius)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppColors.cardCornerRadius))
        .shadow(
            color: AppColors.shadow,
            radius: AppColors.cardShadowRadius,
            x: 0,
            y: AppColors.cardShadowY
        )

    }

}

#Preview {

    ZStack {

        AppColors.background
            .ignoresSafeArea()

        DashboardEmptyStateView(onPrimaryAction: {})
            .padding()

    }

}
