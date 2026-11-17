
import SwiftUI
import SwiftData

struct TransactionHistoryView: View {

    // MARK: - Environment

    @Environment(\.modelContext)
    private var modelContext

    @Environment(\.dismiss)
    private var dismiss

    // MARK: - Data

    @Query(sort: \Transaction.date, order: .reverse)
    private var transactions: [Transaction]

    @Query
    private var userCategories: [UserCategory]

    @AppStorage("selectedCurrency")
    private var currency: String = "USD"

    // MARK: - State

    @State private var searchText = ""
    @State private var selectedFilter = "All"
    @State private var selectedSort = "Newest"
    @State private var selectedArchiveTab = "Active"

    @State private var selectedPeriod = HistoryPeriod.monthly
    @State private var referenceDate = Date()

    @State private var detailTransaction: Transaction?

    // MARK: - Period

    private enum HistoryPeriod: String, CaseIterable, Identifiable {
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"

        var id: String { rawValue }

        var calendarComponent: Calendar.Component {
            switch self {
            case .daily: return .day
            case .weekly: return .weekOfYear
            case .monthly: return .month
            }
        }
    }

    private var periodInterval: DateInterval {
        let calendar = Calendar.current

        return calendar.dateInterval(
            of: selectedPeriod.calendarComponent,
            for: referenceDate
        ) ?? DateInterval(
            start: calendar.startOfDay(for: referenceDate),
            duration: 86_400
        )
    }

    private var periodTitle: String {
        let calendar = Calendar.current

        switch selectedPeriod {

        case .daily:
            return referenceDate.formatted(
                .dateTime.day().month(.wide).year()
            )

        case .weekly:
            let start = periodInterval.start

            let lastDay = calendar.date(
                byAdding: .day,
                value: -1,
                to: periodInterval.end
            ) ?? start

            return "\(start.formatted(.dateTime.day().month(.abbreviated))) – \(lastDay.formatted(.dateTime.day().month(.abbreviated).year()))"

        case .monthly:
            return referenceDate.formatted(
                .dateTime.month(.wide).year()
            )
        }
    }

    private var isCurrentPeriod: Bool {
        periodInterval.contains(Date())
    }

    private func changePeriod(by value: Int) {
        let calendar = Calendar.current

        guard let newDate = calendar.date(
            byAdding: selectedPeriod.calendarComponent,
            value: value,
            to: referenceDate
        ) else {
            return
        }

        referenceDate = newDate
    }

    // MARK: - Transaction Selection

    private var transactionsForCurrentTab: [Transaction] {
        transactions.filter { transaction in
            selectedArchiveTab == "Active"
                ? !transaction.isArchived
                : transaction.isArchived
        }
    }

    private var transactionsForSelectedPeriod: [Transaction] {
        let interval = periodInterval

        return transactionsForCurrentTab.filter { transaction in
            transaction.date >= interval.start &&
            transaction.date < interval.end
        }
    }

    // MARK: - Statistics

    private var totalIncome: Double {
        transactionsForSelectedPeriod
            .filter { $0.type == "Income" }
            .reduce(0) { $0 + $1.amount }
    }

    private var totalExpense: Double {
        transactionsForSelectedPeriod
            .filter { $0.type == "Expense" }
            .reduce(0) { $0 + $1.amount }
    }

    // MARK: - Search, Filter, Sort

