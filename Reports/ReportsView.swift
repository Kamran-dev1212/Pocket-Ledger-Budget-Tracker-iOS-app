import SwiftUI
import SwiftData
import Charts

struct ReportsView: View {

    @Environment(\.dismiss) private var dismiss

    @AppStorage("selectedCurrency")
    private var currency: String = "USD"

    @Query(sort: \Transaction.date, order: .reverse)
    private var transactions: [Transaction]

    private enum ReportPeriod: String, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"

        var calendarComponent: Calendar.Component {
            switch self {
            case .daily:
                return .day
            case .weekly:
                return .weekOfYear
            case .monthly:
                return .month
            }
        }
    }

    @State private var selectedPeriod: ReportPeriod = .monthly
    @State private var reportDate = Date()

    // MARK: - Selected Period

    private var selectedDateInterval: DateInterval {
        Calendar.current.dateInterval(
            of: selectedPeriod.calendarComponent,
            for: reportDate
        )!
    }

    private var periodLabel: String {
        let interval = selectedDateInterval

        switch selectedPeriod {
        case .daily:
            return interval.start.formatted(
                .dateTime.day().month(.wide).year()
            )

        case .weekly:
            let lastDay = Calendar.current.date(
                byAdding: .day,
                value: -1,
                to: interval.end
            )!

            let start = interval.start.formatted(
                date: .abbreviated,
                time: .omitted
            )

            let end = lastDay.formatted(
                date: .abbreviated,
                time: .omitted
            )

            return "\(start) – \(end)"

        case .monthly:
            return interval.start.formatted(
                .dateTime.month(.wide).year()
            )
        }
    }

    // MARK: - Filtered Transactions

    
    private var filteredTransactions: [Transaction] {

        let interval = selectedDateInterval

        return transactions.filter { transaction in
            transaction.date >= interval.start &&
            transaction.date < interval.end
        }
    }


    private var totalIncome: Double {
        filteredTransactions
            .filter { $0.type == "Income" }
            .reduce(0) { $0 + $1.amount }
    }

    private var totalExpense: Double {
        filteredTransactions
            .filter { $0.type == "Expense" }
            .reduce(0) { $0 + $1.amount }
    }

    private var totalSavings: Double {
        totalIncome - totalExpense
    }

    // MARK: - Category Breakdown

    private var categoryBreakdown: [CategoryAmount] {
        let expenses = filteredTransactions.filter {
            $0.type == "Expense"
        }

        let grouped = Dictionary(
            grouping: expenses,
            by: { $0.category }
        )

        let sorted = grouped.map { category, items in
            (
                category: category,
                amount: items.reduce(0.0) { $0 + $1.amount }
            )
        }
        .sorted {
            if $0.amount == $1.amount {
                return $0.category < $1.category
            }

            return $0.amount > $1.amount
        }

        let expenseTotal = totalExpense
        let palette = AppColors.chartPalette

        return sorted.enumerated().map { index, item in
            let percentage = expenseTotal > 0
                ? (item.amount / expenseTotal) * 100
                : 0

            let color = palette.isEmpty
                ? AppColors.dashboardPurple
                : palette[index % palette.count]

            return CategoryAmount(
                category: item.category,
                amount: item.amount,
                percentage: percentage,
                color: color
            )
        }
    }

    // MARK: - Period Navigation

    private func movePeriod(by value: Int) {
        if let newDate = Calendar.current.date(
            byAdding: selectedPeriod.calendarComponent,
            value: value,
            to: selectedDateInterval.start
        ) {
            reportDate = newDate
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.dashboardSurface
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    header

                    ScrollView {
                        reportContent
                    }
                    .background(AppColors.dashboardSurface)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 28,
                            topTrailingRadius: 28
                        )
                    )
                }
                .background {
                    AppColors.dashboardGradient
                        .ignoresSafeArea(edges: .top)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Statistics")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 4) {
                ForEach(ReportPeriod.allCases, id: \.self) { period in
                    Button {
                        selectedPeriod = period
                    } label: {
                        Text(period.rawValue)
                            .font(
                                .system(size: 13, weight: .semibold)
                            )
                            .foregroundStyle(
                                Color.white.opacity(
                                    selectedPeriod == period ? 1 : 0.7
                                )
                            )
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 44)
                            .background {
                                if selectedPeriod == period {
                                    RoundedRectangle(cornerRadius: 9)
                                        .fill(Color.white.opacity(0.18))
                                }
                            }
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(
                        selectedPeriod == period ? .isSelected : []
                    )
                }
            }
            .padding(4)
            .background(
                Color.white.opacity(0.08),
                in: RoundedRectangle(cornerRadius: 12)
            )
        }
        .padding(.horizontal, AppColors.pageHorizontalPadding)
        .padding(.top, 12)
        .padding(.bottom, 16)
    }

    // MARK: - Report Content

    private var reportContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            periodNavigation

            periodSummary

            if filteredTransactions.isEmpty {
                emptyState
            } else if categoryBreakdown.isEmpty {
                Text("No expenses recorded for this period.")
                    .font(.system(size: 14))
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            } else {
                expenseTotal
                expenseChart
                expenseBreakdown
            }
        }
        .padding(.horizontal, AppColors.pageHorizontalPadding)
        .padding(.top, 24)
        .padding(.bottom, 32)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Date Navigation

    private var periodNavigation: some View {
        HStack(spacing: 8) {
            Button {
                movePeriod(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Previous period")

            Text(periodLabel)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            Button {
                movePeriod(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Next period")
        }
        .buttonStyle(.plain)
        .foregroundStyle(AppColors.dashboardPurple)
    }

    // MARK: - Period Summary

    private var periodSummary: some View {
        HStack(alignment: .top, spacing: 12) {
            reportSummary(
                title: "Income",
                amount: totalIncome,
                color: AppColors.success
            )

            reportSummary(
                title: "Expenses",
                amount: totalExpense,
                color: AppColors.expense
            )

            reportSummary(
                title: "Savings",
                amount: totalSavings,
                color: totalSavings < 0
                    ? AppColors.expense
                    : AppColors.dashboardPurple
            )
        }
    }

    private func reportSummary(
        title: String,
        amount: Double,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12))
                .foregroundStyle(AppColors.textSecondary)

            Text(
                CurrencyManager.string(
                    for: amount,
                    currencyCode: currency
                )
            )
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(color)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Expense Total

    private var expenseTotal: some View {
        VStack(spacing: 6) {
            Text("Total expenses")
                .font(.system(size: 12))
                .foregroundStyle(AppColors.textSecondary)

            Text(
                CurrencyManager.string(
                    for: totalExpense,
                    currencyCode: currency
                )
            )
            .font(.system(size: 26, weight: .bold))
            .foregroundStyle(AppColors.textPrimary)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Expense Chart

    private var expenseChart: some View {
        Chart(categoryBreakdown) { item in
            SectorMark(
                angle: .value("Amount", item.amount),
                innerRadius: .ratio(0.68),
                angularInset: 2
            )
            .foregroundStyle(item.color)
            .cornerRadius(4)
            .accessibilityLabel(item.category)
            .accessibilityValue(
                CurrencyManager.string(
                    for: item.amount,
                    currencyCode: currency
                )
            )
        }
        .frame(height: 180)
    }

    // MARK: - Expense Breakdown

    private var expenseBreakdown: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Expenses Breakdown")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)

            CategoryBreakdownView(
                categories: categoryBreakdown
            )
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar")
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(AppColors.dashboardPurple)
                .accessibilityHidden(true)

            Text("No Data Yet")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)

            Text(
                "No transactions for this period. Use the arrows to view another period."
            )
            .font(.system(size: 13))
            .foregroundStyle(AppColors.textSecondary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

#Preview {
    ReportsView()
        .modelContainer(
            for: Transaction.self,
            inMemory: true
        )
}
