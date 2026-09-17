import SwiftUI
import SwiftData

struct EditCategoryView: View {

    // MARK: - Environment

    // MARK: - Environment

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.modelContext)
    private var modelContext

    // Needed to carry a rename through to everything that references
    // this category by name.
    @Query private var transactions: [Transaction]
    @Query private var budgets: [Budget]
    @Query private var customCategories: [UserCategory]

    // MARK: - Category

    let category: UserCategory

    // MARK: - Editing State

    @State private var name: String
    @State private var type: String
    @State private var selectedIcon: String

    // MARK: - UI State

    // MARK: - UI State

    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false

    // MARK: - Available Types

    private let categoryTypes = [
        "Expense",
        "Income"
    ]

    // MARK: - Available Icons

    private let availableIcons = [

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

        _name = State(
            initialValue: category.name
        )

        _type = State(
            initialValue: category.type
        )

        _selectedIcon = State(
            initialValue: category.icon
        )

    }

    // MARK: - Body

    var body: some View {

        NavigationStack {

            ZStack {

                AppColors.background
                    .ignoresSafeArea()

                ScrollView {

                    VStack(
                        alignment: .leading,
                        spacing: 24
                    ) {

                        // MARK: - Category Name

                        VStack(
                            alignment: .leading,
                            spacing: 8
                        ) {

                            Text("Category Name")
                                .font(.headline)
                                .foregroundStyle(
                                    AppColors.primary
                                )

                            TextField(
                                "Enter category name",
                                text: $name
                            )
                            .font(.body)
                            .padding()
                            .background(
                                AppColors.card
                            )
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 12
                                )
                            )
                            .overlay {

                                RoundedRectangle(
                                    cornerRadius: 12
                                )
                                .stroke(
                                    AppColors.divider,
                                    lineWidth: 1
                                )

                            }

                        }

                        // MARK: - Category Type

                        VStack(
                            alignment: .leading,
                            spacing: 8
                        ) {

                            Text("Category Type")
                                .font(.headline)
                                .foregroundStyle(
                                    AppColors.primary
                                )

                            Picker(
                                "Category Type",
                                selection: $type
                            ) {

                                ForEach(
                                    categoryTypes,
                                    id: \.self
                                ) { categoryType in

                                    Text(categoryType)
                                        .tag(categoryType)

                                }

                            }
                            .pickerStyle(.segmented)

                        }

                        // MARK: - Icon

                        VStack(
                            alignment: .leading,
                            spacing: 12
                        ) {

                            Text("Choose Icon")
                                .font(.headline)
                                .foregroundStyle(
                                    AppColors.primary
                                )

                            LazyVGrid(
                                columns: Array(
                                    repeating: GridItem(
                                        .flexible()
                                    ),
                                    count: 5
                                ),
                                spacing: 16
                            ) {

                                ForEach(
                                    availableIcons,
                                    id: \.self
                                ) { icon in

                                    Button {

                                        selectedIcon = icon

                                    } label: {

                                        Image(
                                            systemName: icon
                                        )
                                        .font(
                                            .system(
                                                size: 20
                                            )
                                        )
                                        .foregroundStyle(
                                            selectedIcon == icon
                                            ? .white
                                            : AppColors.primary
                                        )
                                        .frame(
                                            width: 48,
                                            height: 48
                                        )
                                        .background {

                                            Circle()
                                                .fill(
                                                    selectedIcon == icon
                                                    ? AppColors.primary
                                                    : AppColors.primary.opacity(
                                                        0.12
                                                    )
                                                )

                                        }

                                    }
                                    .buttonStyle(.plain)

                                }

                            }

                        }

                        // MARK: - Save Button

                        Button {

                            saveCategory()

                        } label: {

                            Text("Save Changes")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(
                                    maxWidth: .infinity
                                )
                                .padding(
                                    .vertical,
                                    15
                                )
                                .background(
                                    AppColors.primary,
                                    in: RoundedRectangle(
                                        cornerRadius: 14
                                    )
                                )

                        }
                        .buttonStyle(.plain)
                        .disabled(
                            name
                                .trimmingCharacters(
                                    in: .whitespacesAndNewlines
                                )
                                .isEmpty
                        )
                        .opacity(
                            name
                                .trimmingCharacters(
                                    in: .whitespacesAndNewlines
                                )
                                .isEmpty
                            ? 0.5
                            : 1
                        )

                    }
                    .padding()

                }

            }
            .navigationTitle("Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .alert(alertTitle, isPresented: $showAlert) {

                Button("OK", role: .cancel) { }

            } message: {

                Text(alertMessage)

            }
            .toolbar {

                ToolbarItem(
                    placement: .topBarLeading
                ) {

                    Button("Cancel") {

                        dismiss()

                    }

                }

                ToolbarItem(
                    placement: .topBarTrailing
                ) {

                    Button {

                        saveCategory()

                    } label: {

                        Text("Save")
                            .fontWeight(.semibold)

                    }
                    .disabled(
                        name
                            .trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )
                            .isEmpty
                    )

                }

            }

        }

    }

    // MARK: - Save Category

    private func saveCategory() {

        let cleanedName = name
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !cleanedName.isEmpty else {
            return
        }

        let oldName = category.name
        let oldType = category.type

        let nameChanged = oldName != cleanedName
        let typeChanged = oldType != type

        // How many records currently point at this category by name.
        let affectedTransactions = transactions.filter {
            $0.type == oldType && $0.category == oldName
        }

        let affectedBudgets = oldType == "Expense"
            ? budgets.filter { $0.category == oldName }
            : []

        // Switching Expense to Income (or back) would strand every
        // existing transaction under a category that no longer exists on
        // that side. Blocked rather than silently corrupting the history.
        if typeChanged && !affectedTransactions.isEmpty {

            show(
                title: "Can't Change the Type",
                message: "\(affectedTransactions.count) transaction\(affectedTransactions.count == 1 ? " uses" : "s use") this category, so it has to stay \(oldType). Create a new \(type) category instead."
            )

            return

        }

        if
            nameChanged || typeChanged,
            CategoryManager.nameIsTaken(
                cleanedName,
                type: type,
                customCategories: customCategories,
                excluding: category
            )
        {

            show(
                title: "Category Already Exists",
                message: "There's already a \(type.lowercased()) category called \"\(cleanedName)\". Pick a different name."
            )

            return

        }

        category.name = cleanedName
        category.type = type
        category.icon = selectedIcon

        // Transactions and budgets store the category as a plain string,
        // so a rename has to be carried across by hand — otherwise every
        // past transaction keeps the old name, drops out of this
        // category's totals, and its budget stops matching.
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

    private func show(title: String, message: String) {

        alertTitle = title
        alertMessage = message
        showAlert = true

    }

}

#Preview {

    EditCategoryView(
        category: UserCategory(
            name: "My Category",
            icon: "star.fill",
            type: "Expense"
        )
    )

}
