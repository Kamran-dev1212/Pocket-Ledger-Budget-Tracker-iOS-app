import SwiftUI
import Foundation

// MARK: - Insight Data Models

struct SavingsHealth {
    let rate: Double
    let rating: String
    let color: Color
}

struct CategoryInsight {
    let category: String
    let amount: Double
    let percentage: Double
}

struct BudgetPerformanceInsight {
    let total: Int
    let onTrack: Int
    let nearLimit: Int
    let exceeded: Int
}

struct MonthlyComparisonInsight {
    let incomeChange: Double?
    let expenseChange: Double?
    let savingsChange: Double?
}

struct FinancialInsights {
    let savingsHealth: SavingsHealth?
    let biggestExpense: CategoryInsight?
    let budgetPerformance: BudgetPerformanceInsight?
    let highestTransaction: Transaction?
    let monthlyComparison: MonthlyComparisonInsight?
    let smartTips: [String]
}

// MARK: - Insights Engine

struct InsightsEngine {

    static func generate(transactions: [Transaction], budgets: [Budget]) -> FinancialInsights {

        let calendar = Calendar.current
        let now = Date()

        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)

        let currentMonthTransactions = transactions.filter {
            calendar.isDate($0.date, equalTo: now, toGranularity: .month)
        }

        let previousMonthTransactions: [Transaction] = {

            guard let previousMonthDate = calendar.date(byAdding: .month, value: -1, to: now) else {
                return []
            }

            return transactions.filter {
                calendar.isDate($0.date, equalTo: previousMonthDate, toGranularity: .month)
            }

        }()

        // MARK: Current & Previous Totals

        let currentIncome = sum(currentMonthTransactions, type: "Income")
        let currentExpense = sum(currentMonthTransactions, type: "Expense")
        let currentSavings = currentIncome - currentExpense

        let previousIncome = sum(previousMonthTransactions, type: "Income")
        let previousExpense = sum(previousMonthTransactions, type: "Expense")
        let previousSavings = previousIncome - previousExpense

        // MARK: A. Savings Health

        var savingsHealth: SavingsHealth? = nil

        if currentIncome > 0 {

            let rate = (currentSavings / currentIncome) * 100
            let rating: String
            let color: Color

            if rate >= 30 {
                rating = "Excellent"
                color = AppColors.success
            } else if rate >= 15 {
                rating = "Good"
                color = AppColors.primary
            } else if rate >= 0 {
                rating = "Fair"
                color = AppColors.warning
            } else {
                rating = "Needs Attention"
                color = AppColors.danger
            }

            savingsHealth = SavingsHealth(rate: rate, rating: rating, color: color)

        }

        // MARK: B. Biggest Expense Category

        var biggestExpense: CategoryInsight? = nil
        let expenseItems = currentMonthTransactions.filter { $0.type == "Expense" }

        if !expenseItems.isEmpty && currentExpense > 0 {

            let grouped = Dictionary(grouping: expenseItems, by: { $0.category })
            let summed = grouped.map { ($0.key, $0.value.reduce(0) { $0 + $1.amount }) }

            if let top = summed.max(by: { $0.1 < $1.1 }) {

                let percentage = (top.1 / currentExpense) * 100
                biggestExpense = CategoryInsight(category: top.0, amount: top.1, percentage: percentage)

            }

        }

        // MARK: C. Budget Performance (current month/year budgets)
        //
        // The banding was previously inlined here as
        // < 0.6 onTrack / < 0.8 nearLimit / else exceeded, which
        // reported someone at 85% of budget as having exceeded it.
        // Now delegated to BudgetMath so this and BudgetCardView
        // always agree.

        var budgetPerformance: BudgetPerformanceInsight? = nil

        let currentMonthBudgets = budgets.filter {
            $0.month == currentMonth && $0.year == currentYear
        }

        if !currentMonthBudgets.isEmpty {

            // Pre-group this month's expenses by category once,
            // instead of re-filtering the whole transaction list
            // per budget. Matters as history grows.

            let currentMonthExpensesByCategory = Dictionary(
                grouping: currentMonthTransactions.filter { $0.type == "Expense" },
                by: { $0.category }
            )
            .mapValues { items in
                items.reduce(0) { $0 + $1.amount }
            }

            var onTrack = 0
            var nearLimit = 0
            var exceeded = 0

            for budget in currentMonthBudgets {

                let spent = currentMonthExpensesByCategory[budget.category] ?? 0

                switch BudgetMath.status(
                    spent: spent,
                    budgetAmount: budget.amount
                ) {

                case .onTrack:
                    onTrack += 1

                case .nearLimit:
                    nearLimit += 1

                case .exceeded:
                    exceeded += 1

                }

            }

            budgetPerformance = BudgetPerformanceInsight(
                total: currentMonthBudgets.count,
                onTrack: onTrack,
                nearLimit: nearLimit,
                exceeded: exceeded
            )

        }

        // MARK: D. Highest Expense Transaction

        let highestTransaction = expenseItems.max(by: { $0.amount < $1.amount })

        // MARK: E. Monthly Comparison

        var monthlyComparison: MonthlyComparisonInsight? = nil

        if !previousMonthTransactions.isEmpty {

            monthlyComparison = MonthlyComparisonInsight(
                incomeChange: percentChange(from: previousIncome, to: currentIncome),
                expenseChange: percentChange(from: previousExpense, to: currentExpense),
                savingsChange: percentChange(from: previousSavings, to: currentSavings)
            )

        }

        // MARK: F. Smart Tips

        var tips: [String] = []

        if let biggestExpense {
            tips.append("\(biggestExpense.category) is your biggest expense this month.")
        }

        if let budgetPerformance {

            if budgetPerformance.exceeded == 0 && budgetPerformance.nearLimit == 0 {
                tips.append("You stayed within all your budgets.")
            } else if budgetPerformance.nearLimit > 0 {
                tips.append("Some budgets are close to their limit — keep an eye on your spending.")
            }

            if budgetPerformance.exceeded > 0 {
                tips.append("\(budgetPerformance.exceeded) budget\(budgetPerformance.exceeded == 1 ? "" : "s") went over this month.")
            }

        }

        if let savingsHealth {

            if savingsHealth.rate >= 0 {

                tips.append("You saved \(Int(savingsHealth.rate))% of your income this month.")

            } else {

                // A negative savings rate previously read
                // "You saved -40% of your income", which is nonsense.

                tips.append("You spent \(Int(abs(savingsHealth.rate)))% more than you earned this month.")

            }

        }

        if tips.isEmpty {
            tips.append("Add more transactions to unlock personalized insights.")
        }

        return FinancialInsights(
            savingsHealth: savingsHealth,
            biggestExpense: biggestExpense,
            budgetPerformance: budgetPerformance,
            highestTransaction: highestTransaction,
            monthlyComparison: monthlyComparison,
            smartTips: tips
        )

    }

    // MARK: - Helpers

    private static func sum(_ transactions: [Transaction], type: String) -> Double {
        transactions.filter { $0.type == type }.reduce(0) { $0 + $1.amount }
    }

    private static func percentChange(from oldValue: Double, to newValue: Double) -> Double? {
        guard oldValue != 0 else { return nil }
        return ((newValue - oldValue) / abs(oldValue)) * 100
    }

}
