import SwiftUI
import SwiftData

struct AddCategoryView: View {

    // MARK: - Environment

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.modelContext)
    private var modelContext

    // MARK: - Form State

    @State private var categoryName = ""

    @State private var categoryType = "Expense"

    @State private var selectedIcon = "tag.fill"

    // MARK: - Available Icons

    private let icons = [

        "tag.fill",
        "fork.knife",
        "bag.fill",
        "car.fill",
        "fuelpump.fill",
        "doc.text.fill",
        "cross.case.fill",
        "book.fill",
        "tv.fill",
        "airplane",
        "house.fill",
        "cart.fill",
        "briefcase.fill",
        "banknote.fill",
        "laptopcomputer",
        "building.2.fill",
        "chart.line.uptrend.xyaxis",
        "star.circle.fill",
        "gift.fill",
        "heart.fill",
        "gamecontroller.fill",
        "figure.run",
        "cup.and.saucer.fill",
        "phone.fill",
        "wifi",
        "creditcard.fill"

    ]

    // MARK: - Validation

    private var isCategoryNameValid: Bool {

        !categoryName
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty

    }

    // MARK: - Body

    var body: some View {

        NavigationStack {

            ZStack {

                AppColors.background
                    .ignoresSafeArea()

                ScrollView {

                    VStack(
                        alignment: .leading,
                        spacing: 24
                    ) {

                        // MARK: - Category Preview

                        categoryPreview

                        // MARK: - Category Name

                        VStack(
                            alignment: .leading,
                            spacing: 8
                        ) {

                            Text("Category Name")
                                .font(.headline)
                                .foregroundStyle(
                                    AppColors.textPrimary
                                )

                            TextField(
                                "Enter category name",
                                text: $categoryName
                            )
                            .font(.body)
                            .foregroundStyle(
                                AppColors.textPrimary
                            )
                            .padding(
                                .horizontal,
                                14
                            )
                            .padding(
                                .vertical,
                                13
                            )
                            .background(
                                AppColors.card
                            )
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 12
                                )
                            )
                            .overlay {

                                RoundedRectangle(
                                    cornerRadius: 12
                                )
                                .stroke(
                                    AppColors.divider,
                                    lineWidth: 1
                                )

                            }

                        }

                        // MARK: - Category Type

                        VStack(
                            alignment: .leading,
                            spacing: 8
                        ) {

                            Text("Category Type")
                                .font(.headline)
                                .foregroundStyle(
                                    AppColors.textPrimary
                                )

                            Picker(
                                "Category Type",
                                selection: $categoryType
                            ) {

                                Text("Expense")
                                    .tag("Expense")

                                Text("Income")
                                    .tag("Income")

                            }
                            .pickerStyle(
                                .segmented
                            )

                        }

                        // MARK: - Icon Selection

                        VStack(
                            alignment: .leading,
                            spacing: 12
                        ) {

                            Text("Choose Icon")
                                .font(.headline)
                                .foregroundStyle(
                                    AppColors.textPrimary
                                )

                            LazyVGrid(

                                columns: Array(
                                    repeating:
                                        GridItem(
                                            .flexible()
                                        ),
                                    count: 5
                                ),

                                spacing: 14

                            ) {

                                ForEach(
                                    icons,
                                    id: \.self
                                ) { icon in

                                    Button {

                                        selectedIcon = icon

                                    } label: {

                                        Image(
                                            systemName: icon
                                        )
                                        .font(
                                            .system(
                                                size: 20
                                            )
                                        )
                                        .foregroundStyle(
                                            selectedIcon == icon
                                            ? .white
                                            : AppColors.primary
                                        )
                                        .frame(
                                            width: 48,
                                            height: 48
                                        )
                                        .background(

                                            selectedIcon == icon
                                            ? AppColors.primary
                                            : AppColors.primary.opacity(
                                                0.12
                                            ),

                                            in: RoundedRectangle(
                                                cornerRadius: 12
                                            )

                                        )

                                    }
                                    .buttonStyle(
                                        .plain
                                    )

                                }

                            }

                        }

                        // MARK: - Save Button

                        Button {

                            saveCategory()

                        } label: {

                            Text("Save Category")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(
                                    maxWidth: .infinity
                                )
                                .padding(
                                    .vertical,
                                    16
                                )
                                .background(

                                    isCategoryNameValid
                                    ? AppColors.primary
                                    : AppColors.primary.opacity(
                                        0.45
                                    ),

                                    in: RoundedRectangle(
                                        cornerRadius: 14
                                    )

                                )

                        }
                        .buttonStyle(
                            .plain
                        )
                        .disabled(
                            !isCategoryNameValid
                        )

                    }
                    .padding()

                }

            }
            .navigationTitle("Add Category")
            .navigationBarTitleDisplayMode(
                .inline
            )
            .toolbar {

                ToolbarItem(
                    placement: .topBarLeading
                ) {

                    Button("Cancel") {

                        dismiss()

                    }
                    .foregroundStyle(
                        AppColors.textSecondary
                    )

                }

            }

        }

    }

    // MARK: - Category Preview

    private var categoryPreview: some View {

        VStack(spacing: 12) {

            Image(
                systemName: selectedIcon
            )
            .font(
                .system(
                    size: 38
                )
            )
            .foregroundStyle(
                AppColors.primary
            )
            .frame(
                width: 84,
                height: 84
            )
            .background(
                AppColors.primary.opacity(
                    0.12
                ),
                in: Circle()
            )

            Text(

                categoryName
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    .isEmpty

                ? "New Category"
                : categoryName

            )
            .font(
                .title3
            )
            .fontWeight(
                .semibold
            )
            .foregroundStyle(
                AppColors.textPrimary
            )

            Text(categoryType)
                .font(
                    .subheadline
                )
                .foregroundStyle(
                    AppColors.textSecondary
                )

        }
        .frame(
            maxWidth: .infinity
        )
        .padding(
            .vertical,
            10
        )

    }

    // MARK: - Save Category

    private func saveCategory() {

        let cleanedName = categoryName
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !cleanedName.isEmpty else {
            return
        }

        let newCategory = UserCategory(

            name: cleanedName,

            icon: selectedIcon,

            type: categoryType,

            isDefault: false

        )

        modelContext.insert(
            newCategory
        )

        dismiss()

    }

}

#Preview {

    AddCategoryView()
        .modelContainer(

            for: [

                Transaction.self,
                Budget.self,
                UserProfile.self,
                UserCategory.self

            ],

            inMemory: true

        )

}
