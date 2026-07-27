import SwiftUI

struct SummaryCardView: View {

    let title: String
    let amount: String
    let color: Color
    let icon: String
    var backgroundTint: Color = .clear

    @State private var isVisible = false

    var body: some View {

        VStack(alignment: .leading, spacing: 10) {

            ZStack {

                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(color)

            }

            Text(title)
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)

            Text(amount)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppColors.cardPadding)
        .background(

            ZStack {
                AppColors.card
                backgroundTint
            }

        )
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
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 8)
        .onAppear {

            withAnimation(.easeOut(duration: 0.35)) {
                isVisible = true
            }

        }

    }

}

#Preview {

    ZStack {

        AppColors.background
            .ignoresSafeArea()

        HStack(spacing: 16) {

            SummaryCardView(
                title: "Income",
                amount: "Rs. 85,000",
                color: AppColors.success,
                icon: "arrow.down",
                backgroundTint: AppColors.successBackground
            )

            SummaryCardView(
                title: "Expense",
                amount: "Rs. 32,500",
                color: AppColors.expense,
                icon: "arrow.up",
                backgroundTint: AppColors.expenseBackground
            )

        }
        .padding()

    }

}
