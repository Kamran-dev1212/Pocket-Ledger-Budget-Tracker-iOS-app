import SwiftUI

struct SettingsSectionView<Content: View>: View {

    let title: String
    @ViewBuilder let content: Content

    var body: some View {

        VStack(alignment: .leading, spacing: 10) {

            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(AppColors.textSecondary)
                .padding(.horizontal, 6)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 0) {

                content

            }
            .padding(.horizontal, 16)
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: AppColors.cardCornerRadius))
            .shadow(
                color: AppColors.shadow,
                radius: AppColors.cardShadowRadius,
                x: 0,
                y: AppColors.cardShadowY
            )

        }

    }

}
