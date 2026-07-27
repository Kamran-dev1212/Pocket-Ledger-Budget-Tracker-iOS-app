import SwiftUI

// MARK: - Reusable gradient hero summary card
// Mirrors BalanceCardView's structure (same corner radius, padding, and
// shadow tokens) so Income/Expense feel like they belong to the same
// design system as the Dashboard's balance card.

struct TransactionHeroCardView: View {

    let label: String
    let amount: Double
    let transactionCount: Int
    let gradientColors: [Color]
    let icon: String

    @AppStorage("selectedCurrency") private var currency: String = "PKR"

    @State private var isVisible = false

    private var transactionCountText: String {
        "\(transactionCount) Transaction\(transactionCount == 1 ? "" : "s")"
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 16) {

            Text(label)
                .font(.headline)
                .foregroundStyle(AppColors.textOnPrimary.opacity(0.85))

            Text("\(CurrencyManager.symbol(for: currency))\(Int(amount).formatted())")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(AppColors.textOnPrimary)
                .monospacedDigit()

            HStack(spacing: 8) {

                Image(systemName: icon)
                    .foregroundStyle(AppColors.textOnPrimary.opacity(0.65))

                Text(transactionCountText)
                    .font(.footnote)
                    .foregroundStyle(AppColors.textOnPrimary.opacity(0.65))

            }

        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppColors.heroCardPadding)
        .background(

            ZStack {

                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Subtle top highlight for a premium glassy feel (matches BalanceCardView)
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.16),
                        Color.white.opacity(0)
                    ],
                    startPoint: .top,
                    endPoint: .center
                )

            }

        )
        .clipShape(RoundedRectangle(cornerRadius: AppColors.heroCardCornerRadius))
        .shadow(
            color: (gradientColors.first ?? AppColors.primary).opacity(0.16),
            radius: AppColors.heroShadowRadius,
            x: 0,
            y: AppColors.heroShadowY
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

        VStack(spacing: 20) {

            TransactionHeroCardView(
                label: "Total Income",
                amount: 275000,
                transactionCount: 18,
                gradientColors: AppColors.incomeGradient,
                icon: "arrow.down.circle.fill"
            )

            TransactionHeroCardView(
                label: "Total Expense",
                amount: 59600,
                transactionCount: 12,
                gradientColors: AppColors.expenseGradient,
                icon: "arrow.up.circle.fill"
            )

        }
        .padding()

    }

}
