
import SwiftUI
import SwiftData

struct AddCategoryView: View {

    // MARK: - Environment

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.modelContext)
    private var modelContext

    @Query private var customCategories: [UserCategory]

    // MARK: - State

    @State private var showDuplicateAlert = false
    @State private var duplicateMessage = ""

    @State private var categoryName = ""
    @State private var categoryType = "Expense"
    @State private var selectedIcon = "tag.fill"

    @FocusState private var nameIsFocused: Bool

    // MARK: - Icons

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

    private var cleanedName: String {
        categoryName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private var isCategoryNameValid: Bool {
        !cleanedName.isEmpty
    }

    // MARK: - Body

    var body: some View {

        NavigationStack {

            ZStack {

                AppColors.dashboardGradient
                    .ignoresSafeArea()

                VStack(spacing: 0) {

                    topHeader

                    ScrollView {

                        VStack(
                            alignment: .leading,
                            spacing: 22
                        ) {

                            categoryPreview

                            nameSection

                            typeSection

                            iconSection

                            saveButton

                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 24)
                        .padding(.bottom, 36)

                    }
                    .scrollDismissesKeyboard(.interactively)
                    .background(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 28,
                            topTrailingRadius: 28
                        )
                        .fill(AppColors.dashboardSurface)
                        .ignoresSafeArea(edges: .bottom)
                    )

                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .alert(
                "Category Already Exists",
                isPresented: $showDuplicateAlert
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(duplicateMessage)
            }
        }
    }

    // MARK: - Header

    private var topHeader: some View {

        VStack(alignment: .leading, spacing: 24) {

            HStack {

                Button {
                    dismiss()
                } label: {

                    Text("Cancel")
                        .font(.system(
                            size: 16,
                            weight: .semibold
                        ))
                        .foregroundStyle(.white)

                }

                Spacer()

                Text("Add Category")
                    .font(.system(
                        size: 17,
                        weight: .semibold
                    ))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    nameIsFocused = false
                    saveCategory()
                } label: {

                    Text("Save")
                        .font(.system(
                            size: 16,
                            weight: .semibold
                        ))
                        .foregroundStyle(
                            .white.opacity(
                                isCategoryNameValid ? 1 : 0.5
                            )
                        )

                }
                .disabled(!isCategoryNameValid)
            }

            VStack(alignment: .leading, spacing: 8) {

                Text("New Category")
                    .font(.system(
                        size: 27,
                        weight: .bold
                    ))
                    .foregroundStyle(.white)

                Text("Personalize how you track your money")
                    .font(.system(size: 14))
                    .foregroundStyle(
                        .white.opacity(0.85)
                    )

            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 14)
        .padding(.bottom, 28)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    // MARK: - Preview

    private var categoryPreview: some View {

        VStack(spacing: 12) {

            Image(systemName: selectedIcon)
                .font(.system(size: 34))
                .foregroundStyle(
                    AppColors.dashboardPurple
                )
                .frame(width: 78, height: 78)
                .background(
                    AppColors.dashboardPurple.opacity(0.12),
                    in: Circle()
                )

            Text(
                cleanedName.isEmpty
                    ? "New Category"
                    : cleanedName
            )
            .font(.system(
                size: 20,
                weight: .bold
            ))
            .foregroundStyle(AppColors.textPrimary)
            .lineLimit(2)
            .multilineTextAlignment(.center)

            Text(categoryType)
                .font(.subheadline)
                .foregroundStyle(
                    AppColors.textSecondary
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(
            AppColors.card,
            in: RoundedRectangle(cornerRadius: 20)
        )
    }

    // MARK: - Category Name

    private var nameSection: some View {

        VStack(alignment: .leading, spacing: 10) {

            Text("Category Name")
                .font(.system(
                    size: 16,
                    weight: .semibold
                ))
                .foregroundStyle(
                    AppColors.textPrimary
                )

            TextField(
                "Enter category name",
                text: $categoryName
            )
            .focused($nameIsFocused)
            .font(.body)
            .foregroundStyle(
                AppColors.textPrimary
            )
            .padding(15)
            .background(
                AppColors.card,
                in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        AppColors.divider,
                        lineWidth: 1
                    )
            }
            .submitLabel(.done)
            .onSubmit {
                nameIsFocused = false
            }
        }
    }

    // MARK: - Category Type

    private var typeSection: some View {

        VStack(alignment: .leading, spacing: 10) {

            Text("Category Type")
                .font(.system(
                    size: 16,
                    weight: .semibold
                ))
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
            .pickerStyle(.segmented)
            .tint(AppColors.dashboardPurple)
        }
    }

    // MARK: - Icon Selection

    private var iconSection: some View {

        VStack(alignment: .leading, spacing: 14) {

            Text("Choose Icon")
                .font(.system(
                    size: 16,
                    weight: .semibold
                ))
                .foregroundStyle(
                    AppColors.textPrimary
                )

            LazyVGrid(
                columns: Array(
                    repeating: GridItem(
                        .flexible(),
                        spacing: 10
                    ),
                    count: 5
                ),
                spacing: 12
            ) {

                ForEach(icons, id: \.self) { icon in

                    Button {
                        selectedIcon = icon
                    } label: {

                        Image(systemName: icon)
                            .font(.system(size: 19))
                            .foregroundStyle(
                                selectedIcon == icon
                                    ? Color.white
                                    : AppColors.dashboardPurple
                            )
                            .frame(
                                maxWidth: .infinity,
                                minHeight: 48
                            )
                            .background(
                                selectedIcon == icon
                                    ? AppColors.dashboardPurple
                                    : AppColors.dashboardPurple
                                        .opacity(0.10),
                                in: RoundedRectangle(
                                    cornerRadius: 13
                                )
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(icon)
                    .accessibilityAddTraits(
                        selectedIcon == icon
                            ? .isSelected
                            : []
                    )
                }
            }
        }
        .padding(16)
        .background(
            AppColors.card,
            in: RoundedRectangle(cornerRadius: 20)
        )
    }

    // MARK: - Save Button

    private var saveButton: some View {

        Button {

            nameIsFocused = false
            saveCategory()

        } label: {

            Text("Save Category")
                .font(.system(
                    size: 16,
                    weight: .semibold
                ))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    AppColors.dashboardPurple.opacity(
                        isCategoryNameValid ? 1 : 0.45
                    ),
                    in: RoundedRectangle(cornerRadius: 15)
                )

        }
        .buttonStyle(.plain)
        .disabled(!isCategoryNameValid)
    }

    // MARK: - Save Category

    private func saveCategory() {

        guard isCategoryNameValid else {
            return
        }

        guard !CategoryManager.nameIsTaken(
            cleanedName,
            type: categoryType,
            customCategories: customCategories
        ) else {

            duplicateMessage =
                "There's already a \(categoryType.lowercased()) category called \"\(cleanedName)\". Pick a different name."

            showDuplicateAlert = true
            return
        }

        let newCategory = UserCategory(
            name: cleanedName,
            icon: selectedIcon,
            type: categoryType,
            isDefault: false
        )

        modelContext.insert(newCategory)
        dismiss()
    }
}

// MARK: - Preview

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
