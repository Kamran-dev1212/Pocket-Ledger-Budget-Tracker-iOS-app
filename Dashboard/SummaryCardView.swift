import SwiftUI

struct SummaryCardView: View {
    let title: String
    let amount: String
    let color: Color
    let icon: String
    var backgroundTint: Color = .clear
    var alignment: HorizontalAlignment = .leading

    private var frameAlignment: Alignment {
        alignment == .trailing ? .trailing : .leading
    }

    var body: some View {
        VStack(alignment: alignment, spacing: 5) {

            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(color)

                Text(title)
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textSecondary)
            }

            Text(amount)
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity, alignment: frameAlignment)
        .frame(height: 56)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
