import SwiftUI

import SwiftData
import UIKit
import UniformTypeIdentifiers

private struct TransactionDayGroup: Identifiable {

    let id: Date

    let date: Date

    let transactions: [Transaction]

}

struct DashboardView: View {

    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Transaction.date, order: .reverse)

    private var transactions: [Transaction]

    // Needed so a renamed or re-iconed category shows its real icon.

    @Query private var userCategories: [UserCategory]

    @Query(sort: \Budget.category)

    private var budgets: [Budget]

    @State private var detailTransaction: Transaction?

    @State private var openSwipeRowID: ObjectIdentifier?

    @State private var showAddTransaction = false

    @State private var showBudget = false

    @State private var showReports = false

    @State private var showProfile = false

    @State private var showAboutUs = false

    @State private var showManageCategories = false

    @State private var showCategoriesPaywall = false

    @ObservedObject private var subscriptionManager = SubscriptionManager.shared

    @State private var showGroups = false

    @ObservedObject private var shareCoordinator = ShareAcceptanceCoordinator.shared

    @State private var showShareAlert = false

    @State private var shareAlertTitle = ""

    @State private var shareAlertMessage = ""

    @State private var showStartNewMonthConfirm = false

    @State private var showClearAllStep1 = false

    @State private var showClearAllStep2 = false

    @State private var backupFileURL: URL?

    @State private var showBackupShareSheet = false

    @State private var showRestoreBackupScreen = false

    @State private var showBackupError = false

    @State private var backupErrorMessage = ""

    @State private var showBalance = false

    @State private var showSummary = false

    @State private var showTransactions = false

    @AppStorage("selectedCurrency") private var currency: String = "USD"

    private let recentTransactionLimit = 20

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

    private var activeTransactions: [Transaction] {

        let calendar = Calendar.current

        guard let currentMonth = calendar.dateInterval(

            of: .month,

            for: Date()

        ) else {

            return []

        }

        return transactions.filter { transaction in

            !transaction.isArchived &&

            transaction.date >= currentMonth.start &&

            transaction.date < currentMonth.end

        }

    }

    var totalIncome: Double {

        activeTransactions

            .filter { $0.type == "Income" }

            .reduce(0) { $0 + $1.amount }

    }

    var totalExpense: Double {

        activeTransactions

            .filter { $0.type == "Expense" }

            .reduce(0) { $0 + $1.amount }

    }

    var totalBalance: Double {

        totalIncome - totalExpense

    }

    private var groupedTransactions: [TransactionDayGroup] {

        let calendar = Calendar.current

        let recent = Array(activeTransactions.prefix(recentTransactionLimit))

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

        activeTransactions.count > recentTransactionLimit

    }

    private var insights: FinancialInsights {

        // Must be activeTransactions, not transactions — otherwise the

        // balance above resets on Start New Month while the insight cards

        // below keep reporting the archived month.

        InsightsEngine.generate(

            transactions: activeTransactions,

            budgets: budgets

        )

    }

    var body: some View {

        ZStack {

            ZStack {

                AppColors.dashboardGradient

            }

            .ignoresSafeArea()

            ScrollView {

                LazyVStack(spacing: 16) {

                    // **MARK: - Unified Purple Dashboard Header**

                    VStack(spacing: 0) {

                        HStack(alignment: .center, spacing: 12) {

                            DashboardHeaderView {

                                showProfile = true

                            }

                            Menu {

                                Button {

                                    showProfile = true

                                } label: {

                                    Label("Profile", systemImage: "person.circle")

                                }

                                Button {

                                    if subscriptionManager.hasPremiumFeatures {

                                        showManageCategories = true

                                    } else {

                                        showCategoriesPaywall = true

                                    }

                                } label: {

                                    Label(

                                        "Manage Categories",

                                        systemImage: "square.grid.2x2.fill"

                                    )

                                }

                                Divider()

                                Button {
                                    do {
                                        backupFileURL = try PocketLedgerBackupExporter.createBackupFile(
                                            from: modelContext,
                                            selectedCurrency: currency
                                        )
                                        showBackupShareSheet = true
                                    } catch {
                                        backupErrorMessage = error.localizedDescription
                                        showBackupError = true
                                    }
                                } label: {
                                    Label("Save Data", systemImage: "square.and.arrow.up")
                                }

                                Button {
                                    showRestoreBackupScreen = true
                                } label: {
                                    Label("Restore Data", systemImage: "square.and.arrow.down")
                                }

                                Button {
                                    showStartNewMonthConfirm = true

                                } label: {

                                    Label(

                                        "Start New Month",

                                        systemImage: "calendar.badge.clock"

                                    )

                                }

                                Button(role: .destructive) {

                                    showClearAllStep1 = true

                                } label: {

                                    Label("Clear All Data", systemImage: "trash")

                                }

                                Divider()

                                Button {

                                    showAboutUs = true

                                } label: {

                                    Label("About Us", systemImage: "info.circle")

                                }

                            } label: {

                                Image(systemName: "line.3.horizontal")

                                    .font(.system(size: 20, weight: .semibold))

                                    .foregroundStyle(.white)

                                    .frame(width: 44, height: 44)

                                    .contentShape(Rectangle())

                            }

                            .accessibilityLabel("More")

                        }

                        .padding(.horizontal, AppColors.pageHorizontalPadding)

                        .padding(.top, 20)

                        BalanceCardView(

                            balance: totalBalance,

                            presentationStyle: .header

                        )

                        .opacity(showBalance ? 1 : 0)

                        .offset(y: showBalance ? 0 : 8)

                        .padding(.top, 8)

                        .padding(.bottom, 20)

                    }

                    .frame(maxWidth: .infinity)

                    .background(AppColors.dashboardGradient)

                    // **MARK: - Dashboard Content Container**

                    VStack(spacing: 14) {

                        // **MARK: Income & Expense Cards**

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

                                    icon: "arrow.down.left"

                                )

                            }

                            .buttonStyle(.plain)

                            .frame(maxWidth: .infinity)

                            Rectangle()

                                .fill(AppColors.textSecondary.opacity(0.12))

                                .frame(width: 1, height: 32)

                                .accessibilityHidden(true)

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

                                    icon: "arrow.up.right",

                                    alignment: .trailing

                                )

                            }

                            .buttonStyle(.plain)

                            .frame(maxWidth: .infinity)

                        }

                        .opacity(showSummary ? 1 : 0)

                        .offset(y: showSummary ? 0 : 8)

                        // **MARK: Dashboard Shortcuts**

                        HStack(spacing: 9) {

                            Button {

                                showBudget = true

                            } label: {

                                DashboardShortcutView(

                                    title: "Budgets",

                                    icon: "chart.pie.fill"

                                )

                            }

                            .buttonStyle(.plain)

                            .frame(maxWidth: .infinity)

                            Button {

                                showGroups = true

                            } label: {

                                DashboardShortcutView(

                                    title: "Groups",

                                    icon: "person.2.fill"

                                )

                            }

                            .buttonStyle(.plain)

                            .frame(maxWidth: .infinity)

                            Button {

                                showReports = true

                            } label: {

                                DashboardShortcutView(

                                    title: "Reports",

                                    icon: "chart.bar.fill"

                                )

                            }

                            .buttonStyle(.plain)

                            .frame(maxWidth: .infinity)

                        }

                        .frame(maxWidth: .infinity)

                        // **MARK: Recent Transactions Timeline**

                        VStack(alignment: .leading, spacing: 14) {

                            HStack {

                                Text("Recent Transactions")

                                    .font(.system(size: 16, weight: .semibold))

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

                            if activeTransactions.isEmpty {

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

                                // **MARK: Link to full history**

                                if hasMoreThanRecentWindow {

                                    NavigationLink {

                                        TransactionHistoryView()

                                    } label: {

                                        HStack(spacing: 6) {

                                            Text("View all \(activeTransactions.count) transactions")

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

                        // **MARK: Financial Insights**

                        VStack(alignment: .leading, spacing: 12) {

                            Text("Financial Insights")

                                .font(.system(size: 16, weight: .semibold))

                                .foregroundStyle(AppColors.textPrimary)

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

                    } // Closes Dashboard Content Container

                    .padding(.horizontal, AppColors.pageHorizontalPadding)

                    .padding(.top, 28)

                    .padding(.bottom, 100)

                    .frame(maxWidth: .infinity)

                    .background {

                        UnevenRoundedRectangle(

                            topLeadingRadius: AppColors.dashboardContentCornerRadius,

                            topTrailingRadius: AppColors.dashboardContentCornerRadius

                        )

                        .fill(AppColors.dashboardSurface)

                    }

                    .padding(.top, -24)

                } // Closes original LazyVStack

                .padding(.top, 0)

                .padding(.bottom, 0)

            } // Closes ScrollView

        } // Closes outer ZStack

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

        .fullScreenCover(isPresented: $showAddTransaction) {

            AddTransactionView(transaction: nil)

        }

        .fullScreenCover(isPresented: $showBudget) {

            BudgetView()

        }

        .fullScreenCover(isPresented: $showReports) {

            ReportsView()

        }

        .fullScreenCover(isPresented: $showProfile) {

            ProfileView()

        }

        .fullScreenCover(isPresented: $showAboutUs) {

            AboutUsView()

        }

        .fullScreenCover(isPresented: $showManageCategories) {

            NavigationStack {

                ManageCategoriesView()

                    .toolbar {

                        ToolbarItem(placement: .topBarLeading) {

                            Button("Done") {

                                showManageCategories = false

                            }

                            .fontWeight(.semibold)

                            .foregroundStyle(AppColors.primary)

                        }

                    }

            }

        }

        .fullScreenCover(isPresented: $showCategoriesPaywall) {

            PaywallView(reason: "Create and manage custom categories with Premium.")

        }

        .fullScreenCover(isPresented: $showGroups) {

            GroupsListView()

        }

        .fullScreenCover(isPresented: $showRestoreBackupScreen) {
            PocketLedgerRestoreBackupView()
        }
        .sheet(isPresented: $showBackupShareSheet) {
            if let backupFileURL {
                PocketLedgerBackupShareSheet(activityItems: [backupFileURL])
            }
        }
        .alert("Backup Failed", isPresented: $showBackupError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(backupErrorMessage)
        }
        .onReceive(shareCoordinator.$lastResult) { result in

            guard let result else { return }

            // Never present an alert and the Groups sheet in the same tick.

            // UIKit drops the second one ("while a presentation is in

            // progress") and the user is left on the Dashboard. The small

            // delay also lets the launch transition settle first.

            switch result {

            case .success:

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {

                    shareCoordinator.lastResult = nil

                    showGroups = true

                }

            case .failure(let message):

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {

                    shareCoordinator.lastResult = nil

                    shareAlertTitle = "Couldn't Join Group"

                    shareAlertMessage = message

                    showShareAlert = true

                }

            }

        }

        .alert(shareAlertTitle, isPresented: $showShareAlert) {

            Button("OK", role: .cancel) { }

        } message: {

            Text(shareAlertMessage)

        }

        .alert("Start New Month?", isPresented: $showStartNewMonthConfirm) {

            Button("Cancel", role: .cancel) { }

            Button("Start New Month") {

                startNewMonth()

            }

        } message: {

            Text("Current transactions will move to history and won't count toward your balance anymore. Nothing is deleted, and past data stays available in Transaction History under Archived.")

        }

        .alert("Clear All Data", isPresented: $showClearAllStep1) {

            Button("Cancel", role: .cancel) { }

            Button("Continue", role: .destructive) {

                showClearAllStep2 = true

            }

        } message: {

            Text("This permanently deletes every transaction and budget, including archived history. This cannot be undone.")

        }

        .alert("Are You Sure?", isPresented: $showClearAllStep2) {

            Button("Cancel", role: .cancel) { }

            Button("Delete Everything", role: .destructive) {

                clearAllData()

            }

        } message: {

            Text("This is your last chance to cancel. All transactions and budgets will be gone permanently.")

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

    // **MARK: - Helper Views**

    @ViewBuilder

    private func dayCard(for txns: [Transaction]) -> some View {

        VStack(spacing: 0) {

            ForEach(Array(txns.enumerated()), id: \.element.id) { index, transaction in

                SwipeToDeleteRow(

                    id: ObjectIdentifier(transaction),

                    openRowID: $openSwipeRowID

                ) {

                    delete(transaction)

                } content: {

                    TransactionTimelineRowView(

                        icon: TransactionIcon.icon(

                            for: transaction.category,

                            type: transaction.type,

                            in: userCategories

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

                    .padding(.horizontal, 4)

                    .padding(.vertical, 4)

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

        .background(AppColors.dashboardSurface)

    }

    // **MARK: - Delete**

    private func delete(_ transaction: Transaction) {

        withAnimation {

            modelContext.delete(transaction)

            SaveReporter.shared.save(

                modelContext,

                failureMessage: "That transaction couldn't be deleted."

            )

        }

    }

    // **MARK: - Start New Month**

    private func startNewMonth() {

        let calendar = Calendar.current

        guard let startOfCurrentMonth = calendar.dateInterval(

            of: .month,

            for: Date()

        )?.start else {

            return

        }

        var hasChanges = false

        for transaction in transactions {

            if !transaction.isArchived &&

                transaction.date < startOfCurrentMonth {

                transaction.isArchived = true

                hasChanges = true

            }

        }

        guard hasChanges else {

            return

        }

        SaveReporter.shared.save(

            modelContext,

            failureMessage: "Couldn't archive previous months."

        )

    }

    // **MARK: - Clear All Data**

    private func clearAllData() {

        for transaction in transactions {

            modelContext.delete(transaction)

        }

        for budget in budgets {

            modelContext.delete(budget)

        }

        SaveReporter.shared.save(

            modelContext,

            failureMessage: "Couldn't clear your data."

        )

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

    // **MARK: - Helper Functions**

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

// MARK: - iOS Backup Share Sheet

private struct PocketLedgerBackupShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) { }
}


// MARK: - Read-only Restore Backup Validation Screen
// This view deliberately does not access SwiftData or CloudKit.
private struct PocketLedgerRestoreBackupView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var showFilePicker = false
    @State private var selectedBackup: PocketLedgerBackup?
    @State private var validationError: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "externaldrive.badge.questionmark")
                    .font(.system(size: 46))
                    .foregroundStyle(AppColors.primary)

                Text("Restore Data")
                    .font(.title2.bold())

                Text("Select a Pocket Ledger JSON backup to check its contents. This step does not restore, replace, or delete any data.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                Button {
                    showFilePicker = true
                } label: {
                    Label("Choose Backup File", systemImage: "folder")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.primary)

                if let backup = selectedBackup {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Backup Validated", systemImage: "checkmark.shield.fill")
                            .font(.headline)
                            .foregroundStyle(AppColors.success)

                        LabeledContent("Format version", value: String(backup.formatVersion))
                        LabeledContent("Currency", value: backup.selectedCurrency)
                        LabeledContent("Transactions", value: String(backup.transactions.count))
                        LabeledContent("Budgets", value: String(backup.budgets.count))
                        LabeledContent("Categories", value: String(backup.categories.count))
                        LabeledContent("Profiles", value: String(backup.profiles.count))

                        Text("Your existing data has not been changed.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(AppColors.card, in: RoundedRectangle(cornerRadius: 16))
                }

                Spacer(minLength: 0)
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(AppColors.dashboardSurface.ignoresSafeArea())
            .navigationTitle("Backup Validation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AppColors.primary)
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    let accessGranted = url.startAccessingSecurityScopedResource()
                    defer {
                        if accessGranted { url.stopAccessingSecurityScopedResource() }
                    }
                    do {
                        let data = try Data(contentsOf: url)
                        let backup = try PocketLedgerBackupValidator.validate(data: data)
                        selectedBackup = backup
                        validationError = nil
                    } catch {
                        selectedBackup = nil
                        validationError = error.localizedDescription
                    }
                case .failure(let error):
                    selectedBackup = nil
                    validationError = error.localizedDescription
                }
            }
            .alert(
                "Backup Validation Failed",
                isPresented: Binding(
                    get: { validationError != nil },
                    set: { if !$0 { validationError = nil } }
                )
            ) {
                Button("OK", role: .cancel) { validationError = nil }
            } message: {
                Text(validationError ?? "Unable to read this backup.")
            }
        }
    }
}
