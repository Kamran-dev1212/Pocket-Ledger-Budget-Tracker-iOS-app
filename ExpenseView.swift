import SwiftUI
import SwiftData

struct ExpenseView: View {

    @Environment(\.modelContext) private var modelContext

    @State private var showAddExpense = false
    @State private var selectedTransaction: Transaction?
    @State private var searchText = ""

    // Staggered entrance animation flags (same pattern as Dashboard)
    @State private var showHero = false
    @State private var showSearch = false

    @AppStorage("selectedCurrency") private var currency: String = "PKR"

    @Query(sort: \Transaction.date, order: .reverse)
    private var transactions: [Transaction]

    // MARK: - Same filtering logic as before, unchanged

    var expenseTransactions: [Transaction] {
        transactions.filter { $0.type == "Expense" }
    }

    var totalExpense: Double {
        expenseTransactions.reduce(0) { $0 + $1.amount }
    }

    // MARK: - New: search filtering (same pattern as Dashboard's search)

    private var filteredTransactions: [Transaction] {

        guard !searchText.isEmpty else {
            return expenseTransactions
        }

        return expenseTransactions.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.category.localizedCaseInsensitiveContains(searchText)
        }

    }

    var body: some View {

        List {

            // MARK: Header + Hero + Search (scrolls together, single row)

            Section {

                VStack(spacing: AppColors.sectionSpacing) {

                    TransactionTypeHeaderView(
                        title: "Expense",
                        subtitle: "Track your spending"
                    )

                    TransactionHeroCardView(
                        label: "Total Expense",
                        amount: totalExpense,
                        transactionCount: expenseTransactions.count,
                        gradientColors: AppColors.expenseGradient,
                        icon: "arrow.up.circle.fill"
                    )
                    .opacity(showHero ? 1 : 0)
                    .offset(y: showHero ? 0 : 8)

                    SearchBarView(text: $searchText, placeholder: "Search expenses...")
                        .opacity(showSearch ? 1 : 0)
                        .offset(y: showSearch ? 0 : 8)

                }
                .padding(.top, 8)
                .padding(.bottom, 4)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

            }

            // MARK: Transaction List / Empty States

            Section {

                if expenseTransactions.isEmpty {

                    // MARK: True empty state (no expenses recorded at all)

                    DashboardEmptyStateView(
                        icon: "arrow.up.circle.fill",
                        title: "No Expenses Yet",
                        message: "Start adding your expenses to see them appear here.",
                        buttonTitle: "Add Expense",
                        tintColor: AppColors.expense
                    ) {
                        showAddExpense = true
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: AppColors.pageHorizontalPadding, bottom: 0, trailing: AppColors.pageHorizontalPadding))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                } else if filteredTransactions.isEmpty {

                    // MARK: No search results

                    Text("No matching expenses found")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)

                } else {

                    // MARK: Premium transaction cards

                    ForEach(filteredTransactions) { transaction in

                        TransactionRowView(
                            icon: TransactionIcon.icon(
                                for: transaction.category,
                                type: transaction.type
                            ),
                            title: transaction.title,
                            category: transaction.category,
                            date: formattedDate(transaction.date),
                            amount: "-\(CurrencyManager.symbol(for: currency))\(Int(transaction.amount).formatted())",
                            amountColor: AppColors.expense
                        )
                        .listRowInsets(
                            EdgeInsets(
                                top: 0,
                                leading: AppColors.pageHorizontalPadding,
                                bottom: 12,
                                trailing: AppColors.pageHorizontalPadding
                            )
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .leading) {

                            // MARK: Edit — same logic as before (opens AddTransactionView via sheet(item:))

                            Button {

                                selectedTransaction = transaction

                            } label: {

                                Label("Edit", systemImage: "pencil")

                            }
                            .tint(AppColors.primary)

                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {

                            // MARK: Delete — same logic as before (modelContext.delete)

                            Button(role: .destructive) {

                                withAnimation {
                                    modelContext.delete(transaction)
                                }

                            } label: {

                                Label("Delete", systemImage: "trash")

                            }

                        }

                    }

                }

            }

        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppColors.background)
        .animation(.easeInOut(duration: 0.2), value: searchText)
        .navigationTitle("Expenses")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {

            ToolbarItem(placement: .topBarTrailing) {

                Button {

                    showAddExpense = true

                } label: {

                    Image(systemName: "plus")

                }

            }

        }
        .sheet(isPresented: $showAddExpense) {

            AddTransactionView(
                transaction: nil,
                defaultType: "Expense"
            )

        }
        .sheet(item: $selectedTransaction) { transaction in

            AddTransactionView(transaction: transaction)

        }
        .onAppear {

            withAnimation(.easeOut(duration: 0.35)) {
                showHero = true
            }

            withAnimation(.easeOut(duration: 0.35).delay(0.1)) {
                showSearch = true
            }

        }

    }

    // MARK: - Helper (same date-formatting pattern used on the Dashboard)

    private func formattedDate(_ date: Date) -> String {

        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"

        return formatter.string(from: date)

    }

}

#Preview {
    NavigationStack {
        ExpenseView()
    }
}