    private var filteredTransactions: [Transaction] {

        var filtered = transactionsForSelectedPeriod

        let query = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if !query.isEmpty {
            filtered = filtered.filter {
                $0.title.localizedCaseInsensitiveContains(query) ||
                $0.category.localizedCaseInsensitiveContains(query)
            }
        }

        switch selectedFilter {

        case "Income":
            filtered = filtered.filter {
                $0.type == "Income"
            }

        case "Expense":
            filtered = filtered.filter {
                $0.type == "Expense"
            }

        default:
            break
        }

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

    // MARK: - Grouping

    private struct TransactionGroup: Identifiable {
        let date: Date
        let transactions: [Transaction]

        var id: Date { date }
    }

    private var groupedTransactions: [TransactionGroup] {

        let calendar = Calendar.current

        let buckets = Dictionary(
            grouping: filteredTransactions
        ) { transaction in
            calendar.startOfDay(for: transaction.date)
        }

        let dates = buckets.keys.sorted {
            selectedSort == "Oldest" ? $0 < $1 : $0 > $1
        }

        return dates.map { date in
            TransactionGroup(
                date: date,
                transactions: buckets[date] ?? []
            )
        }
    }

    private func groupTitle(for date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today"
        }

        if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }

        return date.formatted(
            .dateTime.day().month(.abbreviated).year()
        )
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

