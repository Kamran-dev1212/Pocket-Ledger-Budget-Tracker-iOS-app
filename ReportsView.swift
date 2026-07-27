import SwiftUI
import SwiftData
import Charts

struct ReportsView: View {

    @Query(sort: \Transaction.date, order: .reverse)
    private var transactions: [Transaction]

    // MARK: - This Month's Transactions

    private var currentMonthTransactions: [Transaction] {

        let calendar = Calendar.current
        let now = Date()

        return transactions.filter {
            calendar.isDate($0.date, equalTo: now, toGranularity: .month)
        }

    }

    private var totalIncome: Double {
        currentMonthTransactions
            .filter { $0.type == "Income" }
            .reduce(0) { $0 + $1.amount }
    }

    private var totalExpense: Double {
        currentMonthTransactions
            .filter { $0.type == "Expense" }
            .reduce(0) { $0 + $1.amount }
    }

    private var totalSavings: Double {
        totalIncome - totalExpense
    }

    // MARK: - Category Breakdown

    private var categoryBreakdown: [CategoryAmount] {

        let expenses = currentMonthTransactions.filter { $0.type == "Expense" }

        let grouped = Dictionary(grouping: expenses, by: { $0.category })

        let summed = grouped.map { category, items -> (String, Double) in
            (category, items.reduce(0) { $0 + $1.amount })
        }

        let sorted = summed.sorted { $0.1 > $1.1 }

        return sorted.enumerated().map { index, item in

            let percentage = totalExpense > 0
                ? (item.1 / totalExpense) * 100
                : 0

            return CategoryAmount(
                category: item.0,
                amount: item.1,
                percentage: percentage,
                color: AppColors.chartPalette[index % AppColors.chartPalette.count]
            )

        }

    }

    var body: some View {

        NavigationStack {

            ZStack {

                AppColors.background
                    .ignoresSafeArea()

                if currentMonthTransactions.isEmpty {

                    VStack(spacing: 20) {

                        ZStack {

                            Circle()
                                .fill(AppColors.primary.opacity(0.12))
                                .frame(width: 120, height: 120)

                            Image(systemName: "chart.pie.fill")
                                .font(.system(size: 54, weight: .semibold))
                                .foregroundStyle(AppColors.primary)

                        }

                        Text("No Data Yet")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Add some transactions this month to see your statistics.")
                            .foregroundStyle(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                    }

                } else {

                    ScrollView {

                        VStack(spacing: 20) {

                            // MARK: Monthly Summary

                            StatisticsCardView(
                                title: "Income",
                                amount: totalIncome,
                                icon: "arrow.down.circle.fill",
                                color: AppColors.success
                            )

                            StatisticsCardView(
                                title: "Expenses",
                                amount: totalExpense,
                                icon: "arrow.up.circle.fill",
                                color: AppColors.expense
                            )

                            StatisticsCardView(
                                title: "Savings",
                                amount: totalSavings,
                                icon: "banknote.fill",
                                color: AppColors.primary
                            )

                            // MARK: Expense Distribution Chart

                            if !categoryBreakdown.isEmpty {

                                VStack(alignment: .leading, spacing: 16) {

                                    Text("Expense Distribution")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(AppColors.textPrimary)

                                    Chart(categoryBreakdown) { item in

                                        SectorMark(
                                            angle: .value("Amount", item.amount),
                                            innerRadius: .ratio(0.6),
                                            angularInset: 2
                                        )
                                        .foregroundStyle(item.color)
                                        .cornerRadius(4)

                                    }
                                    .frame(height: 220)

                                }
                                .padding()
                                .background(AppColors.card)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                                .shadow(
                                    color: AppColors.shadow,
                                    radius: 6,
                                    x: 0,
                                    y: 3
                                )

                            }

                            // MARK: Top Spending Categories

                            if !categoryBreakdown.isEmpty {

                                VStack(alignment: .leading, spacing: 16) {

                                    Text("Top Spending Categories")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(AppColors.textPrimary)

                                    CategoryBreakdownView(
                                        categories: categoryBreakdown
                                    )

                                }

                            }

                        }
                        .padding()

                    }

                }

            }
            .navigationTitle("Statistics")

        }

    }

}

#Preview {
    ReportsView()
}
