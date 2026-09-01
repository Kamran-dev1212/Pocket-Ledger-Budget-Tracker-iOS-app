import SwiftUI
import SwiftData

struct ExpenseView: View {

    @Environment(\.modelContext) private var modelContext

    @State private var showAddExpense = false
    @State private var detailTransaction: Transaction?
    @State private var searchText = ""

    // Staggered entrance animation flags (same pattern as Dashboard)
    @State private var showHero = false
    @State private var showSearch = false

    @AppStorage("selectedCurrency") private var currency: String = "PKR"

    @Query(sort: \Transaction.date, order: .reverse)
    private var transactions: [Transaction]

    // MARK: - Shared Formatter
    //
    // Was allocated fresh inside formattedDate(_:) on every row,
    // every render. DateFormatter creation is expensive.

    private static let rowDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter
    }()

    // MARK: - Filtering

    var expenseTransactions: [Transaction] {
        transactions.filter { $0.type == "Expense" }
    }

    var totalExpense: Double {
        expenseTransactions.reduce(0) { $0 + $1.amount }
    }

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
                        title: "Expenses",
                        subtitle: "Track your spending"
                    )

                    TransactionHeroCardView(
                        label: "Total Expenses",
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
                .padding(.horizontal, AppColors.pageHorizontalPadding)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

            }

            // MARK: Transaction List / Empty States

            Section {

                if expenseTransactions.isEmpty {

                    // MARK: True empty state (no expense recorded at all)

                    DashboardEmptyStateView(
                        icon: "arrow.up.circle.fill",
                        title: "No Expenses Yet",
                        message: "Start adding your expenses to see them appear here.",
                        buttonTitle: "Add Expense",
                        tintColor: AppColors.expense
                    ) {
                        showAddExpense = true
                    }
                    .listRowInsets(
                        EdgeInsets(
                            top: 0,
                            leading: AppColors.pageHorizontalPadding,
                            bottom: 0,
                            trailing: AppColors.pageHorizontalPadding
                        )
                    )
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
                            amount: CurrencyManager.string(
                                for: transaction.amount,
                                currencyCode: currency,
                                forcedSign: "-"
                            ),
                            amountColor: AppColors.expense
                        )
                        .contentShape(RoundedRectangle(cornerRadius: AppColors.cardCornerRadius))
                        .onTapGesture {

                            detailTransaction = transaction

                        }
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
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {

                            // MARK: Delete
                            //
                            // allowsFullSwipe was true, so a fast swipe
                            // deleted a record outright with no undo.
                            // Now the button must be tapped deliberately.

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
                .accessibilityLabel("Add expense")

            }

        }
        .sheet(isPresented: $showAddExpense) {

            AddTransactionView(
                transaction: nil,
                defaultType: "Expense"
            )

        }
        .sheet(item: $detailTransaction) { transaction in

            TransactionDetailView(transaction: transaction)

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

    // MARK: - Helper

    private func formattedDate(_ date: Date) -> String {

        Self.rowDateFormatter.string(from: date)

    }

}

#Preview {

    NavigationStack {

        ExpenseView()

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
