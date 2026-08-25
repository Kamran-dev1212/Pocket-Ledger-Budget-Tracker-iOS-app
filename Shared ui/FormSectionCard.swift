import SwiftUI

struct FormSectionCard<Content: View>: View {

    let icon: String
    let iconColor: Color
    @ViewBuilder let content: Content

    init(
        icon: String,
        iconColor: Color = AppColors.primary,
        @ViewBuilder content: () -> Content
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }

    var body: some View {

        HStack(spacing: 14) {

            ZStack {

                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(iconColor)

            }

            content

            Spacer(minLength: 0)

        }
        .padding(AppColors.cardPadding)
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

    }

}

#Preview {

    ZStack {

        AppColors.background
            .ignoresSafeArea()

        VStack(spacing: 16) {

            FormSectionCard(icon: "text.alignleft") {

                TextField("Title (optional)", text: .constant(""))
                    .foregroundStyle(AppColors.textPrimary)

            }

            FormSectionCard(icon: "calendar") {

                Text("17 July 2026")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)

            }

        }
        .padding()

    }

}
