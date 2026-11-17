import SwiftUI
import SwiftData

struct AddTransactionView: View {

    // MARK: - Environment

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
    @State private var selectedDate = Date()

    // Prevents form reset after returning from category selection
    @State private var hasInitialized = false

    // MARK: - Keyboard Focus

    @FocusState private var isAmountFocused: Bool
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isOtherCategoryFocused: Bool

    // MARK: - Edit Mode

    private var isEditMode: Bool {
        transaction != nil
    }

    // MARK: - Available Categories

    private var availableCategories: [Category] {

        customCategories
            .filter { $0.type == type }
            .map {
                Category(
                    name: $0.name,
                    icon: $0.icon,
                    type: $0.type
                )
            }
    }

    // MARK: - Validation

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

    private var canSave: Bool {

        isAmountValid &&
        isCategoryNameValid &&
        !category.isEmpty

    }

    // MARK: - Date Range

    private var dateRange: ClosedRange<Date> {

        let calendar = Calendar.current
        let now = Date()

        let tenYearsAgo = calendar.date(
            byAdding: .year,
            value: -10,
            to: now
        ) ?? now

        let endOfToday = calendar.date(
            bySettingHour: 23,
            minute: 59,
            second: 59,
            of: now
        ) ?? now

        return min(tenYearsAgo, selectedDate)
            ...
            max(endOfToday, selectedDate)
    }

    // MARK: - Body

