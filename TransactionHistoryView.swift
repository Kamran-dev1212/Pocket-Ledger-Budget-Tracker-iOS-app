import SwiftUI
import SwiftData

struct TransactionHistoryView: View {

    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Transaction.date, order: .reverse)
    private var transactions: [Transaction]

    @State private var searchText = ""
    @State private var selectedFilter = "All"
    @State private var selectedSort = "Newest"
    @State private var detailTransaction: Transaction?

    @AppStorage("selectedCurrency") private var currency: String = "PKR"

    // MARK: Statistics

    var totalIncome: Double {
        transactions
            .filter { $0.type == "Income" }
            .reduce(0) { $0 + $1.amount }
    }

    var totalExpense: Double {
        transactions
            .filter { $0.type == "Expense" }
            .reduce(0) { $0 + $1.amount }
    }

    // MARK: Filter + Sort

    var filteredTransactions: [Transaction] {

        var filtered = transactions

        // Search

        if !searchText.isEmpty {

            filtered = filtered.filter {

                $0.title.localizedCaseInsensitiveContains(searchText)

                ||

                $0.category.localizedCaseInsensitiveContains(searchText)

            }

        }

        // Filter

        switch selectedFilter {

        case "Income":
            filtered = filtered.filter { $0.type == "Income" }

        case "Expense":
            filtered = filtered.filter { $0.type == "Expense" }

        default:
            break

        }

        // Sort

        switch selectedSort {

        case "Oldest":
            filtered.sort { $0.date < $1.date }

        case "Highest":
            filtered.sort { $0.amount > $1.amount }

        case "Lowest":
            filtered.sort { $0.amount < $1.amount }

        default:
            filtered.sort { $0.date > $1.date }

        }

        return filtered

    }

    // MARK: Date Grouping

    private struct TransactionGroup: Identifiable {
        let id = UUID()
        let label: String
        let transactions: [Transaction]
    }

    private var groupedTransactions: [TransactionGroup] {

        let calendar = Calendar.current

        func label(for date: Date) -> String {

            if calendar.isDateInToday(date) {
                return "Today"
            } else if calendar.isDateInYesterday(date) {
                return "Yesterday"
            } else {
                return formatter.string(from: date)
            }

        }

        let buckets = Dictionary(grouping: filteredTransactions) { label(for: $0.date) }

        var orderedLabels: [String] = []

        for transaction in filteredTransactions {

            let key = label(for: transaction.date)

            if !orderedLabels.contains(key) {
                orderedLabels.append(key)
            }

        }

        return orderedLabels.map { key in
            TransactionGroup(label: key, transactions: buckets[key] ?? [])
        }

    }

    // MARK: Date Formatter

    private let formatter: DateFormatter = {

        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"

        return formatter

    }()

    var body: some View {

        ZStack {

            AppColors.background
                .ignoresSafeArea()

            List {

                Group {

                    VStack(spacing: 22) {

                        statisticsCard
                        searchBar
                        filterSortRow

                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 4)

                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

                if transactions.isEmpty {

                    noTransactionsEmptyState
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)

                } else if filteredTransactions.isEmpty {

                    noMatchingResultsEmptyState
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)

                } else {

                    ForEach(groupedTransactions) { group in

                        Section {

                            ForEach(group.transactions) { transaction in

                                TransactionRowView(

                                    icon: TransactionIcon.icon(
                                        for: transaction.category,
                                        type: transaction.type
                                    ),

                                    title: transaction.title,

                                    date: "\(transaction.category) • \(formatter.string(from: transaction.date))",

                                    amount: "\(transaction.type == "Income" ? "+" : "-")\(CurrencyManager.symbol(for: currency))\(Int(transaction.amount).formatted())",

                                    amountColor: transaction.type == "Income"
                                    ? AppColors.success
                                    : AppColors.expense

                                )
                                .contentShape(Rectangle())
                                .onTapGesture {

                                    detailTransaction = transaction

                                }
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {

                                    Button(role: .destructive) {
                                        delete(transaction)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }

                                }

                            }

                        } header: {

                            Text(group.label)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppColors.textSecondary)
                                .textCase(nil)

                        }

                    }

                }

            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)

        }
        .navigationTitle("All Transactions")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $detailTransaction) { transaction in

            TransactionDetailView(transaction: transaction)

        }

    }

    // MARK: Delete

    private func delete(_ transaction: Transaction) {

        modelContext.delete(transaction)

        try? modelContext.save()

    }

    // MARK: Statistics Card

    @ViewBuilder
    private var statisticsCard: some View {

        VStack(spacing: 18) {

            HStack {

                VStack(alignment: .leading) {

                    Text("\(transactions.count)")
                        .font(.system(size: 34, weight: .bold))

                    Text("Transactions")
                        .foregroundStyle(AppColors.textSecondary)

                }

                Spacer()

            }

            Divider()

            HStack {

                VStack(alignment: .leading, spacing: 6) {

                    Text("Income")
                        .foregroundStyle(AppColors.textSecondary)

                    Text("\(CurrencyManager.symbol(for: currency))\(Int(totalIncome).formatted())")
                        .fontWeight(.bold)
                        .foregroundStyle(AppColors.success)

                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {

                    Text("Expense")
                        .foregroundStyle(AppColors.textSecondary)

                    Text("\(CurrencyManager.symbol(for: currency))\(Int(totalExpense).formatted())")
                        .fontWeight(.bold)
                        .foregroundStyle(AppColors.expense)

                }

            }

        }
        .padding(20)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: AppColors.shadow,
                radius: 8,
                x: 0,
                y: 5)

    }

    // MARK: Search Bar

    @ViewBuilder
    private var searchBar: some View {

        HStack {

            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppColors.textSecondary)

            TextField("Search transactions...", text: $searchText)

            if !searchText.isEmpty {

                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppColors.textSecondary)
                }

            }

        }
        .padding(14)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))

    }

    // MARK: Filter + Sort Row

    @ViewBuilder
    private var filterSortRow: some View {

        HStack {

            ScrollView(.horizontal, showsIndicators: false) {

                HStack(spacing: 12) {

                    filterChip(title: "All")

                    filterChip(title: "Income")

                    filterChip(title: "Expense")

                }

            }

            Menu {

                Button("Newest") {

                    selectedSort = "Newest"

                }

                Button("Oldest") {

                    selectedSort = "Oldest"

                }

                Button("Highest Amount") {

                    selectedSort = "Highest"

                }

                Button("Lowest Amount") {

                    selectedSort = "Lowest"

                }

            } label: {

                HStack {

                    Image(systemName: "arrow.up.arrow.down")

                    Text(selectedSort)

                }
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(AppColors.card)
                .clipShape(Capsule())

            }

        }

    }

    // MARK: Empty States

    @ViewBuilder
    private var noTransactionsEmptyState: some View {

        VStack(spacing: 20) {

            ZStack {

                Circle()
                    .fill(AppColors.primary.opacity(0.12))
                    .frame(width: 120, height: 120)

                Image(systemName: "tray.fill")
                    .font(.system(size: 54, weight: .semibold))
                    .foregroundStyle(AppColors.primary)

            }

            Text("No Transactions Yet")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(AppColors.textPrimary)

            Text("Add your first income or expense to see it here.")
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)

    }

    @ViewBuilder
    private var noMatchingResultsEmptyState: some View {

        VStack(spacing: 16) {

            ZStack {

                Circle()
                    .fill(AppColors.primary.opacity(0.12))
                    .frame(width: 100, height: 100)

                Image(systemName: "magnifyingglass")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(AppColors.primary)

            }

            Text("No Matching Transactions")
                .font(.headline)
                .foregroundStyle(AppColors.textPrimary)

            Text("Try another search or filter.")
                .foregroundStyle(AppColors.textSecondary)

        }
        .frame(maxWidth: .infinity)
        .padding(.top, 50)

    }

    // MARK: Filter Chip

    @ViewBuilder

    func filterChip(title: String) -> some View {

        Button {

            withAnimation(.easeInOut) {

                selectedFilter = title

            }

        } label: {

            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(
                    selectedFilter == title
                    ? .white
                    : AppColors.textPrimary
                )
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    selectedFilter == title
                    ? AppColors.primary
                    : AppColors.card
                )
                .clipShape(Capsule())

        }

    }

}

#Preview {

    NavigationStack {

        TransactionHistoryView()

    }

}