                        VStack(spacing: 18) {

                            archiveTabPicker

                            periodFilterCard

                            statisticsCard

                            searchBar

                            filterSortRow
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 24)
                        .padding(.bottom, 12)

                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())

                    if transactionsForSelectedPeriod.isEmpty {

                        emptyState(
                            title: "No Transactions",
                            message: "No \(selectedArchiveTab.lowercased()) transactions found for this \(selectedPeriod.rawValue.lowercased()) period.",
                            icon: "tray.fill"
                        )
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)

                    } else if filteredTransactions.isEmpty {

                        emptyState(
                            title: "No Matching Transactions",
                            message: "Try another search or transaction type.",
                            icon: "magnifyingglass"
                        )
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)

                    } else {

                        ForEach(groupedTransactions) { group in

                            Section {

                                ForEach(group.transactions) { transaction in

                                    TransactionRowView(
                                        icon: TransactionIcon.icon(
                                            for: transaction.category,
                                            type: transaction.type,
                                            in: userCategories
                                        ),
                                        title: transaction.title,
                                        date: "\(transaction.category) • \(transaction.date.formatted(.dateTime.day().month(.abbreviated).year()))",
                                        amount: "\(transaction.type == "Income" ? "+" : "-")\(CurrencyManager.symbol(for: currency))\(CurrencyManager.number(for: transaction.amount))",
                                        amountColor: transaction.type == "Income"
                                            ? AppColors.success
                                            : AppColors.expense
                                    )
                                    .padding(12)
                                    .background(
                                        AppColors.card,
                                        in: RoundedRectangle(cornerRadius: 18)
                                    )
                                    .contentShape(
                                        RoundedRectangle(cornerRadius: 18)
                                    )
                                    .onTapGesture {
                                        detailTransaction = transaction
                                    }
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .listRowInsets(
                                        EdgeInsets(
                                            top: 5,
                                            leading: 18,
                                            bottom: 5,
                                            trailing: 18
                                        )
                                    )
                                    .swipeActions(
                                        edge: .trailing,
                                        allowsFullSwipe: true
                                    ) {
                                        Button(role: .destructive) {
                                            delete(transaction)
                                        } label: {
                                            Label(
                                                "Delete",
                                                systemImage: "trash"
                                            )
                                        }
                                    }
                                }

                            } header: {

                                Text(groupTitle(for: group.date))
                                    .font(.system(
                                        size: 14,
                                        weight: .semibold
                                    ))
                                    .foregroundStyle(
                                        AppColors.textSecondary
                                    )
                                    .textCase(nil)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .scrollIndicators(.hidden)
                .background {
                    UnevenRoundedRectangle(
                        topLeadingRadius: 28,
                        topTrailingRadius: 28
                    )
                    .fill(AppColors.dashboardSurface)
                    .ignoresSafeArea(edges: .bottom)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $detailTransaction) { transaction in
            TransactionDetailView(transaction: transaction)
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
                        Text("Back")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                }

                Spacer()

                Text("All Transactions")
                    .font(.system(
                        size: 17,
                        weight: .semibold
                    ))
                    .foregroundStyle(.white)

                Spacer()

                Text("Back")
                    .hidden()
            }

            VStack(alignment: .leading, spacing: 8) {

                Text("Transaction History")
                    .font(.system(
                        size: 27,
                        weight: .bold
                    ))
                    .foregroundStyle(.white)

                Text("Explore your financial activity")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 14)
        .padding(.bottom, 28)
    }

    // MARK: - Active / Archived

    private var archiveTabPicker: some View {

        Picker("View", selection: $selectedArchiveTab) {

            Text("Active").tag("Active")

            Text("Archived").tag("Archived")
        }
        .pickerStyle(.segmented)
        .tint(AppColors.dashboardPurple)
    }

    // MARK: - Period Filter

    private var periodFilterCard: some View {

        VStack(spacing: 16) {

            HStack {

                Image(systemName: "calendar")
                    .foregroundStyle(
                        AppColors.dashboardPurple
                    )

                Text("History Period")
                    .font(.system(
                        size: 16,
                        weight: .semibold
                    ))
                    .foregroundStyle(
                        AppColors.textPrimary
                    )

                Spacer()

                Button("Today") {
                    referenceDate = Date()
                }
                .font(.system(
                    size: 13,
                    weight: .semibold
                ))
                .foregroundStyle(
                    AppColors.dashboardPurple
                )
            }

            Picker(
                "History Period",
                selection: $selectedPeriod
            ) {

                ForEach(HistoryPeriod.allCases) { period in
                    Text(period.rawValue)
                        .tag(period)
                }
            }
            .pickerStyle(.segmented)
            .tint(AppColors.dashboardPurple)

            HStack(spacing: 12) {

                Button {
                    changePeriod(by: -1)
                } label: {

                    Image(systemName: "chevron.left")
                        .font(.system(
                            size: 15,
                            weight: .semibold
                        ))
                        .frame(
                            width: 40,
                            height: 40
                        )
                        .background(
                            AppColors.dashboardPurple.opacity(0.10),
                            in: RoundedRectangle(
                                cornerRadius: 12
                            )
                        )
                }
                .accessibilityLabel("Previous period")

                Spacer(minLength: 4)

                Text(periodTitle)
                    .font(.system(
                        size: 15,
                        weight: .semibold
                    ))
                    .foregroundStyle(
                        AppColors.textPrimary
                    )
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 4)

                Button {
                    changePeriod(by: 1)
                } label: {

                    Image(systemName: "chevron.right")
                        .font(.system(
                            size: 15,
                            weight: .semibold
                        ))
                        .frame(
                            width: 40,
                            height: 40
                        )
                        .background(
                            AppColors.dashboardPurple.opacity(0.10),
                            in: RoundedRectangle(
                                cornerRadius: 12
                            )
                        )
                }
                .accessibilityLabel("Next period")
                .disabled(isCurrentPeriod)
                .opacity(isCurrentPeriod ? 0.35 : 1)
            }
            .foregroundStyle(
                AppColors.dashboardPurple
            )
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(
            AppColors.card,
            in: RoundedRectangle(cornerRadius: 20)
        )
    }

    // MARK: - Statistics

    private var statisticsCard: some View {

        VStack(alignment: .leading, spacing: 18) {

            HStack {

                VStack(alignment: .leading, spacing: 6) {

                    Text("\(transactionsForSelectedPeriod.count)")
                        .font(.system(
                            size: 34,
                            weight: .bold
                        ))
                        .foregroundStyle(
                            AppColors.textPrimary
                        )

                    Text("Transactions")
                        .font(.system(size: 13))
                        .foregroundStyle(
                            AppColors.textSecondary
                        )
                }

                Spacer()

                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 22))
                    .foregroundStyle(
                        AppColors.dashboardPurple
                    )
                    .frame(width: 48, height: 48)
                    .background(
                        AppColors.dashboardPurple.opacity(0.10),
                        in: RoundedRectangle(cornerRadius: 14)
                    )
            }

            Divider()

            HStack(alignment: .top) {

                VStack(alignment: .leading, spacing: 7) {

                    Text("Income")
                        .font(.system(size: 13))
                        .foregroundStyle(
                            AppColors.textSecondary
                        )

                    Text(
                        "\(CurrencyManager.symbol(for: currency))\(CurrencyManager.number(for: totalIncome))"
                    )
                    .font(.system(
                        size: 17,
                        weight: .bold
                    ))
                    .foregroundStyle(
                        AppColors.success
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                }

                Spacer(minLength: 12)

                VStack(alignment: .trailing, spacing: 7) {

                    Text("Expense")
                        .font(.system(size: 13))
                        .foregroundStyle(
                            AppColors.textSecondary
                        )

                    Text(
                        "\(CurrencyManager.symbol(for: currency))\(CurrencyManager.number(for: totalExpense))"
                    )
                    .font(.system(
                        size: 17,
                        weight: .bold
                    ))
                    .foregroundStyle(
                        AppColors.expense
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                }
            }
        }
        .padding(20)
        .background(
            AppColors.card,
            in: RoundedRectangle(cornerRadius: 22)
        )
    }

    // MARK: - Search

    private var searchBar: some View {

        HStack(spacing: 12) {

            Image(systemName: "magnifyingglass")
                .foregroundStyle(
                    AppColors.textSecondary
                )

            TextField(
                "Search transactions...",
                text: $searchText
            )
            .font(.system(size: 15))
            .foregroundStyle(
                AppColors.textPrimary
            )
            .autocorrectionDisabled()

            if !searchText.isEmpty {

                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(
                            AppColors.textSecondary
                        )
                }
            }
        }
        .padding(15)
        .background(
            AppColors.card,
            in: RoundedRectangle(cornerRadius: 16)
        )
    }

    // MARK: - Income / Expense and Sort

    private var filterSortRow: some View {

        HStack(spacing: 10) {

            ScrollView(
                .horizontal,
                showsIndicators: false
            ) {

                HStack(spacing: 9) {
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

                HStack(spacing: 5) {

                    Image(systemName: "arrow.up.arrow.down")

                    Text(selectedSort)
                }
                .font(.system(
                    size: 13,
                    weight: .medium
                ))
                .foregroundStyle(
                    AppColors.textPrimary
                )
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background(
                    AppColors.card,
                    in: Capsule()
                )
            }
        }
    }

    private func filterChip(title: String) -> some View {

        Button {

            withAnimation(.easeInOut) {
                selectedFilter = title
            }

        } label: {

            Text(title)
                .font(.system(
                    size: 13,
                    weight: .semibold
                ))
                .foregroundStyle(
                    selectedFilter == title
                        ? Color.white
                        : AppColors.textPrimary
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(
                    selectedFilter == title
                        ? AppColors.dashboardPurple
                        : AppColors.card,
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    private func emptyState(
        title: String,
        message: String,
        icon: String
    ) -> some View {

        VStack(spacing: 16) {

            Image(systemName: icon)
                .font(.system(size: 38))
                .foregroundStyle(
                    AppColors.dashboardPurple
                )
                .frame(width: 90, height: 90)
                .background(
                    AppColors.dashboardPurple.opacity(0.10),
                    in: Circle()
                )

            Text(title)
                .font(.system(
                    size: 19,
                    weight: .semibold
                ))
                .foregroundStyle(
                    AppColors.textPrimary
                )

            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(
                    AppColors.textSecondary
                )
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 18)
        .padding(.top, 45)
        .padding(.bottom, 30)
    }

    // MARK: - Delete

    private func delete(_ transaction: Transaction) {

        modelContext.delete(transaction)

        SaveReporter.shared.save(
            modelContext,
            failureMessage: "That transaction couldn't be deleted."
        )
    }
}

// MARK: - Preview

#Preview {

    NavigationStack {
        TransactionHistoryView()
    }
}
