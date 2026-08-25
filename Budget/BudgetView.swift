import SwiftUI
import SwiftData

struct BudgetView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Budget.category)
    private var budgets: [Budget]

    @Query(sort: \Transaction.date, order: .reverse)
    private var transactions: [Transaction]

    @State private var showAddBudget = false
    @State private var selectedBudget: Budget?

    // MARK: - Selected Period

    @State private var selectedMonth: Int = Calendar.current.component(.month, from: .now)
    @State private var selectedYear: Int = Calendar.current.component(.year, from: .now)

    /// How far ahead the user may navigate. Prevents wandering into
    /// 2043 with a stuck finger.
    private let maxMonthsAhead = 12

    // MARK: - Period Helpers

    /// First day of the selected month, used for all date arithmetic.
    private var selectedPeriodStart: Date {

        Calendar.current.date(
            from: DateComponents(year: selectedYear, month: selectedMonth)
        ) ?? .now

    }

    private var currentPeriodStart: Date {

        let calendar = Calendar.current

        return calendar.date(
            from: DateComponents(
                year: calendar.component(.year, from: .now),
                month: calendar.component(.month, from: .now)
            )
        ) ?? .now

    }

    private var canGoForward: Bool {

        guard let limit = Calendar.current.date(
            byAdding: .month,
            value: maxMonthsAhead,
            to: currentPeriodStart
        ) else {
            return false
        }

        return selectedPeriodStart < limit

    }

    private var periodLabel: String {

        let symbols = Calendar.current.monthSymbols

        guard selectedMonth >= 1, selectedMonth <= symbols.count else {
            return String(selectedYear)
        }

        return "\(symbols[selectedMonth - 1]) \(selectedYear)"

    }

    // MARK: - Filtered Data

    private var budgetsForSelectedPeriod: [Budget] {

        budgets.filter {
            $0.month == selectedMonth && $0.year == selectedYear
        }

    }

    /// The most recent month before the selected one that actually has
    /// budgets. Usually the immediately previous month, but falls back
    /// further so a gap month doesn't disable the copy action.
    private var sourcePeriodForCopy: (month: Int, year: Int, budgets: [Budget])? {

        let calendar = Calendar.current

        let earlier = budgets.filter { budget in

            guard let start = calendar.date(
                from: DateComponents(year: budget.year, month: budget.month)
            ) else {
                return false
            }

            return start < selectedPeriodStart

        }

        guard !earlier.isEmpty else {
            return nil
        }

        // Newest period first.
        let sorted = earlier.sorted {
            ($0.year, $0.month) > ($1.year, $1.month)
        }

        guard let newest = sorted.first else {
            return nil
        }

        let group = earlier.filter {
            $0.month == newest.month && $0.year == newest.year
        }

        return (newest.month, newest.year, group)

    }

    private var sourcePeriodLabel: String? {

        guard let source = sourcePeriodForCopy else {
            return nil
        }

        let symbols = Calendar.current.monthSymbols

        guard source.month >= 1, source.month <= symbols.count else {
            return String(source.year)
        }

        return "\(symbols[source.month - 1]) \(source.year)"

    }

    // MARK: - Body

    var body: some View {

        NavigationStack {

            ZStack {

                AppColors.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {

                    monthNavigator

                    if budgetsForSelectedPeriod.isEmpty {

                        emptyState

                    } else {

                        ScrollView {

                            LazyVStack(spacing: 18) {

                                ForEach(budgetsForSelectedPeriod) { budget in

                                    BudgetCardView(
                                        budget: budget,
                                        spent: spent(for: budget),
                                        onEdit: {

                                            selectedBudget = budget

                                        },
                                        onDelete: {

                                            modelContext.delete(budget)

                                        }
                                    )

                                }

                            }
                            .padding()

                        }

                    }

                }

            }
            .navigationTitle("Monthly Budget")
            .toolbar {

                ToolbarItem(placement: .topBarLeading) {

                    Button("Done") {

                        dismiss()

                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.primary)

                }

                ToolbarItem(placement: .topBarTrailing) {

                    Button {

                        showAddBudget = true

                    } label: {

                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(AppColors.primary)

                    }

                }

            }
            .sheet(isPresented: $showAddBudget) {

                AddBudgetView(
                    initialMonth: selectedMonth,
                    initialYear: selectedYear
                )

            }
            .sheet(item: $selectedBudget) { budget in

                AddBudgetView(budgetToEdit: budget)

            }

        }

    }

    // MARK: - Month Navigator

    @ViewBuilder
    private var monthNavigator: some View {

        HStack {

            Button {

                shiftPeriod(by: -1)

            } label: {

                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.primary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())

            }
            .accessibilityLabel("Previous month")

            Spacer()

            Text(periodLabel)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(AppColors.textPrimary)
                .accessibilityLabel("Showing \(periodLabel)")

            Spacer()

            Button {

                shiftPeriod(by: 1)

            } label: {

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(
                        canGoForward
                            ? AppColors.primary
                            : AppColors.textSecondary.opacity(0.35)
                    )
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())

            }
            .disabled(!canGoForward)
            .accessibilityLabel("Next month")

        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)

    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {

        ScrollView {

            VStack(spacing: 24) {

                ZStack {

                    Circle()
                        .fill(AppColors.primary.opacity(0.12))
                        .frame(width: 120, height: 120)

                    Image(systemName: "wallet.pass.fill")
                        .font(.system(size: 54, weight: .semibold))
                        .foregroundStyle(AppColors.primary)

                }

                Text("No Budgets for \(periodLabel)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Set monthly spending limits for each category and keep your finances under control.")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
                    .lineSpacing(3)

                VStack(spacing: 12) {

                    if let sourceLabel = sourcePeriodLabel {

                        Button {

                            copyBudgetsFromSourcePeriod()

                        } label: {

                            Label(
                                "Copy \(sourceLabel) Budgets",
                                systemImage: "doc.on.doc"
                            )
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)

                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppColors.primary)

                    }

                    Button {

                        showAddBudget = true

                    } label: {

                        Label("Add Budget", systemImage: "plus")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)

                    }
                    .buttonStyle(.bordered)
                    .tint(AppColors.primary)

                }
                .padding(.horizontal, 40)

            }
            .frame(maxWidth: .infinity)
            .padding(.top, 40)

        }

    }

    // MARK: - Spending

    /// Unchanged from the previous implementation: derived live from
    /// transactions, never stored on Budget.
    private func spent(for budget: Budget) -> Double {

        let calendar = Calendar.current

        return transactions
            .filter {
                $0.type == "Expense" &&
                $0.category == budget.category &&
                calendar.component(.month, from: $0.date) == budget.month &&
                calendar.component(.year, from: $0.date) == budget.year
            }
            .reduce(0) { $0 + $1.amount }

    }

    // MARK: - Period Navigation

    private func shiftPeriod(by months: Int) {

        let calendar = Calendar.current

        guard let shifted = calendar.date(
            byAdding: .month,
            value: months,
            to: selectedPeriodStart
        ) else {
            return
        }

        withAnimation(.easeInOut(duration: 0.2)) {

            selectedMonth = calendar.component(.month, from: shifted)
            selectedYear = calendar.component(.year, from: shifted)

        }

    }

    // MARK: - Copy Previous Budgets

    private func copyBudgetsFromSourcePeriod() {

        guard let source = sourcePeriodForCopy else {
            return
        }

        for budget in source.budgets {

            // Defensive: never create a second budget for the same
            // category in the selected period, even though this action
            // is only offered when the period is empty.

            let alreadyExists = budgets.contains {
                $0.category == budget.category &&
                $0.month == selectedMonth &&
                $0.year == selectedYear
            }

            guard !alreadyExists else {
                continue
            }

            modelContext.insert(

                Budget(
                    category: budget.category,
                    amount: budget.amount,
                    month: selectedMonth,
                    year: selectedYear
                )

            )

        }

        try? modelContext.save()

    }

}

#Preview {

    BudgetView()

}
