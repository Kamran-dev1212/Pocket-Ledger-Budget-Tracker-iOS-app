import SwiftUI

struct TransactionRowView: View {

    let icon: String
    let title: String
    let category: String
    let date: String
    let amount: String
    let amountColor: Color

    // MARK: - New initializer (category + date shown separately)

    init(
        icon: String,
        title: String,
        category: String,
        date: String,
        amount: String,
        amountColor: Color
    ) {
        self.icon = icon
        self.title = title
        self.category = category
        self.date = date
        self.amount = amount
        self.amountColor = amountColor
    }

    // MARK: - Legacy initializer (old call sites passing a single combined string)

    init(
        icon: String,
        title: String,
        date: String,
        amount: String,
        amountColor: Color
    ) {
        self.icon = icon
        self.title = title
        self.category = ""
        self.date = date
        self.amount = amount
        self.amountColor = amountColor
    }

    var body: some View {

        HStack(spacing: 16) {

            ZStack {

                Circle()
                    .fill(amountColor.opacity(0.12))
                    .frame(width: 56, height: 56)

                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(amountColor)

            }

            VStack(alignment: .leading, spacing: 4) {

                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)

                if category.isEmpty {

                    Text(date)
                        .font(.footnote)
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)

                } else {

                    HStack(spacing: 6) {

                        Text(category)
                            .font(.footnote)
                            .fontWeight(.medium)
                            .foregroundStyle(AppColors.textSecondary)

                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(AppColors.textSecondary.opacity(0.5))

                        Text(date)
                            .font(.caption)
                            .foregroundStyle(AppColors.textSecondary.opacity(0.75))

                    }
                    .lineLimit(1)

                }

            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {

                Text(amount)
                    .font(.headline)
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
        .padding(20)
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
        .contentShape(RoundedRectangle(cornerRadius: AppColors.cardCornerRadius))

    }

}

#Preview {

    ZStack {

        AppColors.background
            .ignoresSafeArea()

        VStack(spacing: 12) {

            TransactionRowView(
                icon: "cart.fill",
                title: "Shopping",
                category: "Food",
                date: "14 Jul 2026",
                amount: "-Rs. 2,500",
                amountColor: AppColors.expense
            )

            TransactionRowView(
                icon: "briefcase.fill",
                title: "Monthly Salary",
                date: "Salary • 01 Jul 2026",
                amount: "+Rs. 85,000",
                amountColor: AppColors.success
            )

        }
        .padding()

    }

}
