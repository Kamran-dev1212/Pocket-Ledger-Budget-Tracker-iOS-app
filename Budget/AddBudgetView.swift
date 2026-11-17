import SwiftUI
import SwiftData

struct AddBudgetView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // MARK: - SwiftData

    @Query(sort: \UserCategory.name, order: .forward)
    private var customCategories: [UserCategory]

    @Query
    private var allBudgets: [Budget]

    // MARK: - Configuration

    var budgetToEdit: Budget?

    private let initialMonth: Int?
    private let initialYear: Int?

    // MARK: - Form State

    @State private var category: String
    @State private var otherCategoryName = ""
    @State private var amount: String
    @State private var month: Int
    @State private var year: Int

    @State private var showDuplicateAlert = false
    @State private var duplicateMessage = ""

    @FocusState private var amountIsFocused: Bool

    // MARK: - Constants

    private let months = Calendar.current.monthSymbols

    private var years: [Int] {

        let currentYear = Calendar.current.component(
            .year,
            from: .now
        )

        let firstYear = min(currentYear - 1, year)
        let lastYear = max(currentYear + 3, year)

        return Array(firstYear...lastYear)
    }

    // MARK: - Categories

    private var availableExpenseCategories: [Category] {

        customCategories
            .filter { $0.type == "Expense" }
            .map {
                Category(
                    name: $0.name,
                    icon: $0.icon,
                    type: $0.type
                )
            }
    }

    private var isAmountValid: Bool {

        CurrencyManager.isValidAmount(amount)
    }

    private var isCategoryNameValid: Bool {

        guard category == "Others" else {
            return true
        }

        return !otherCategoryName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
    }

    private var isCategorySelectionValid: Bool {

        guard !category.isEmpty else {
            return false
        }

        if let existingBudget = budgetToEdit,
           category == existingBudget.category {
            return true
        }

        return availableExpenseCategories.contains {
            $0.name == category
        }
    }

    private var canSave: Bool {

        isAmountValid &&
        isCategoryNameValid &&
        isCategorySelectionValid
    }

    // MARK: - Initializer

    init(
        budgetToEdit: Budget? = nil,
        initialMonth: Int? = nil,
        initialYear: Int? = nil
    ) {

        self.budgetToEdit = budgetToEdit
        self.initialMonth = initialMonth
        self.initialYear = initialYear

        let calendar = Calendar.current
        let currentDate = Date()

        _category = State(
            initialValue: budgetToEdit?.category ?? ""
        )

        _amount = State(
            initialValue: budgetToEdit.map {
                CurrencyManager.editableText(for: $0.amount)
            } ?? ""
        )

        _month = State(
            initialValue:
                budgetToEdit?.month ??
                initialMonth ??
                calendar.component(.month, from: currentDate)
        )

        _year = State(
            initialValue:
                budgetToEdit?.year ??
                initialYear ??
                calendar.component(.year, from: currentDate)
        )
    }

    // MARK: - Body

    var body: some View {

        NavigationStack {

            ZStack {

                AppColors.dashboardGradient
                    .ignoresSafeArea()

                VStack(spacing: 0) {

                    // Purple Header

                    addBudgetHeader

                    // Rounded Content

                    VStack(spacing: 0) {

                        budgetForm

                    }
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
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
            .alert(
                "Budget Already Exists",
                isPresented: $showDuplicateAlert
            ) {

                Button("OK", role: .cancel) {}

            } message: {

                Text(duplicateMessage)

            }
            .onAppear {

                ensureValidCategorySelection()

            }
            .onChange(
                of: availableExpenseCategories.map(\.name)
            ) { _, _ in

                ensureValidCategorySelection()

            }

        }

    }

    // MARK: - Custom Purple Header

    private var addBudgetHeader: some View {

        VStack(spacing: 22) {

            // Navigation

            HStack(spacing: 12) {

                Button {

                    dismiss()

                } label: {

                    Text("Cancel")
                        .font(
                            .system(
                                size: 16,
                                weight: .medium
                            )
                        )
                        .foregroundStyle(.white)

                }
                .frame(width: 70, alignment: .leading)
                .accessibilityLabel("Cancel")

                Spacer(minLength: 0)

                Text(
                    budgetToEdit == nil
                    ? "Add Budget"
                    : "Edit Budget"
                )
                .font(
                    .system(
                        size: 18,
                        weight: .bold
                    )
                )
                .foregroundStyle(.white)
                .lineLimit(1)

                Spacer(minLength: 0)

                Button {

                    amountIsFocused = false
                    saveBudget()

                } label: {

                    Text(
                        budgetToEdit == nil
                        ? "Save"
                        : "Update"
                    )
                    .font(
                        .system(
                            size: 16,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        canSave
                        ? Color.white
                        : Color.white.opacity(0.45)
                    )

                }
                .disabled(!canSave)
                .frame(width: 70, alignment: .trailing)
                .accessibilityLabel(
                    budgetToEdit == nil
                    ? "Save budget"
                    : "Update budget"
                )

            }

            // Header Description

            VStack(spacing: 7) {

                Text(
                    budgetToEdit == nil
                    ? "Set Your Budget"
                    : "Update Your Budget"
                )
                .font(
                    .system(
                        size: 24,
                        weight: .bold
                    )
                )
                .foregroundStyle(.white)

                Text(
                    budgetToEdit == nil
                    ? "Plan your monthly spending"
                    : "Adjust your monthly spending limit"
                )
                .font(
                    .system(
                        size: 13,
                        weight: .medium
                    )
                )
                .foregroundStyle(
                    .white.opacity(0.85)
                )
                .multilineTextAlignment(.center)

            }
            .frame(maxWidth: .infinity)

        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 30)
        .frame(maxWidth: .infinity)

    }

    // MARK: - Budget Form

    private var budgetForm: some View {

        Form {

            // MARK: - Category

            Section {

                NavigationLink {

                    BudgetCategorySelectionView(
                        categories: availableExpenseCategories,
                        selectedCategory: $category
                    )

                } label: {

                    HStack(spacing: 12) {

                        Text("Category")
                            .foregroundStyle(AppColors.textPrimary)

                        Spacer()

                        Text(
                            category.isEmpty
                            ? "Select Category"
                            : category
                        )
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)

                    }

                }
                .tint(AppColors.dashboardPurple)

            } header: {

                Text("CATEGORY")
                    .foregroundStyle(AppColors.dashboardPurple)

            }
            .listRowBackground(AppColors.card)
            // MARK: - Other Category

            if category == "Others" {

                Section {

                    TextField(
                        "What is this budget for?",
                        text: $otherCategoryName
                    )
                    .textInputAutocapitalization(.words)

                } header: {

                    Text("CATEGORY NAME")
                        .foregroundStyle(
                            AppColors.dashboardPurple
                        )

                } footer: {

                    Text(
                        "Use the same category name when recording expenses so spending can be tracked correctly."
                    )

                }
                .listRowBackground(AppColors.card)

            }

            // MARK: - Monthly Amount

            Section {

                HStack(spacing: 12) {

                    Image(systemName: "banknote")
                        .font(
                            .system(
                                size: 20,
                                weight: .medium
                            )
                        )
                        .foregroundStyle(
                            AppColors.dashboardPurple
                        )

                    TextField(
                        "Enter Amount",
                        text: $amount
                    )
                    .keyboardType(.decimalPad)
                    .focused($amountIsFocused)
                    .font(
                        .system(
                            size: 20,
                            weight: .semibold
                        )
                    )

                }
                .padding(.vertical, 5)

            } header: {

                Text("MONTHLY BUDGET")
                    .foregroundStyle(
                        AppColors.dashboardPurple
                    )

            } footer: {

                Text(
                    "Set the maximum amount you want to spend in this category."
                )

            }
            .listRowBackground(AppColors.card)

            // MARK: - Budget Period

            Section {

                Picker("Month", selection: $month) {

                    ForEach(1...12, id: \.self) { index in

                        Text(months[index - 1])
                            .tag(index)

                    }

                }
                .tint(AppColors.textSecondary)
                .disabled(budgetToEdit != nil)

                Picker("Year", selection: $year) {

                    ForEach(years, id: \.self) { yearOption in

                        Text(String(yearOption))
                            .tag(yearOption)

                    }

                }
                .tint(AppColors.textSecondary)
                .disabled(budgetToEdit != nil)

            } header: {

                Text("BUDGET PERIOD")
                    .foregroundStyle(
                        AppColors.dashboardPurple
                    )

            } footer: {

                if budgetToEdit != nil {

                    Text(
                        "A budget's month can't be changed. Add a budget in another month instead."
                    )

                }

            }
            .listRowBackground(AppColors.card)

        }
        .scrollContentBackground(.hidden)
        .background(AppColors.dashboardSurface)
        .contentMargins(.top, 10, for: .scrollContent)
        .toolbar {

            ToolbarItemGroup(placement: .keyboard) {

                Spacer()

                Button("Done") {

                    amountIsFocused = false

                }

            }

        }

    }

    // MARK: - Category Selection

    private func ensureValidCategorySelection() {

        // Preserve the existing category while editing.

        if let existingBudget = budgetToEdit,
           category == existingBudget.category {

            return
        }

        // Preserve a valid selected category.

        if availableExpenseCategories.contains(
            where: { $0.name == category }
        ) {

            return
        }

        // Automatically select the first available category.

        category = availableExpenseCategories.first?.name ?? ""

    }

    // MARK: - Save Budget

    private func saveBudget() {

        guard canSave else {
            return
        }

        guard let budgetAmount = CurrencyManager.amount(
            from: amount
        ) else {
            return
        }

        guard budgetAmount > 0 else {
            return
        }

        // Resolve the selected category.

        let trimmedOtherCategory = otherCategoryName
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let finalCategory =
            category == "Others" &&
            !trimmedOtherCategory.isEmpty
            ? trimmedOtherCategory
            : category

        // Check for an existing budget.

        let clash = allBudgets.first {

            $0.category == finalCategory &&
            $0.month == month &&
            $0.year == year &&
            $0.persistentModelID !=
                budgetToEdit?.persistentModelID

        }

        if clash != nil {

            let symbols = Calendar.current.monthSymbols

            let periodName =
                (month >= 1 && month <= symbols.count)
                ? "\(symbols[month - 1]) \(year)"
                : String(year)

            duplicateMessage =
                "\(finalCategory) already has a budget for \(periodName)."

            showDuplicateAlert = true

            return
        }

        // Update an existing budget.

        if let existingBudget = budgetToEdit {

            existingBudget.category = finalCategory
            existingBudget.amount = budgetAmount
            existingBudget.month = month
            existingBudget.year = year

        } else {

            // Create a new budget.

            let budget = Budget(
                category: finalCategory,
                amount: budgetAmount,
                month: month,
                year: year
            )

            modelContext.insert(budget)

        }

        dismiss()

    }

}

// MARK: - Preview

#Preview {

    AddBudgetView()
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
