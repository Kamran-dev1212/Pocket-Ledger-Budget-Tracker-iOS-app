import SwiftUI
import SwiftData

private struct TransactionDayGroup: Identifiable {
    let id: Date
    let date: Date
    let transactions: [Transaction]
}

struct DashboardView: View {

    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Transaction.date, order: .reverse)
    private var transactions: [Transaction]

    @Query(sort: \Budget.category)
    private var budgets: [Budget]

    @State private var detailTransaction: Transaction?
    @State private var showAddTransaction = false
    @State private var showBudget = false
    @State private var showReports = false
    @State private var showProfile = false

    // Staggered entrance animation flags
    @State private var showBalance = false
    @State private var showSummary = false
    @State private var showTransactions = false

    @AppStorage("selectedCurrency") private var currency: String = "PKR"

    // MARK: - Recent Window

    private let recentTransactionLimit = 20

    // MARK: - Shared Formatters

    private static let dayLabelFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    private static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        return formatter
    }()

    // MARK: - Calculated Values (all-time totals)

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

    var totalBalance: Double {
        totalIncome - totalExpense
    }

    // MARK: - Recent transactions grouped by calendar day, newest first

    private var groupedTransactions: [TransactionDayGroup] {

        let calendar = Calendar.current

        let recent = Array(transactions.prefix(recentTransactionLimit))

        let buckets = Dictionary(grouping: recent) { transaction in
            calendar.startOfDay(for: transaction.date)
        }

        return buckets
            .map { key, value in
                TransactionDayGroup(
                    id: key,
                    date: key,
                    transactions: value.sorted { $0.date > $1.date }
                )
            }
            .sorted { $0.date > $1.date }

    }

    private var hasMoreThanRecentWindow: Bool {
        transactions.count > recentTransactionLimit
    }

    private var insights: FinancialInsights {
        InsightsEngine.generate(transactions: transactions, budgets: budgets)
    }

    var body: some View {

        ZStack {

            ZStack {

                AppColors.background

                LinearGradient(
                    colors: [
                        AppColors.primary.opacity(0.035),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

            }
            .ignoresSafeArea()

            ScrollView {

                LazyVStack(spacing: 16) {

                    // MARK: Header

                    HStack(alignment: .center) {

                        DashboardHeaderView {
                            showProfile = true
                        }

                        Spacer()

                        Menu {

                            Button {
                                showBudget = true
                            } label: {
                                Label("Budget", systemImage: "wallet.pass")
                            }

                            Button {
                                showReports = true
                            } label: {
                                Label("Reports", systemImage: "doc.text")
                            }

                        } label: {

                            Image(systemName: "ellipsis")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(AppColors.textSecondary)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())

                        }
                        .accessibilityLabel("More")

                    }

                    // MARK: Balance Card

                    BalanceCardView(balance: totalBalance)
                        .opacity(showBalance ? 1 : 0)
                        .offset(y: showBalance ? 0 : 8)

                    // MARK: Income & Expense Cards

                    HStack(spacing: 16) {

                        NavigationLink {

                            IncomeView()

                        } label: {

                            SummaryCardView(
                                title: "Income",
                                amount: CurrencyManager.string(
                                    for: totalIncome,
                                    currencyCode: currency
                                ),
                                color: AppColors.success,
                                icon: "arrow.down.circle.fill",
                                backgroundTint: AppColors.successBackground
                            )

                        }
                        .buttonStyle(.plain)

                        NavigationLink {

                            ExpenseView()

                        } label: {

                            SummaryCardView(
                                title: "Expenses",
                                amount: CurrencyManager.string(
                                    for: totalExpense,
                                    currencyCode: currency
                                ),
                                color: AppColors.expense,
                                icon: "arrow.up.circle.fill",
                                backgroundTint: AppColors.expenseBackground
                            )

                        }
                        .buttonStyle(.plain)

                    }
                    .opacity(showSummary ? 1 : 0)
                    .offset(y: showSummary ? 0 : 8)

                    // MARK: Recent Transactions Timeline

                    VStack(alignment: .leading, spacing: 20) {

                        HStack {

                            Text("Recent Transactions")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppColors.textPrimary)

                            Spacer()

                            NavigationLink {

                                TransactionHistoryView()

                            } label: {

                                Text("See All")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(AppColors.primary)

                            }

                        }

                        if transactions.isEmpty {

                            DashboardEmptyStateView {

                                showAddTransaction = true

                            }

                        } else {

                            ForEach(groupedTransactions) { group in

                                VStack(alignment: .leading, spacing: 12) {

                                    HStack {

                                        Text(dayLabel(for: group.date))
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(AppColors.textPrimary)

                                        Spacer()

                                        let net = dayTotal(for: group.transactions)

                                        Text(
                                            CurrencyManager.signedString(
                                                for: net,
                                                currencyCode: currency
                                            )
                                        )
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .monospacedDigit()
                                        .foregroundStyle(
                                            net >= 0
                                                ? AppColors.success
                                                : AppColors.expense
                                        )

                                    }
                                    .padding(.horizontal, 4)

                                    dayCard(for: group.transactions)

                                }
                                .id(group.id)

                            }

                            // MARK: Link to full history

                            if hasMoreThanRecentWindow {

                                NavigationLink {

                                    TransactionHistoryView()

                                } label: {

                                    HStack(spacing: 6) {

                                        Text("View all \(transactions.count) transactions")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)

                                        Image(systemName: "arrow.right")
                                            .font(.caption)
                                            .fontWeight(.semibold)

                                    }
                                    .foregroundStyle(AppColors.primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(AppColors.card)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppColors.cardCornerRadius)
                                            .stroke(AppColors.border, lineWidth: 1)
                                    )
                                    .clipShape(
                                        RoundedRectangle(cornerRadius: AppColors.cardCornerRadius)
                                    )

                                }
                                .buttonStyle(.plain)

                            }

                        }

                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .opacity(showTransactions ? 1 : 0)
                    .offset(y: showTransactions ? 0 : 8)

                    // MARK: Financial Insights

                    VStack(alignment: .leading, spacing: 16) {

                        Text("Financial Insights")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(AppColors.textPrimary)

                        // A. Monthly Financial Health

                        InsightCardView(
                            icon: "heart.text.square.fill",
                            iconColor: insights.savingsHealth?.color ?? AppColors.textSecondary,
                            title: "Monthly Financial Health"
                        ) {

                            if let health = insights.savingsHealth {

                                HStack {

                                    Text("\(Int(health.rate))%")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundStyle(health.color)

                                    Spacer()

                                    Text(health.rating)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(health.color)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(health.color.opacity(0.12))
                                        .clipShape(Capsule())

                                }

                            } else {

                                InsightEmptyStateView(
                                    icon: "chart.line.uptrend.xyaxis",
                                    message: "Add income this month to see your savings rate."
                                )

                            }

                        }

                        // B. Biggest Expense Category

                        InsightCardView(
                            icon: "flame.fill",
                            iconColor: AppColors.expense,
                            title: "Biggest Expense Category"
                        ) {

                            if let biggest = insights.biggestExpense {

                                VStack(alignment: .leading, spacing: 6) {

                                    Text(biggest.category)
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundStyle(AppColors.textPrimary)

                                    HStack {

                                        Text(
                                            CurrencyManager.string(
                                                for: biggest.amount,
                                                currencyCode: currency
                                            )
                                        )
                                        .font(.subheadline)
                                        .foregroundStyle(AppColors.textSecondary)

                                        Spacer()

                                        Text("\(Int(biggest.percentage))% of expenses")
                                            .font(.caption)
                                            .foregroundStyle(AppColors.textSecondary)

                                    }

                                }

                            } else {

                                InsightEmptyStateView(
                                    icon: "tray",
                                    message: "No expenses recorded yet this month."
                                )

                            }

                        }

                        // C. Budget Performance

                        InsightCardView(
                            icon: "chart.pie.fill",
                            iconColor: AppColors.primary,
                            title: "Budget Performance"
                        ) {

                            if let performance = insights.budgetPerformance {

                                HStack(spacing: 20) {

                                    budgetStat(count: performance.onTrack, label: "On Track", color: AppColors.success)
                                    budgetStat(count: performance.nearLimit, label: "Near Limit", color: AppColors.warning)
                                    budgetStat(count: performance.exceeded, label: "Exceeded", color: AppColors.danger)

                                }

                            } else {

                                InsightEmptyStateView(
                                    icon: "wallet.pass",
                                    message: "Create a budget this month to track performance."
                                )

                            }

                        }

                        // D. Highest Expense Transaction

                        InsightCardView(
                            icon: "arrow.up.circle.fill",
                            iconColor: AppColors.danger,
                            title: "Highest Expense"
                        ) {

                            if let highest = insights.highestTransaction {

                                VStack(alignment: .leading, spacing: 6) {

                                    HStack {

                                        Text(highest.title)
                                            .font(.headline)
                                            .foregroundStyle(AppColors.textPrimary)
                                            .lineLimit(1)

                                        Spacer()

                                        Text(
                                            CurrencyManager.string(
                                                for: highest.amount,
                                                currencyCode: currency
                                            )
                                        )
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .monospacedDigit()
                                        .foregroundStyle(AppColors.expense)

                                    }

                                    HStack {

                                        Text(highest.category)
                                            .font(.caption)
                                            .foregroundStyle(AppColors.textSecondary)

                                        Spacer()

                                        Text(formattedDate(highest.date))
                                            .font(.caption)
                                            .foregroundStyle(AppColors.textSecondary)

                                    }

                                }

                            } else {

                                InsightEmptyStateView(
                                    icon: "tray",
                                    message: "No expenses recorded yet this month."
                                )

                            }

                        }

                        // E. Monthly Comparison

                        InsightCardView(
                            icon: "arrow.left.arrow.right.circle.fill",
                            iconColor: AppColors.accent,
                            title: "Monthly Comparison"
                        ) {

                            if let comparison = insights.monthlyComparison {

                                VStack(spacing: 10) {

                                    comparisonRow(label: "Income", change: comparison.incomeChange, higherIsBetter: true)
                                    comparisonRow(label: "Expenses", change: comparison.expenseChange, higherIsBetter: false)
                                    comparisonRow(label: "Savings", change: comparison.savingsChange, higherIsBetter: true)

                                }

                            } else {

                                InsightEmptyStateView(
                                    icon: "calendar",
                                    message: "Not enough data from last month to compare yet."
                                )

                            }

                        }

                        // F. Smart Tips

                        InsightCardView(
                            icon: "lightbulb.fill",
                            iconColor: AppColors.warning,
                            title: "Smart Tips"
                        ) {

                            VStack(alignment: .leading, spacing: 10) {

                                ForEach(insights.smartTips, id: \.self) { tip in

                                    HStack(alignment: .top, spacing: 8) {

                                        Image(systemName: "sparkle")
                                            .font(.caption)
                                            .foregroundStyle(AppColors.warning)

                                        Text(tip)
                                            .font(.subheadline)
                                            .foregroundStyle(AppColors.textPrimary)

                                    }

                                }

                            }

                        }

                    }

                    Spacer()
                        .frame(height: 16)

                }
                .padding(.horizontal, AppColors.pageHorizontalPadding)
                .padding(.top, 8)
                .padding(.bottom, 120)

            }

        }
        .navigationBarHidden(true)
        .overlay(alignment: .bottom) {

            Button {

                showAddTransaction = true

            } label: {

                ZStack {

                    Circle()
                        .fill(AppColors.primary)
                        .frame(width: 64, height: 64)
                        .shadow(color: AppColors.shadow, radius: 10, y: 6)

                    Image(systemName: "plus")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(AppColors.textOnPrimary)

                }

            }
            .accessibilityLabel("Add Transaction")
            .padding(.bottom, 16)

        }
        .sheet(item: $detailTransaction) { transaction in

            TransactionDetailView(transaction: transaction)

        }
        .sheet(isPresented: $showAddTransaction) {

            AddTransactionView(transaction: nil)

        }
        .sheet(isPresented: $showBudget) {

            BudgetView()

        }
        .sheet(isPresented: $showReports) {

            ReportsView()

        }
        .sheet(isPresented: $showProfile) {

            ProfileView()

        }
        .onAppear {

            withAnimation(.easeOut(duration: 0.35)) {
                showBalance = true
            }

            withAnimation(.easeOut(duration: 0.35).delay(0.1)) {
                showSummary = true
            }

            withAnimation(.easeOut(duration: 0.35).delay(0.2)) {
                showTransactions = true
            }

        }

    }

    // MARK: - Helper Views

    @ViewBuilder
    private func dayCard(for txns: [Transaction]) -> some View {

        VStack(spacing: 0) {

            ForEach(Array(txns.enumerated()), id: \.element.id) { index, transaction in

                SwipeToDeleteRow {

                    delete(transaction)

                } content: {

                    TransactionTimelineRowView(
                        icon: TransactionIcon.icon(
                            for: transaction.category,
                            type: transaction.type
                        ),
                        title: transaction.title,
                        category: transaction.category,
                        time: timeString(for: transaction.date),
                        amount: CurrencyManager.string(
                            for: transaction.amount,
                            currencyCode: currency,
                            forcedSign: transaction.type == "Income" ? "+" : "-"
                        ),
                        amountColor: transaction.type == "Income"
                            ? AppColors.success
                            : AppColors.expense
                    )
                    .padding(.horizontal, AppColors.cardPadding)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                    .onTapGesture {

                        detailTransaction = transaction

                    }

                }

                if index < txns.count - 1 {

                    Divider()
                        .overlay(AppColors.divider)
                        .padding(.leading, 58)

                }

            }

        }
        .background(AppColors.card)
        .overlay(
            RoundedRectangle(cornerRadius: AppColors.cardCornerRadius)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppColors.cardCornerRadius))
        .shadow(
            color: AppColors.shadow,
            radius: AppColors.cardShadowRadius,
            x: 0,
            y: AppColors.cardShadowY
        )

    }

    // MARK: - Delete

    private func delete(_ transaction: Transaction) {

        withAnimation {

            modelContext.delete(transaction)
            try? modelContext.save()

        }

    }

    @ViewBuilder
    private func budgetStat(count: Int, label: String, color: Color) -> some View {

        VStack(spacing: 4) {

            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)

            Text(label)
                .font(.caption2)
                .foregroundStyle(AppColors.textSecondary)

        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(count) \(label)")

    }

    @ViewBuilder
    private func comparisonRow(label: String, change: Double?, higherIsBetter: Bool) -> some View {

        HStack {

            Text(label)
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)

            Spacer()

            if let change {

                let isPositiveOutcome = higherIsBetter ? change >= 0 : change < 0

                HStack(spacing: 4) {

                    Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")

                    Text("\(abs(Int(change)))%")

                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(isPositiveOutcome ? AppColors.success : AppColors.danger)

            } else {

                Text("—")
                    .foregroundStyle(AppColors.textSecondary)

            }

        }

    }

    // MARK: - Helper Functions

    private func dayLabel(for date: Date) -> String {

        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today"
        }

        if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }

        return Self.dayLabelFormatter.string(from: date)

    }

    private func dayTotal(for txns: [Transaction]) -> Double {

        txns.reduce(0) { partial, transaction in
            partial + (transaction.type == "Income" ? transaction.amount : -transaction.amount)
        }

    }

    private func timeString(for date: Date) -> String {

        Self.timeFormatter.string(from: date)

    }

    private func formattedDate(_ date: Date) -> String {

        Self.fullDateFormatter.string(from: date)

    }

}

#Preview {

    NavigationStack {

        DashboardView()

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
