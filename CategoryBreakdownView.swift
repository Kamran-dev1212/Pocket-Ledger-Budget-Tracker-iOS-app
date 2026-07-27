import SwiftUI

struct CategoryAmount: Identifiable {

    let id = UUID()
    let category: String
    let amount: Double
    let percentage: Double
    let color: Color

}

struct CategoryBreakdownView: View {

    let categories: [CategoryAmount]

    @AppStorage("selectedCurrency") private var currency: String = "PKR"

    var body: some View {

        VStack(spacing: 16) {

            ForEach(categories) { item in

                HStack(spacing: 12) {

                    Circle()
                        .fill(item.color)
                        .frame(width: 12, height: 12)

                    Text(item.category)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(AppColors.textPrimary)

                    Spacer()

                    Text("\(Int(item.percentage))%")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(width: 40, alignment: .trailing)

                    Text("\(CurrencyManager.symbol(for: currency))\(Int(item.amount).formatted())")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.textPrimary)
                        .frame(width: 95, alignment: .trailing)

                }

            }

        }
        .padding()
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(
            color: AppColors.shadow,
            radius: 6,
            x: 0,
            y: 3
        )

    }

}
