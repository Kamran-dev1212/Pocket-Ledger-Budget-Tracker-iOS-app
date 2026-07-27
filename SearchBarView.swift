import SwiftUI

struct SearchBarView: View {

    @Binding var text: String
    var placeholder: String = "Search transactions..."

    var body: some View {

        HStack(spacing: 10) {

            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppColors.textSecondary)

            TextField(placeholder, text: $text)
                .foregroundStyle(AppColors.textPrimary)

            if !text.isEmpty {

                Button {

                    text = ""

                } label: {

                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppColors.textSecondary)

                }

            }

        }
        .padding(16)
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

        SearchBarView(text: .constant(""))
            .padding()

    }

}
