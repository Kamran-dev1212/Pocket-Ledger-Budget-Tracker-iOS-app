import SwiftUI

struct CategorySelectionCard: View {

    let categories: [Category]
    @Binding var selection: String
    var accentColor: Color

    private let columns = [
        GridItem(.adaptive(minimum: 84), spacing: 12)
    ]

    var body: some View {

        VStack(alignment: .leading, spacing: 14) {

            Text("Category")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(AppColors.textSecondary)

            LazyVGrid(columns: columns, spacing: 12) {

                ForEach(categories) { category in

                    let isSelected = selection == category.name

                    Button {

                        withAnimation(.easeInOut(duration: 0.2)) {
                            selection = category.name
                        }

                    } label: {

                        VStack(spacing: 8) {

                            ZStack {

                                Circle()
                                    .fill(
                                        isSelected
                                            ? accentColor.opacity(0.18)
                                            : AppColors.textSecondary.opacity(0.08)
                                    )
                                    .frame(width: 48, height: 48)

                                Image(systemName: category.icon)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(
                                        isSelected ? accentColor : AppColors.textSecondary
                                    )

                                if isSelected {

                                    Circle()
                                        .stroke(accentColor, lineWidth: 2)
                                        .frame(width: 48, height: 48)

                                }

                            }

                            Text(category.name)
                                .font(.caption)
                                .fontWeight(isSelected ? .semibold : .regular)
                                .foregroundStyle(
                                    isSelected ? AppColors.textPrimary : AppColors.textSecondary
                                )
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)

                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())

                    }
                    .buttonStyle(.plain)

                }

            }

        }
        .padding(AppColors.cardPadding)
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

        CategorySelectionCard(
            categories: CategoryManager.expenseCategories,
            selection: .constant("Food"),
            accentColor: AppColors.expense
        )
        .padding()

    }

}
