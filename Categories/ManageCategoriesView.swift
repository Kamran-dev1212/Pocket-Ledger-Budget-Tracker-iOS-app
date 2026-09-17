import SwiftUI
import SwiftData

struct ManageCategoriesView: View {

    // MARK: - Environment

    @Environment(\.modelContext)
    private var modelContext

    // MARK: - Categories
    //
    // Holds every category — the defaults seeded on first launch and
    // anything the user has added since. There is no longer a separate
    // hardcoded list.

    @Query(
        sort: \UserCategory.name,
        order: .forward
    )
    private var allCategories: [UserCategory]

    // Needed to find — and rescue — everything that points at a category
    // by name before it's deleted.
    @Query private var transactions: [Transaction]
    @Query private var budgets: [Budget]

    // MARK: - UI State

    @State private var showingAddCategory = false

    @State private var showingEditCategory = false

    @State private var categoryToEdit: UserCategory?

    @State private var categoryToDelete: UserCategory?

    @State private var showingDeleteAlert = false

    // MARK: - Computed Categories

    private var expenseCategories: [UserCategory] {

        allCategories.filter {
            $0.type == "Expense"
        }

    }

    private var incomeCategories: [UserCategory] {

        allCategories.filter {
            $0.type == "Income"
        }

    }

    // MARK: - Delete Impact

    private var affectedTransactionCount: Int {

        guard let categoryToDelete else {
            return 0
        }

        return transactions.filter {
            $0.type == categoryToDelete.type
                && $0.category == categoryToDelete.name
        }
        .count

    }

    private var affectedBudgetCount: Int {

        guard
            let categoryToDelete,
            categoryToDelete.type == "Expense"
        else {
            return 0
        }

        return budgets.filter {
            $0.category == categoryToDelete.name
        }
        .count

    }

    /// Where orphaned transactions go. Matched on seedKey so a renamed
    /// "Others" is still found.
    private func fallbackCategoryName(for type: String) -> String? {

        let candidates = allCategories.filter {
            $0.type == type
                && $0.persistentModelID != categoryToDelete?.persistentModelID
        }

        if let others = candidates.first(where: { $0.seedKey == "Others" }) {
            return others.name
        }

        return candidates.first?.name

    }

    private var canDeleteSelected: Bool {

        guard let categoryToDelete else {
            return false
        }

        if affectedTransactionCount == 0 && affectedBudgetCount == 0 {
            return true
        }

        return fallbackCategoryName(for: categoryToDelete.type) != nil

    }

    private var deleteButtonTitle: String {

        affectedTransactionCount > 0 || affectedBudgetCount > 0
            ? "Move & Delete"
            : "Delete"

    }

    private var deleteMessage: String {

        guard let categoryToDelete else {
            return ""
        }

        var parts: [String] = []

        if affectedTransactionCount > 0 {
            parts.append("\(affectedTransactionCount) transaction\(affectedTransactionCount == 1 ? "" : "s")")
        }

        if affectedBudgetCount > 0 {
            parts.append("\(affectedBudgetCount) budget\(affectedBudgetCount == 1 ? "" : "s")")
        }

        guard !parts.isEmpty else {
            return "Nothing is using this category. This can't be undone."
        }

        let subject = parts.joined(separator: " and ")

        guard let destination = fallbackCategoryName(for: categoryToDelete.type) else {

            return "\(subject) use this category, and there's no other \(categoryToDelete.type.lowercased()) category to move them to. Create one first."

        }

        return "\(subject) use this category and will be moved to \"\(destination)\". This can't be undone."

    }

    // MARK: - Body

