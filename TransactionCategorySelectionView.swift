import SwiftUI

struct TransactionCategorySelectionView: View {

    @Environment(\.dismiss) private var dismiss

    let categories: [Category]
    @Binding var selectedCategory: String

    var body: some View {

        ZStack {

            AppColors.dashboardGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // MARK: - Purple Header

                HStack {

                    Button {
                        dismiss()
                    } label: {

                        HStack(spacing: 6) {

                            Image(systemName: "chevron.left")

                            Text("Back")

                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)

                    }

                    Spacer()

                    Text("Category")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)

                    Spacer()

                    Color.clear
                        .frame(width: 65, height: 30)

                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 30)

                // MARK: - Category List

                ScrollView {

                    LazyVStack(spacing: 0) {

                        ForEach(categories) { item in

                            Button {

                                selectedCategory = item.name
                                dismiss()

                            } label: {

                                HStack(spacing: 14) {

                                    Image(systemName: item.icon)
                                        .font(.system(size: 18))
                                        .foregroundStyle(
                                            AppColors.dashboardPurple
                                        )
                                        .frame(width: 28)

                                    Text(item.name)
                                        .font(.system(size: 16))
                                        .foregroundStyle(
                                            AppColors.textPrimary
                                        )

                                    Spacer()

                                    if selectedCategory == item.name {

                                        Image(systemName: "checkmark")
                                            .fontWeight(.semibold)
                                            .foregroundStyle(
                                                AppColors.dashboardPurple
                                            )

                                    }

                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .contentShape(Rectangle())

                            }
                            .buttonStyle(.plain)

                            Divider()
                                .padding(.leading, 62)

                        }

                    }
                    .padding(.top, 12)

                }
                .background {

                    UnevenRoundedRectangle(
                        topLeadingRadius:
                            AppColors.dashboardContentCornerRadius,
                        topTrailingRadius:
                            AppColors.dashboardContentCornerRadius
                    )
                    .fill(AppColors.dashboardSurface)
                    .ignoresSafeArea(edges: .bottom)

                }

            }

        }
        .toolbar(.hidden, for: .navigationBar)

    }

}
