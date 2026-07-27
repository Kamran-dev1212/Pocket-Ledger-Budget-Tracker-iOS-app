import SwiftUI

struct TransactionTimelineRowView: View {

    let icon: String
    let title: String
    let category: String
    let time: String
    let amount: String
    let amountColor: Color

    var body: some View {

        HStack(spacing: 12) {

            ZStack {

                Circle()
                    .fill(amountColor.opacity(0.12))
                    .frame(width: 46, height: 46)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(amountColor)

            }

            VStack(alignment: .leading, spacing: 4) {

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 6) {

                    Text(category)
                        .font(.footnote)
                        .fontWeight(.medium)
                        .foregroundStyle(AppColors.textSecondary)

                    Text("•")
                        .font(.caption2)
                        .foregroundStyle(AppColors.textSecondary.opacity(0.5))

                    Text(time)
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary.opacity(0.75))

                }
                .lineLimit(1)

            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {

                Text(amount)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(amountColor)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(AppColors.textSecondary.opacity(0.4))

            }

        }

    }

}

#Preview {

    ZStack {

        AppColors.background
            .ignoresSafeArea()

        TransactionTimelineRowView(
            icon: "cart.fill",
            title: "Pizza",
            category: "Food",
            time: "8:45 PM",
            amount: "-Rs. 2,000",
            amountColor: AppColors.expense
        )
        .padding()

    }

}
