import SwiftUI

struct GroupDetailView: View {

    let group: SharedGroup

    @State private var expenses: [SharedExpense] = []
    @State private var isLoading = false
    @State private var showAddExpense = false
    @State private var errorMessage = ""
    @State private var showError = false

    @AppStorage("selectedCurrency") private var currency: String = "PKR"

    private var total: Double {

        expenses.reduce(0) { $0 + $1.amount }

    }

    var body: some View {

        ZStack {

            AppColors.background
                .ignoresSafeArea()

            if isLoading {

                ProgressView()

            } else if expenses.isEmpty {

                VStack(spacing: 16) {

                    Image(systemName: "receipt")
                        .font(.system(size: 48))
                        .foregroundStyle(AppColors.primary)

                    Text("No Expenses Yet")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(AppColors.textPrimary)

                    Text("Add the first expense for this group.")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textSecondary)

                }

            } else {

                List {

                    Section {

                        HStack {

                            Text("Total")
                                .font(.headline)

                            Spacer()

                            Text(
                                CurrencyManager.string(
                                    for: total,
                                    currencyCode: currency
                                )
                            )
                            .font(.headline)
                            .fontWeight(.bold)

                        }

                    }

                    Section("Expenses") {

                        ForEach(expenses) { expense in

                            VStack(alignment: .leading, spacing: 4) {

                                HStack {

                                    Text(expense.title)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(AppColors.textPrimary)

                                    Spacer()

                                    Text(
                                        CurrencyManager.string(
                                            for: expense.amount,
                                            currencyCode: currency
                                        )
                                    )
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(AppColors.textPrimary)

                                }

                                Text("Paid by \(expense.paidByDisplayName) · split \(expense.splitAmongUserRecordIDs.count) ways")
                                    .font(.caption)
                                    .foregroundStyle(AppColors.textSecondary)

                            }
                            .padding(.vertical, 4)

                        }

                    }

                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)

            }

        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {

            ToolbarItem(placement: .topBarTrailing) {

                Button {
                    showAddExpense = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Expense")

            }

        }
        .sheet(isPresented: $showAddExpense) {

            AddSharedExpenseView(group: group) {

                Task {
                    await loadExpenses()
                }

            }

        }
        .task {
            await loadExpenses()
        }
        .alert("Error", isPresented: $showError) {

            Button("OK", role: .cancel) { }

        } message: {

            Text(errorMessage)

        }

    }

    private func loadExpenses() async {

        isLoading = true

        do {

            expenses = try await GroupSharingManager.shared.fetchExpenses(for: group)

        } catch {

            errorMessage = error.localizedDescription
            showError = true

        }

        isLoading = false

    }

}
