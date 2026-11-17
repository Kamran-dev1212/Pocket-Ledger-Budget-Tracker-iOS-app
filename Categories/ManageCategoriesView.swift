
import SwiftUI
import SwiftData

struct ManageCategoriesView: View {

    // MARK: - Environment

    @Environment(\.modelContext)
    private var modelContext

    @Environment(\.dismiss)
    private var dismiss

    // MARK: - Categories

    @Query(
        sort: \UserCategory.name,
        order: .forward
    )
    private var allCategories: [UserCategory]

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
        allCategories.filter { $0.type == "Expense" }
    }

    private var incomeCategories: [UserCategory] {
        allCategories.filter { $0.type == "Income" }
    }

    // MARK: - Delete Impact

    private var affectedTransactionCount: Int {
        guard let categoryToDelete else { return 0 }

        return transactions.filter {
            $0.type == categoryToDelete.type &&
            $0.category == categoryToDelete.name
        }.count
    }

    private var affectedBudgetCount: Int {
        guard let categoryToDelete,
              categoryToDelete.type == "Expense"
        else { return 0 }

        return budgets.filter {
            $0.category == categoryToDelete.name
        }.count
    }

    private func fallbackCategoryName(for type: String) -> String? {

        let candidates = allCategories.filter {
            $0.type == type &&
            $0.persistentModelID != categoryToDelete?.persistentModelID
        }

        if let others = candidates.first(where: {
            $0.seedKey == "Others"
        }) {
            return others.name
        }

        return candidates.first?.name
    }

    private var canDeleteSelected: Bool {

        guard categoryToDelete != nil else { return false }

        if affectedTransactionCount == 0 &&
            affectedBudgetCount == 0 {
            return true
        }

        return fallbackCategoryName(
            for: categoryToDelete!.type
        ) != nil
    }

    private var deleteButtonTitle: String {
        affectedTransactionCount > 0 ||
        affectedBudgetCount > 0
            ? "Move & Delete"
            : "Delete"
    }

    private var deleteMessage: String {

        guard let categoryToDelete else { return "" }

        var parts: [String] = []

        if affectedTransactionCount > 0 {
            parts.append(
                "\(affectedTransactionCount) transaction\(affectedTransactionCount == 1 ? "" : "s")"
            )
        }

        if affectedBudgetCount > 0 {
            parts.append(
                "\(affectedBudgetCount) budget\(affectedBudgetCount == 1 ? "" : "s")"
            )
        }

        guard !parts.isEmpty else {
            return "Nothing is using this category. This can't be undone."
        }

        let subject = parts.joined(separator: " and ")

        guard let destination = fallbackCategoryName(
            for: categoryToDelete.type
        ) else {
            return "\(subject) use this category, and there's no other \(categoryToDelete.type.lowercased()) category to move them to. Create one first."
        }

        return "\(subject) use this category and will be moved to \"\(destination)\". This can't be undone."
    }

    // MARK: - Body

    var body: some View {

        ZStack {

            AppColors.dashboardGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {

                topHeader

                List {

                    Section {

                        ForEach(expenseCategories) { category in
                            categoryRow(category)
                        }

                    } header: {
                        sectionHeader(
                            "Expense Categories",
                            count: expenseCategories.count,
                            icon: "arrow.up.circle.fill"
                        )
                    }

                    Section {

                        ForEach(incomeCategories) { category in
                            categoryRow(category)
                        }

                    } header: {
                        sectionHeader(
                            "Income Categories",
                            count: incomeCategories.count,
                            icon: "arrow.down.circle.fill"
                        )
                    }

                    Section {

                        Button {
                            showingAddCategory = true
                        } label: {

                            HStack(spacing: 10) {

                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20))

                                Text("Add Category")
                                    .font(.system(
                                        size: 16,
                                        weight: .semibold
                                    ))
                            }
                            .foregroundStyle(
                                AppColors.dashboardPurple
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)

                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
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

        // MARK: - Add Category

        .sheet(isPresented: $showingAddCategory) {
            AddCategoryView()
        }

        // MARK: - Edit Category

        .sheet(isPresented: $showingEditCategory) {
            if let categoryToEdit {
                EditCategoryView(category: categoryToEdit)
            }
        }

        // MARK: - Delete Confirmation

        .alert(
            "Delete \"\(categoryToDelete?.name ?? "")\"?",
            isPresented: $showingDeleteAlert
        ) {

            Button("Cancel", role: .cancel) {
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

    // MARK: - Header

    private var topHeader: some View {

        VStack(alignment: .leading, spacing: 24) {

            HStack {

                Button {
                    dismiss()
                } label: {

                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left")
                            .font(.system(
                                size: 15,
                                weight: .semibold
                            ))

                        Text("Back")
                            .font(.system(
                                size: 16,
                                weight: .semibold
                            ))
                    }
                    .foregroundStyle(.white)
                }

                Spacer()

                Text("Manage Categories")
                    .font(.system(
                        size: 17,
                        weight: .semibold
                    ))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    showingAddCategory = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(
                            size: 20,
                            weight: .semibold
                        ))
                        .foregroundStyle(.white)
                }
                .accessibilityLabel("Add Category")
            }

            VStack(alignment: .leading, spacing: 7) {

                Text("Your Categories")
                    .font(.system(
                        size: 27,
                        weight: .bold
                    ))
                    .foregroundStyle(.white)

                Text("Organize your income and expenses")
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

    // MARK: - Section Header

    private func sectionHeader(
        _ title: String,
        count: Int,
        icon: String
    ) -> some View {

        HStack(spacing: 8) {

            Image(systemName: icon)
                .foregroundStyle(
                    AppColors.dashboardPurple
                )

            Text(title)
                .font(.system(
                    size: 15,
                    weight: .semibold
                ))
                .foregroundStyle(
                    AppColors.textPrimary
                )
                .textCase(nil)

            Spacer()

            Text("\(count)")
                .font(.system(
                    size: 12,
                    weight: .semibold
                ))
                .foregroundStyle(
                    AppColors.textSecondary
                )
        }
        .padding(.vertical, 5)
    }

    // MARK: - Category Row

    private func categoryRow(
        _ category: UserCategory
    ) -> some View {

        HStack(spacing: 14) {

            Image(systemName: category.icon)
                .font(.system(size: 17))
                .foregroundStyle(
                    CategoryManager.color(for: category)
                )
                .frame(width: 34, height: 34)
                .background(
                    CategoryManager.color(for: category)
                        .opacity(0.12),
                    in: Circle()
                )

            Text(category.name)
                .font(.system(size: 16))
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
        .padding(.vertical, 7)
        .listRowBackground(AppColors.card)

        .swipeActions(
            edge: .trailing,
            allowsFullSwipe: false
        ) {

            Button(role: .destructive) {
                categoryToDelete = category
                showingDeleteAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }

            Button {
                categoryToEdit = category
                showingEditCategory = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(AppColors.dashboardPurple)
        }
    }

    // MARK: - Delete Category

    private func deleteCategory() {

        guard let categoryToDelete else { return }

        let name = categoryToDelete.name
        let type = categoryToDelete.type

        if affectedTransactionCount > 0 ||
            affectedBudgetCount > 0 {

            guard let destination = fallbackCategoryName(
                for: type
            ) else {
                return
            }

            for transaction in transactions
            where transaction.type == type &&
                transaction.category == name {

                transaction.category = destination
            }

            if type == "Expense" {

                for budget in budgets
                where budget.category == name {

                    budget.category = destination
                }
            }
        }

        modelContext.delete(categoryToDelete)
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
