import SwiftUI
import SwiftData

struct EditCategoryView: View {

    // MARK: - Environment

    @Environment(\.dismiss)
    private var dismiss

    // MARK: - Category

    let category: UserCategory

    // MARK: - Editing State

    @State private var name: String
    @State private var type: String
    @State private var selectedIcon: String

    // MARK: - UI State

    @State private var showDeleteAlert = false

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

        category.name = cleanedName
        category.type = type
        category.icon = selectedIcon

        dismiss()

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
