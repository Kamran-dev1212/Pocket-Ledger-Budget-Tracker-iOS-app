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
    @State private var otherCategoryName = ""

    // MARK: - Animation State

    @State private var isVisible = false

    // MARK: - Keyboard Focus

    @FocusState private var isAmountFocused: Bool
    @FocusState private var isOtherCategoryFocused: Bool

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

    private var isAmountValid: Bool {

        CurrencyManager.isValidAmount(amount)

    }
    // MARK: - Category Name Validation
    //
    // "Others" with no typed name would save a transaction literally
    // categorized "Others" — indistinguishable from every other
    // unnamed "Others" transaction, and unable to match any budget
    // that was named more specifically.

    private var isCategoryNameValid: Bool {

        guard category == "Others" else {
            return true
        }

        return !otherCategoryName
            .trimmingCharacters(in: .whitespacesAndNewlines)
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

                            otherCategoryName = ""

                            isOtherCategoryFocused = false

                        }

                        // MARK: Category

                        CategorySelectionCard(

                            categories:
                                availableCategories,

                            selection:
                                $category,

                            accentColor:
                                accentColor

                        )

                        // MARK: Other Category Name

                        if category == "Others" {

                            FormSectionCard(

                                icon: "pencil",

                                iconColor: accentColor

                            ) {

                                TextField(
                                    "What is this?",
                                    text: $otherCategoryName
                                )
                                .font(
                                    .subheadline
                                )
                                .foregroundStyle(
                                    AppColors.textPrimary
                                )
                                .textInputAutocapitalization(
                                    .sentences
                                )
                                .autocorrectionDisabled(false)
                                .focused(
                                    $isOtherCategoryFocused
                                )
                                .submitLabel(
                                    .done
                                )
                                .onSubmit {

                                    isOtherCategoryFocused = false

                                    UIApplication.shared.sendAction(
                                        #selector(
                                            UIResponder.resignFirstResponder
                                        ),
                                        to: nil,
                                        from: nil,
                                        for: nil
                                    )

                                }

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
                        !isAmountValid || !isCategoryNameValid
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

                    amount =
                        CurrencyManager.editableText(
                            for:
                                transaction.amount
                        )

                    category =
                        transaction.category

                    type =
                        transaction.type

                    // If an existing transaction has a custom
                    // category, do not treat it as "Others".
                    // It remains the actual category name.

                    otherCategoryName = ""

                } else {

                    // MARK: Add Mode

                    type =
                        defaultType

                    category =
                        CategoryManager
                            .categories(
                                for:
                                    defaultType
                            )
                            .first?
                            .name
                            ?? ""

                    otherCategoryName = ""

                }

                withAnimation(
                    .easeOut(
                        duration: 0.3
                    )
                ) {

                    isVisible = true

                }

                // IMPORTANT:
                // We intentionally do NOT focus the amount field here.
                //
                // The user must tap the AmountInputCard
                // to open the amount keyboard.

            }

        }

    }

    // MARK: - Save Transaction

    private func saveTransaction() {

        guard let amountValue =
            CurrencyManager.amount(
                from:
                    amount
            )
        else {

            return

        }

        guard amountValue > 0 else {

            return

        }

        // MARK: Resolve Other Category

        let trimmedOtherCategory =
            otherCategoryName
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )

        let finalCategory =
            category == "Others" &&
            !trimmedOtherCategory.isEmpty

            ? trimmedOtherCategory

            : category

        // MARK: Resolve Title

        let trimmedTitle =
            title
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )

        let finalTitle =
            trimmedTitle.isEmpty

            ? finalCategory

            : trimmedTitle

        if let transaction {

            // MARK: Edit Existing Transaction

            transaction.title =
                finalTitle

            transaction.amount =
                amountValue

            transaction.category =
                finalCategory

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
                        finalCategory,

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
                    duration:
                        0.12
                ),
                value:
                    configuration.isPressed
            )

    }

}

// MARK: - Preview

#Preview {

    AddTransactionView(

        transaction:
            nil,

        defaultType:
            "Income"

    )
    .modelContainer(

        for: [

            Transaction.self,
            Budget.self,
            UserProfile.self,
            UserCategory.self

        ],

        inMemory:
            true

    )

}
