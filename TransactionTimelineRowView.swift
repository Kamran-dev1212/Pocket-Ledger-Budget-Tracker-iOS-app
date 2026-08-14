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
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(amountColor)

            }

            VStack(alignment: .leading, spacing: 3) {

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                HStack(spacing: 5) {

                    Text(category)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .layoutPriority(1)

                    Text("•")
                        .font(.caption2)
                        .foregroundStyle(AppColors.textSecondary.opacity(0.5))

                    Text(time)
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary.opacity(0.75))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)

                }

            }
            .layoutPriority(1)

            Spacer(minLength: 8)

            // Amount and chevron side by side rather than stacked, so
            // the chevron stays visible without adding row height.

            HStack(spacing: 6) {

                Text(amount)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(amountColor)
                    .monospacedDigit()
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary.opacity(0.4))

            }

        }

    }

}

#Preview {

    ZStack {

        AppColors.background
            .ignoresSafeArea()

        VStack(spacing: 16) {

            TransactionTimelineRowView(
                icon: "cart.fill",
                title: "Pizza",
                category: "Food",
                time: "8:45 PM",
                amount: "-Rs. 2,000",
                amountColor: AppColors.expense
            )

            TransactionTimelineRowView(
                icon: "briefcase.fill",
                title: "Freelance project payment received",
                category: "Business",
                time: "12:47 PM",
                amount: "+Rs. 125,000",
                amountColor: AppColors.success
            )

        }
        .padding()

    }

}
