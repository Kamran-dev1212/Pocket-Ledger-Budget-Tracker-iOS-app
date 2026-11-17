
import SwiftUI
import SwiftData

struct EditCategoryView: View {

    // MARK: - Environment

    @Environment(\.dismiss)
    private var dismiss

    @Query private var transactions: [Transaction]
    @Query private var budgets: [Budget]
    @Query private var customCategories: [UserCategory]

    // MARK: - Category

    let category: UserCategory

    // MARK: - Editing State

    @State private var name: String
    @State private var type: String
    @State private var selectedIcon: String

    @FocusState private var nameIsFocused: Bool

    // MARK: - Alert State

    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false

    // MARK: - Icons

    private let availableIcons = [
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
        "arrow.uturn.left.circle.fill",
        "ellipsis.circle.fill",
        "gamecontroller.fill",
        "music.note",
        "film.fill",
        "heart.fill",
        "person.fill",
        "pawprint.fill",
        "phone.fill",
        "wifi",
        "creditcard.fill",
        "dollarsign.circle.fill"
    ]

    // MARK: - Initializer

    init(category: UserCategory) {

        self.category = category

        _name = State(initialValue: category.name)
        _type = State(initialValue: category.type)
        _selectedIcon = State(initialValue: category.icon)
    }

    // MARK: - Validation

    private var cleanedName: String {
        name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private var isNameValid: Bool {
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
                alertTitle,
                isPresented: $showAlert
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
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

                Text("Edit Category")
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
                                isNameValid ? 1 : 0.5
                            )
                        )
                }
                .disabled(!isNameValid)
            }

            VStack(alignment: .leading, spacing: 8) {

                Text("Edit Category")
                    .font(.system(
                        size: 27,
                        weight: .bold
                    ))
                    .foregroundStyle(.white)

                Text("Update your category details")
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
                    ? "Category Name"
                    : cleanedName
            )
            .font(.system(
                size: 20,
                weight: .bold
            ))
            .foregroundStyle(AppColors.textPrimary)
            .lineLimit(2)
            .multilineTextAlignment(.center)

            Text(type)
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
                .foregroundStyle(AppColors.textPrimary)

            TextField(
                "Enter category name",
                text: $name
            )
            .focused($nameIsFocused)
            .font(.body)
            .foregroundStyle(AppColors.textPrimary)
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
                .foregroundStyle(AppColors.textPrimary)

            Picker(
                "Category Type",
                selection: $type
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
                .foregroundStyle(AppColors.textPrimary)

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

                ForEach(
                    availableIcons,
                    id: \.self
                ) { icon in

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

            Text("Save Changes")
                .font(.system(
                    size: 16,
                    weight: .semibold
                ))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    AppColors.dashboardPurple.opacity(
                        isNameValid ? 1 : 0.45
                    ),
                    in: RoundedRectangle(
                        cornerRadius: 15
                    )
                )
        }
        .buttonStyle(.plain)
        .disabled(!isNameValid)
    }

    // MARK: - Save Category

    private func saveCategory() {

        guard isNameValid else { return }

        let oldName = category.name
        let oldType = category.type

        let nameChanged = oldName != cleanedName
        let typeChanged = oldType != type

        // Find transactions and budgets that reference
        // the category's original name.

        let affectedTransactions = transactions.filter {
            $0.type == oldType &&
            $0.category == oldName
        }

        let affectedBudgets: [Budget] =
            oldType == "Expense"
            ? budgets.filter {
                $0.category == oldName
            }
            : []

        // Prevent changing a category's type if it is
        // already used by existing transactions.

        if typeChanged && !affectedTransactions.isEmpty {

            show(
                title: "Can't Change the Type",
                message: "\(affectedTransactions.count) transaction\(affectedTransactions.count == 1 ? " uses" : "s use") this category, so it has to stay \(oldType). Create a new \(type) category instead."
            )

            return
        }

        // Prevent duplicate names within the same type.

        if (nameChanged || typeChanged) &&
            CategoryManager.nameIsTaken(
                cleanedName,
                type: type,
                customCategories: customCategories,
                excluding: category
            ) {

            show(
                title: "Category Already Exists",
                message: "There's already a \(type.lowercased()) category called \"\(cleanedName)\". Pick a different name."
            )

            return
        }

        // Update the category.

        category.name = cleanedName
        category.type = type
        category.icon = selectedIcon

        // Preserve transaction and budget references
        // when the category is renamed.

        if nameChanged {

            for transaction in affectedTransactions {
                transaction.category = cleanedName
            }

            for budget in affectedBudgets {
                budget.category = cleanedName
            }
        }

        dismiss()
    }

    // MARK: - Alert Helper

    private func show(
        title: String,
        message: String
    ) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

// MARK: - Preview

#Preview {

    EditCategoryView(
        category: UserCategory(
            name: "My Category",
            icon: "star.fill",
            type: "Expense"
        )
    )
}
