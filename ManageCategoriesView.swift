import SwiftUI
import SwiftData

struct ManageCategoriesView: View {

    // MARK: - Environment

    @Environment(\.modelContext)
    private var modelContext

    // MARK: - Custom Categories

    @Query(
        sort: \UserCategory.name,
        order: .forward
    )
    private var customCategories: [UserCategory]

    // MARK: - UI State

    @State private var showingAddCategory = false

    @State private var showingEditCategory = false

    @State private var categoryToEdit: UserCategory?

    @State private var categoryToDelete: UserCategory?

    @State private var showingDeleteAlert = false

    // MARK: - Computed Categories

    private var customExpenseCategories: [UserCategory] {

        customCategories.filter {
            $0.type == "Expense"
        }

    }

    private var customIncomeCategories: [UserCategory] {

        customCategories.filter {
            $0.type == "Income"
        }

    }

    // MARK: - Body

    var body: some View {

        ZStack {

            AppColors.background
                .ignoresSafeArea()

            List {

                // MARK: - Expense Categories

                Section {

                    // Built-in Expense Categories

                    ForEach(
                        CategoryManager.expenseCategories
                    ) { category in

                        builtInCategoryRow(
                            name: category.name,
                            icon: category.icon,
                            color: CategoryManager.color(
                                for: category.name
                            )
                        )

                    }

                    // Custom Expense Categories

                    ForEach(
                        customExpenseCategories
                    ) { category in

                        customCategoryRow(
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

                    // Built-in Income Categories

                    ForEach(
                        CategoryManager.incomeCategories
                    ) { category in

                        builtInCategoryRow(
                            name: category.name,
                            icon: category.icon,
                            color: CategoryManager.color(
                                for: category.name
                            )
                        )

                    }

                    // Custom Income Categories

                    ForEach(
                        customIncomeCategories
                    ) { category in

                        customCategoryRow(
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
                            "Add Custom Category",
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
            "Delete Category?",
            isPresented: $showingDeleteAlert
        ) {

            Button(
                "Cancel",
                role: .cancel
            ) { }

            Button(
                "Delete",
                role: .destructive
            ) {

                deleteCategory()

            }

        } message: {

            Text(
                "Are you sure you want to delete this custom category?"
            )

        }

    }

    // MARK: - Built-In Category Row

    private func builtInCategoryRow(
        name: String,
        icon: String,
        color: Color
    ) -> some View {

        HStack(spacing: 14) {

            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundStyle(color)
                .frame(
                    width: 30,
                    height: 30
                )
                .background(
                    color.opacity(0.12),
                    in: Circle()
                )

            Text(name)
                .font(.body)
                .foregroundStyle(
                    AppColors.textPrimary
                )

            Spacer()

            Image(
                systemName: "lock.fill"
            )
            .font(.caption)
            .foregroundStyle(
                AppColors.textSecondary
            )

        }
        .padding(.vertical, 5)
        .listRowBackground(
            AppColors.card
        )

    }

    // MARK: - Custom Category Row

    private func customCategoryRow(
        _ category: UserCategory
    ) -> some View {

        HStack(spacing: 14) {

            Image(
                systemName: category.icon
            )
            .font(.system(size: 17))
            .foregroundStyle(
                AppColors.primary
            )
            .frame(
                width: 30,
                height: 30
            )
            .background(
                AppColors.primary.opacity(0.12),
                in: Circle()
            )

            Text(category.name)
                .font(.body)
                .foregroundStyle(
                    AppColors.textPrimary
                )

            Spacer()

            Text("Custom")
                .font(.caption)
                .foregroundStyle(
                    AppColors.textSecondary
                )

        }
        .padding(.vertical, 5)
        .listRowBackground(
            AppColors.card
        )
        .swipeActions(
            edge: .trailing,
            allowsFullSwipe: false
        ) {

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

        }

    }

    // MARK: - Delete Category

    private func deleteCategory() {

        guard let categoryToDelete else {
            return
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
