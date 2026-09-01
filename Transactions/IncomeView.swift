import SwiftUI
import SwiftData

struct IncomeView: View {

    @Environment(\.modelContext) private var modelContext

    @State private var showAddIncome = false
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

    var incomeTransactions: [Transaction] {
        transactions.filter { $0.type == "Income" }
    }

    var totalIncome: Double {
        incomeTransactions.reduce(0) { $0 + $1.amount }
    }

    private var filteredTransactions: [Transaction] {

        guard !searchText.isEmpty else {
            return incomeTransactions
        }

        return incomeTransactions.filter {
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
                        title: "Income",
                        subtitle: "Track your earnings"
                    )

                    TransactionHeroCardView(
                        label: "Total Income",
                        amount: totalIncome,
                        transactionCount: incomeTransactions.count,
                        gradientColors: AppColors.incomeGradient,
                        icon: "arrow.down.circle.fill"
                    )
                    .opacity(showHero ? 1 : 0)
                    .offset(y: showHero ? 0 : 8)

                    SearchBarView(text: $searchText, placeholder: "Search income...")
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

                if incomeTransactions.isEmpty {

                    // MARK: True empty state (no income recorded at all)

                    DashboardEmptyStateView(
                        icon: "arrow.down.circle.fill",
                        title: "No Income Yet",
                        message: "Start adding your income to see it appear here.",
                        buttonTitle: "Add Income",
                        tintColor: AppColors.success
                    ) {
                        showAddIncome = true
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

                    Text("No matching income found")
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
                                forcedSign: "+"
                            ),
                            amountColor: AppColors.success
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
        .navigationTitle("Income")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {

            ToolbarItem(placement: .topBarTrailing) {

                Button {

                    showAddIncome = true

                } label: {

                    Image(systemName: "plus")

                }
                .accessibilityLabel("Add income")

            }

        }
        .sheet(isPresented: $showAddIncome) {

            AddTransactionView(
                transaction: nil,
                defaultType: "Income"
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

        IncomeView()

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
