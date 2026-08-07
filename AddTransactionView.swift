import SwiftUI
import SwiftData

struct AddTransactionView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // MARK: - Custom Categories

    @Query(
        sort: \UserCategory.name,
        order: .forward
    )
    private var customCategories: [UserCategory]

    // MARK: - Transaction

    var transaction: Transaction?
    var defaultType: String = "Expense"

    // MARK: - Form State

    @State private var title = ""
    @State private var amount = ""
    @State private var category = ""
    @State private var type = "Expense"

    // MARK: - Animation State

    @State private var isVisible = false
    @State private var hasAppeared = false

    // MARK: - Keyboard Focus

    @FocusState private var isAmountFocused: Bool

    // MARK: - Edit Mode

    private var isEditMode: Bool {
        transaction != nil
    }

    // MARK: - Accent Color

    private var accentColor: Color {

        type == "Income"
        ? AppColors.success
        : AppColors.expense

    }

    // MARK: - Available Categories

    private var availableCategories: [Category] {

        let builtInCategories =
            CategoryManager.categories(
                for: type
            )

        let customCategoriesForType =
            customCategories
                .filter {
                    $0.type == type
                }
                .map {

                    Category(
                        name: $0.name,
                        icon: $0.icon,
                        type: $0.type
                    )

                }

        return builtInCategories
            + customCategoriesForType

    }

    // MARK: - Display Date

    private var displayDate: String {

        let formatter = DateFormatter()

        formatter.dateFormat = "d MMMM yyyy"

        return formatter.string(
            from: transaction?.date ?? Date()
        )

    }

    // MARK: - Amount Validation

    // Was: Double(amount), which returns nil for "12,50" and
    // silently leaves Save disabled in comma-decimal locales.

    private var isAmountValid: Bool {

        CurrencyManager.isValidAmount(amount)

    }

    // MARK: - Body

    var body: some View {

        NavigationStack {

            ZStack {

                AppColors.background
                    .ignoresSafeArea()

                ScrollView {

                    VStack(
                        spacing: AppColors.sectionSpacing
                    ) {

                        // MARK: Header

                        VStack(
                            alignment: .leading,
                            spacing: 4
                        ) {

                            Text(
                                isEditMode
                                ? "Edit Transaction"
                                : "Add Transaction"
                            )
                            .font(
                                .system(
                                    size: 26,
                                    weight: .bold
                                )
                            )
                            .foregroundStyle(
                                AppColors.textPrimary
                            )

                            Text(
                                isEditMode
                                ? "Update this transaction"
                                : "Track your spending"
                            )
                            .font(
                                .subheadline
                            )
                            .foregroundStyle(
                                AppColors.textSecondary
                            )

                        }
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )

                        // MARK: Amount

                        AmountInputCard(

                            amount: $amount,

                            accentColor: accentColor,

                            isFocused: $isAmountFocused

                        )

                        // MARK: Type Picker

                        TransactionTypePicker(
                            selection: $type
                        )
                        .onChange(
                            of: type
                        ) { _, _ in

                            category =
                                availableCategories
                                .first?
                                .name
                                ?? ""

                        }

                        // MARK: Category

                        CategorySelectionCard(

                            categories:
                                availableCategories,

                            selection: $category,

                            accentColor: accentColor

                        )
                        .onChange(
                            of: category
                        ) { _, _ in

                            if hasAppeared {

                                isAmountFocused = true

                            }

                        }

                        // MARK: Title

                        FormSectionCard(

                            icon: "text.alignleft",

                            iconColor: accentColor

                        ) {

                            TextField(

                                "Title (optional)",

                                text: $title

                            )
                            .font(
                                .subheadline
                            )
                            .foregroundStyle(
                                AppColors.textPrimary
                            )

                        }

                        // MARK: Date

                        FormSectionCard(

                            icon: "calendar",

                            iconColor: accentColor

                        ) {

                            Text(displayDate)
                                .font(
                                    .subheadline
                                )
                                .foregroundStyle(
                                    AppColors.textSecondary
                                )
                                .accessibilityLabel(
                                    "Date"
                                )
                                .accessibilityValue(
                                    displayDate
                                )

                        }

                    }
                    .padding(
                        .horizontal,
                        AppColors.pageHorizontalPadding
                    )
                    .padding(
                        .top,
                        8
                    )
                    .padding(
                        .bottom,
                        24
                    )

                }
                .scrollDismissesKeyboard(
                    .interactively
                )

            }
            .navigationBarTitleDisplayMode(
                .inline
            )
            .toolbar {

                // MARK: Cancel

                ToolbarItem(
                    placement: .topBarLeading
                ) {

                    Button(
                        "Cancel"
                    ) {

                        dismiss()

                    }
                    .foregroundStyle(
                        AppColors.textSecondary
                    )
                    .accessibilityLabel(
                        "Cancel"
                    )

                }

                // MARK: Save

                ToolbarItem(
                    placement: .topBarTrailing
                ) {

                    Button {

                        saveTransaction()

                    } label: {

                        Text("Save")
                            .fontWeight(
                                .semibold
                            )

                    }
                    .disabled(
                        !isAmountValid
                    )
                    .foregroundStyle(
                        accentColor
                    )
                    .accessibilityLabel(

                        isEditMode
                        ? "Update transaction"
                        : "Save transaction"

                    )
                    .accessibilityHint(

                        isAmountValid
                        ? ""
                        : "Enter a valid amount to continue"

                    )

                }

            }
            .opacity(
                isVisible
                ? 1
                : 0
            )
            .offset(
                y:
                    isVisible
                    ? 0
                    : 10
            )
            .onAppear {

                if let transaction {

                    // MARK: Edit Mode

                    title =
                        transaction.title

                    // Was: String(Int(transaction.amount)), which
                    // dropped the decimals on load — so re-saving an
                    // edited 250.75 wrote 250.00 back to the database.

                    amount =
                        CurrencyManager.editableText(
                            for: transaction.amount
                        )

                    category =
                        transaction.category

                    type =
                        transaction.type

                } else {

                    // MARK: Add Mode

                    type =
                        defaultType

                    category =
                        CategoryManager
                        .categories(
                            for: defaultType
                        )
                        .first?
                        .name
                        ?? ""

                }

                withAnimation(
                    .easeOut(
                        duration: 0.3
                    )
                ) {

                    isVisible = true

                }

                DispatchQueue.main.asyncAfter(

                    deadline:
                        .now()
                        + 0.4

                ) {

                    isAmountFocused = true

                    hasAppeared = true

                }

            }

        }

    }

    // MARK: - Save Transaction

    private func saveTransaction() {

        // Was: Double(amount). Parsing now goes through
        // CurrencyManager so both separators are accepted and the
        // value is rounded to two places before it reaches the model.

        guard let amountValue = CurrencyManager.amount(
            from: amount
        ) else {

            return

        }

        guard amountValue > 0 else {

            return

        }

        let finalTitle = title
            .trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )
            .isEmpty

            ? category

            : title

        if let transaction {

            // MARK: Edit Existing Transaction

            transaction.title =
                finalTitle

            transaction.amount =
                amountValue

            transaction.category =
                category

            transaction.type =
                type

        } else {

            // MARK: Add New Transaction

            let newTransaction =
                Transaction(

                    title:
                        finalTitle,

                    amount:
                        amountValue,

                    category:
                        category,

                    type:
                        type

                )

            modelContext.insert(
                newTransaction
            )

        }

        dismiss()

    }

}

// MARK: - Reusable Press Animation

struct PressableButtonStyle: ButtonStyle {

    func makeBody(
        configuration:
            Configuration
    ) -> some View {

        configuration.label
            .scaleEffect(
                configuration.isPressed
                ? 0.97
                : 1
            )
            .animation(
                .easeInOut(
                    duration: 0.12
                ),
                value:
                    configuration.isPressed
            )

    }

}

#Preview {

    AddTransactionView(

        transaction: nil,

        defaultType: "Income"

    )
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
