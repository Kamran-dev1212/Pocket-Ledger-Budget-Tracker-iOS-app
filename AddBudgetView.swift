import SwiftUI
import SwiftData

struct AddBudgetView: View {

    // MARK: - Environment

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.modelContext)
    private var modelContext

    // MARK: - Custom Categories

    @Query(
        sort: \UserCategory.name,
        order: .forward
    )
    private var customCategories: [UserCategory]

    // MARK: - Budget Being Edited

    var budgetToEdit: Budget?

    // MARK: - Form State

    @State private var category: String
    @State private var amount: String
    @State private var month: Int
    @State private var year: Int

    // MARK: - Constants

    private let months =
        Calendar.current.monthSymbols

    private var years: [Int] {

        let currentYear =
            Calendar.current.component(
                .year,
                from: .now
            )

        return Array(
            (currentYear - 1)
            ...
            (currentYear + 3)
        )

    }

    // MARK: - Available Expense Categories

    private var availableExpenseCategories: [Category] {

        let builtInCategories =
            CategoryManager.expenseCategories

        let customExpenseCategories =
            customCategories
                .filter {
                    $0.type == "Expense"
                }
                .map {

                    Category(

                        name:
                            $0.name,

                        icon:
                            $0.icon,

                        type:
                            $0.type

                    )

                }

        return builtInCategories
            + customExpenseCategories

    }

    // MARK: - Amount Validation

    // Was: Double(amount), which returns nil for comma-decimal input
    // and left Save permanently disabled with no visible reason.

    private var isAmountValid: Bool {

        CurrencyManager.isValidAmount(amount)

    }

    // MARK: - Initializer

    init(
        budgetToEdit: Budget? = nil
    ) {

        self.budgetToEdit =
            budgetToEdit

        let calendar =
            Calendar.current

        let currentDate =
            Date()

        _category =
            State(

                initialValue:

                    budgetToEdit?.category
                    ??
                    CategoryManager
                    .expenseCategories
                    .first?
                    .name
                    ??
                    ""

            )

        // Was: String(Int(budgetToEdit!.amount)), which dropped the
        // decimals on load, so re-saving an edited budget of 4500.50
        // wrote 4500.00 back to the database.

        _amount =
            State(

                initialValue:

                    budgetToEdit
                        .map {

                            CurrencyManager.editableText(
                                for: $0.amount
                            )

                        }
                    ?? ""

            )

        _month =
            State(

                initialValue:

                    budgetToEdit?.month
                    ??
                    calendar.component(
                        .month,
                        from:
                            currentDate
                    )

            )

        _year =
            State(

                initialValue:

                    budgetToEdit?.year
                    ??
                    calendar.component(
                        .year,
                        from:
                            currentDate
                    )

            )

    }

    // MARK: - Body

    var body: some View {

        NavigationStack {

            ZStack {

                AppColors.background
                    .ignoresSafeArea()

                Form {

                    // MARK: Category

                    Section {

                        Picker(

                            "Category",

                            selection:
                                $category

                        ) {

                            ForEach(

                                availableExpenseCategories

                            ) { item in

                                Label(

                                    item.name,

                                    systemImage:
                                        item.icon

                                )
                                .tag(
                                    item.name
                                )

                            }

                        }

                    } header: {

                        Text(
                            "Category"
                        )
                        .foregroundStyle(
                            AppColors.primary
                        )

                    }
                    .listRowBackground(
                        AppColors.card
                    )

                    // MARK: Amount

                    Section {

                        TextField(

                            "Enter Amount",

                            text:
                                $amount

                        )
                        .keyboardType(
                            .decimalPad
                        )

                    } header: {

                        Text(
                            "Monthly Budget"
                        )
                        .foregroundStyle(
                            AppColors.primary
                        )

                    }
                    .listRowBackground(
                        AppColors.card
                    )

                    // MARK: Budget Period

                    Section {

                        Picker(

                            "Month",

                            selection:
                                $month

                        ) {

                            ForEach(

                                1...12,

                                id:
                                    \.self

                            ) { index in

                                Text(

                                    months[
                                        index - 1
                                    ]

                                )
                                .tag(
                                    index
                                )

                            }

                        }

                        Picker(

                            "Year",

                            selection:
                                $year

                        ) {

                            ForEach(

                                years,

                                id:
                                    \.self

                            ) { yearOption in

                                Text(
                                    String(
                                        yearOption
                                    )
                                )
                                .tag(
                                    yearOption
                                )

                            }

                        }

                    } header: {

                        Text(
                            "Budget Period"
                        )
                        .foregroundStyle(
                            AppColors.primary
                        )

                    }
                    .listRowBackground(
                        AppColors.card
                    )

                }
                .scrollContentBackground(
                    .hidden
                )

            }
            .navigationTitle(

                budgetToEdit == nil
                ? "Add Budget"
                : "Edit Budget"

            )
            .toolbar {

                // MARK: Cancel

                ToolbarItem(

                    placement:
                        .topBarLeading

                ) {

                    Button(
                        "Cancel"
                    ) {

                        dismiss()

                    }
                    .accessibilityLabel(
                        "Cancel"
                    )

                }

                // MARK: Save / Update

                ToolbarItem(

                    placement:
                        .topBarTrailing

                ) {

                    Button(

                        budgetToEdit == nil
                        ? "Save"
                        : "Update"

                    ) {

                        saveBudget()

                    }
                    .disabled(
                        !isAmountValid
                    )
                    .accessibilityLabel(

                        budgetToEdit == nil
                        ? "Save budget"
                        : "Update budget"

                    )
                    .accessibilityHint(

                        isAmountValid
                        ? ""
                        : "Enter a valid amount to continue"

                    )

                }

            }

        }

    }

    // MARK: - Save Budget

    private func saveBudget() {

        // Was: Double(amount). Parsing now goes through
        // CurrencyManager so both separators are accepted and the
        // value is rounded to two places before it reaches the model.

        guard let budgetAmount = CurrencyManager.amount(
            from: amount
        ) else {

            return

        }

        guard budgetAmount > 0 else {

            return

        }

        if let existingBudget =
            budgetToEdit {

            // MARK: Update Existing Budget

            existingBudget.category =
                category

            existingBudget.amount =
                budgetAmount

            existingBudget.month =
                month

            existingBudget.year =
                year

        } else {

            // MARK: Create New Budget

            let budget =
                Budget(

                    category:
                        category,

                    amount:
                        budgetAmount,

                    month:
                        month,

                    year:
                        year

                )

            modelContext.insert(
                budget
            )

        }

        dismiss()

    }

}

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
