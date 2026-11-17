import SwiftUI

struct InsightCardView<Content: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .frame(width: 28, height: 28)
                    .background(
                        iconColor.opacity(0.12),
                        in: Circle()
                    )
                    .accessibilityHidden(true)

                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)

                Spacer(minLength: 0)
            }

            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.card)
        .clipShape(
            RoundedRectangle(
                cornerRadius: AppColors.cardCornerRadius
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: AppColors.cardCornerRadius
            )
            .stroke(AppColors.border, lineWidth: 1)
        }
    }
}

struct InsightEmptyStateView: View {
    let icon: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(AppColors.textSecondary)
                .accessibilityHidden(true)

            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
