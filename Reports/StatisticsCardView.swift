import SwiftUI

struct StatisticsCardView: View {

    let title: String
    let amount: Double
    let icon: String
    let color: Color

    @AppStorage("selectedCurrency") private var currency: String = "PKR"

    @State private var isVisible = false

    var body: some View {

        HStack(spacing: 16) {

            ZStack {

                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 52, height: 52)

                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(color)

            }

            VStack(alignment: .leading, spacing: 2) {

                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)

                Text("\(CurrencyManager.symbol(for: currency))\(Int(amount).formatted())")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(AppColors.textPrimary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

            }

            Spacer()

        }
        .padding(AppColors.cardPadding)
        .frame(maxWidth: .infinity)
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

        VStack(spacing: 16) {

            StatisticsCardView(title: "Income", amount: 275000, icon: "arrow.down.circle.fill", color: AppColors.success)
            StatisticsCardView(title: "Expenses", amount: 59600, icon: "arrow.up.circle.fill", color: AppColors.expense)
            StatisticsCardView(title: "Savings", amount: 215400, icon: "banknote.fill", color: AppColors.primary)

        }
        .padding()

    }

}