    var body: some View {

        NavigationStack {

            ZStack {

                AppColors.dashboardGradient
                    .ignoresSafeArea()

                VStack(spacing: 0) {

                    // MARK: Purple Header

                    transactionHeader

                    // MARK: Main Content

                    ScrollView {

                        VStack(
                            spacing: AppColors.sectionSpacing
                        ) {

                            // MARK: Amount

                            AmountInputCard(
                                amount: $amount,
                                accentColor: AppColors.dashboardPurple,
                                isFocused: $isAmountFocused
                            )

                            // MARK: Transaction Type

                            TransactionTypePicker(
                                selection: $type
                            )
                            .onChange(of: type) { _, _ in

                                category = availableCategories
                                    .first?
                                    .name ?? ""

                                otherCategoryName = ""
                                isOtherCategoryFocused = false

                            }

                            // MARK: Category Selection

                            NavigationLink {

                                TransactionCategorySelectionView(
                                    categories: availableCategories,
                                    selectedCategory: $category
                                )

                            } label: {

                                HStack(spacing: 14) {

                                    Image(
                                        systemName: "square.grid.2x2.fill"
                                    )
                                    .font(.system(size: 18))
                                    .foregroundStyle(
                                        AppColors.dashboardPurple
                                    )
                                    .frame(width: 28)

                                    VStack(
                                        alignment: .leading,
                                        spacing: 5
                                    ) {

                                        Text("Category")
                                            .font(.system(size: 13))
                                            .foregroundStyle(
                                                AppColors.textSecondary
                                            )

                                        Text(
                                            category.isEmpty
                                            ? "Select Category"
                                            : category
                                        )
                                        .font(
                                            .system(
                                                size: 16,
                                                weight: .semibold
                                            )
                                        )
                                        .foregroundStyle(
                                            AppColors.textPrimary
                                        )

                                    }

                                    Spacer()

                                    Image(
                                        systemName: "chevron.right"
                                    )
                                    .font(
                                        .system(
                                            size: 13,
                                            weight: .semibold
                                        )
                                    )
                                    .foregroundStyle(
                                        AppColors.textSecondary
                                    )

                                }
                                .padding(AppColors.cardPadding)
                                .background(AppColors.card)
                                .clipShape(
                                    RoundedRectangle(
                                        cornerRadius:
                                            AppColors.cardCornerRadius
                                    )
                                )
                                .overlay {

                                    RoundedRectangle(
                                        cornerRadius:
                                            AppColors.cardCornerRadius
                                    )
                                    .stroke(
                                        AppColors.border,
                                        lineWidth: 1
                                    )

                                }

                            }
                            .buttonStyle(.plain)

                            // MARK: Other Category Name

                            if category == "Others" {

                                FormSectionCard(
                                    icon: "pencil",
                                    iconColor:
                                        AppColors.dashboardPurple
                                ) {

                                    TextField(
                                        "What is this?",
                                        text: $otherCategoryName
                                    )
                                    .font(.subheadline)
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
                                    .submitLabel(.done)
                                    .onSubmit {

                                        isOtherCategoryFocused = false

                                    }

                                }

                            }

                            // MARK: Transaction Title

                            FormSectionCard(
                                icon: "text.alignleft",
                                iconColor: AppColors.dashboardPurple
                            ) {

                                TextField(
                                    "Title (optional)",
                                    text: $title
                                )
                                .font(.subheadline)
                                .foregroundStyle(
                                    AppColors.textPrimary
                                )
                                .focused($isTitleFocused)
                                .submitLabel(.done)
                                .onSubmit {

                                    isTitleFocused = false

                                }

                            }

                            // MARK: Transaction Date

                            FormSectionCard(
                                icon: "calendar",
                                iconColor: AppColors.dashboardPurple
                            ) {

                                DatePicker(
                                    "Date",
                                    selection: $selectedDate,
                                    in: dateRange,
                                    displayedComponents: [.date]
                                )
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .tint(AppColors.dashboardPurple)
                                .accessibilityLabel("Date")

                            }

                        }
                        .padding(
                            .horizontal,
                            AppColors.pageHorizontalPadding
                        )
                        .padding(.top, 20)
                        .padding(.bottom, 32)

                    }
                    .scrollDismissesKeyboard(.interactively)
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

            // MARK: Keyboard Toolbar

            .toolbar {

                ToolbarItemGroup(placement: .keyboard) {

                    Spacer()

                    Button("Done") {

                        isAmountFocused = false
                        isTitleFocused = false
                        isOtherCategoryFocused = false

                    }
                    .fontWeight(.semibold)

                }

            }

            // MARK: Initialize Form Only Once

            .onAppear {

                guard !hasInitialized else {
                    return
                }

                hasInitialized = true

                if let transaction {

                    // MARK: Edit Existing Transaction

                    title = transaction.title

                    amount = CurrencyManager.editableText(
                        for: transaction.amount
                    )

                    category = transaction.category
                    type = transaction.type
                    selectedDate = transaction.date
                    otherCategoryName = ""

                } else {

                    // MARK: Add New Transaction

                    type = defaultType

                    category = customCategories.first {
                        $0.type == defaultType
                    }?.name ?? ""

                    otherCategoryName = ""
                    selectedDate = Date()

                }

            }

        }

    }

    // MARK: - Custom Purple Header

    private var transactionHeader: some View {

        VStack(spacing: 20) {

            // MARK: Navigation Controls

            HStack(spacing: 12) {

                Button("Cancel") {

                    dismiss()

                }
                .font(
                    .system(
                        size: 16,
                        weight: .medium
                    )
                )
                .foregroundStyle(.white)
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )

                Text(
                    isEditMode
                    ? "Edit Transaction"
                    : "Add Transaction"
                )
                .font(
                    .system(
                        size: 18,
                        weight: .bold
                    )
                )
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .fixedSize(
                    horizontal: true,
                    vertical: false
                )

                Button {

                    saveTransaction()

                } label: {

                    Text(
                        isEditMode
                        ? "Update"
                        : "Save"
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
                .frame(
                    maxWidth: .infinity,
                    alignment: .trailing
                )

            }

            // MARK: Header Description

            VStack(
                alignment: .leading,
                spacing: 6
            ) {

                Text(
                    isEditMode
                    ? "Update Transaction"
                    : "New Transaction"
                )
                .font(
                    .system(
                        size: 26,
                        weight: .bold
                    )
                )
                .foregroundStyle(.white)

                Text(
                    isEditMode
                    ? "Edit your transaction details"
                    : "Keep your finances up to date"
                )
                .font(.system(size: 14))
                .foregroundStyle(
                    .white.opacity(0.85)
                )

            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )

        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 28)

    }

    // MARK: - Save Transaction

    private func saveTransaction() {

        guard let amountValue = CurrencyManager.amount(
            from: amount
        ) else {
            return
        }

        guard amountValue > 0 else {
            return
        }

        // MARK: Resolve Other Category

        let trimmedOtherCategory = otherCategoryName
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let finalCategory =
            category == "Others" &&
            !trimmedOtherCategory.isEmpty
            ? trimmedOtherCategory
            : category

        // MARK: Resolve Title

        let trimmedTitle = title
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let finalTitle = trimmedTitle.isEmpty
            ? finalCategory
            : trimmedTitle

        if let transaction {

            // MARK: Edit Existing Transaction

            transaction.title = finalTitle
            transaction.amount = amountValue
            transaction.category = finalCategory
            transaction.type = type
            transaction.date = selectedDate

        } else {

            // MARK: Add New Transaction

            let newTransaction = Transaction(
                title: finalTitle,
                amount: amountValue,
                category: finalCategory,
                type: type,
                date: selectedDate
            )

            modelContext.insert(newTransaction)

        }

        dismiss()

    }

}

// MARK: - Reusable Press Animation

struct PressableButtonStyle: ButtonStyle {

    func makeBody(
        configuration: Configuration
    ) -> some View {

        configuration.label
            .scaleEffect(
                configuration.isPressed
                ? 0.97
                : 1
            )
            .animation(
                .easeInOut(duration: 0.12),
                value: configuration.isPressed
            )

    }

}

// MARK: - Preview

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