    var body: some View {

        ZStack {

            AppColors.background
                .ignoresSafeArea()

            List {

                // MARK: - Expense Categories

                Section {

                    ForEach(
                        expenseCategories
                    ) { category in

                        categoryRow(
                            category
                        )

                    }

                } header: {

                    Text("Expense Categories")
                        .foregroundStyle(
                            AppColors.textPrimary
                        )

                }

                // MARK: - Income Categories

                Section {

                    ForEach(
                        incomeCategories
                    ) { category in

                        categoryRow(
                            category
                        )

                    }

                } header: {

                    Text("Income Categories")
                        .foregroundStyle(
                            AppColors.textPrimary
                        )

                }

                // MARK: - Add Category

                Section {

                    Button {

                        showingAddCategory = true

                    } label: {

                        Label(
                            "Add Category",
                            systemImage: "plus.circle.fill"
                        )
                        .font(.headline)
                        .foregroundStyle(
                            AppColors.primary
                        )
                        .frame(
                            maxWidth: .infinity,
                            alignment: .center
                        )
                        .padding(.vertical, 8)

                    }
                    .buttonStyle(.plain)

                }

            }
            .scrollContentBackground(.hidden)

        }
        .navigationTitle("Manage Categories")
        .navigationBarTitleDisplayMode(.inline)

        // MARK: - Add Category Sheet

        .sheet(
            isPresented: $showingAddCategory
        ) {

            AddCategoryView()

        }

        // MARK: - Edit Category Sheet

        .sheet(
            isPresented: $showingEditCategory
        ) {

            if let categoryToEdit {

                EditCategoryView(
                    category: categoryToEdit
                )

            }

        }

        // MARK: - Delete Confirmation

        .alert(
            "Delete \"\(categoryToDelete?.name ?? "")\"?",
            isPresented: $showingDeleteAlert
        ) {

            Button(
                "Cancel",
                role: .cancel
            ) {

                categoryToDelete = nil

            }

            if canDeleteSelected {

                Button(
                    deleteButtonTitle,
                    role: .destructive
                ) {

                    deleteCategory()

                }

            }

        } message: {

            Text(deleteMessage)

        }

    }

    // MARK: - Category Row

    private func categoryRow(
        _ category: UserCategory
    ) -> some View {

        HStack(spacing: 14) {

            Image(
                systemName: category.icon
            )
            .font(.system(size: 17))
            .foregroundStyle(
                CategoryManager.color(for: category)
            )
            .frame(
                width: 30,
                height: 30
            )
            .background(
                CategoryManager.color(for: category).opacity(0.12),
                in: Circle()
            )

            Text(category.name)
                .font(.body)
                .foregroundStyle(
                    AppColors.textPrimary
                )

            Spacer()

            if !category.isDefault {

                Text("Custom")
                    .font(.caption)
                    .foregroundStyle(
                        AppColors.textSecondary
                    )

            }

        }
        .padding(.vertical, 5)
        .listRowBackground(
            AppColors.card
        )
        .swipeActions(
            edge: .trailing,
            allowsFullSwipe: false
        ) {

            // MARK: Delete

            Button(
                role: .destructive
            ) {

                categoryToDelete = category

                showingDeleteAlert = true

            } label: {

                Label(
                    "Delete",
                    systemImage: "trash"
                )

            }

            // MARK: Edit

            Button {

                categoryToEdit = category

                showingEditCategory = true

            } label: {

                Label(
                    "Edit",
                    systemImage: "pencil"
                )

            }
            .tint(
                AppColors.primary
            )

        }

    }

    // MARK: - Delete Category

    private func deleteCategory() {

        guard let categoryToDelete else {
            return
        }

        let name = categoryToDelete.name
        let type = categoryToDelete.type

        // Transactions and budgets reference a category by name, not by
        // relationship, so deleting the category alone would leave them
        // pointing at something that no longer exists — invisible in every
        // category total, with no icon, and with any budget for it
        // stranded.
        if
            affectedTransactionCount > 0 || affectedBudgetCount > 0,
            let destination = fallbackCategoryName(for: type)
        {

            for transaction in transactions
            where transaction.type == type && transaction.category == name {

                transaction.category = destination

            }

            if type == "Expense" {

                for budget in budgets where budget.category == name {

                    budget.category = destination

                }

            }

        }

        modelContext.delete(
            categoryToDelete
        )

        self.categoryToDelete = nil

    }

}

// MARK: - Preview

#Preview {

    NavigationStack {

        ManageCategoriesView()

    }
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
