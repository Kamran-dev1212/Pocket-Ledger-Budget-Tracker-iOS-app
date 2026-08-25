import SwiftUI

struct InsightCardView<Content: View>: View {

    let icon: String
    let iconColor: Color
    let title: String
    @ViewBuilder let content: Content

    var body: some View {

        VStack(alignment: .leading, spacing: 16) {

            HStack(spacing: 10) {

                ZStack {

                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 38, height: 38)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(iconColor)

                }

                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

            }

            content

        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
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

    }

}

struct InsightEmptyStateView: View {

    let icon: String
    let message: String

    var body: some View {

        HStack(spacing: 10) {

            Image(systemName: icon)
                .foregroundStyle(AppColors.textSecondary)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)

        }
        .padding(.vertical, 4)

    }

}

#Preview {

    ZStack {

        AppColors.background
            .ignoresSafeArea()

        VStack {

            InsightCardView(
                icon: "lightbulb.fill",
                iconColor: AppColors.warning,
                title: "Smart Tips"
            ) {

                InsightEmptyStateView(icon: "tray", message: "Nothing here yet.")

            }

        }
        .padding()

    }

}
