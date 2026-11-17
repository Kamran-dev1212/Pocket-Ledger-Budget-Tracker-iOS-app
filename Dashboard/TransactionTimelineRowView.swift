import SwiftUI

struct TransactionTimelineRowView: View {
    let icon: String
    let title: String
    let category: String
    let time: String
    let amount: String
    let amountColor: Color

    var body: some View {
        HStack(spacing: 10) {

            ZStack {
                Circle()
                    .fill(amountColor.opacity(0.12))
                    .frame(width: 34, height: 34)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(amountColor)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)

                Text("\(category) · \(time)")
                    .font(.system(size: 11))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(amount)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(amountColor)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .layoutPriority(1)
        }
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
    }
}
