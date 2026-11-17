import SwiftUI

struct BudgetCardView: View {

    let budget: Budget
    let spent: Double
    var onEdit: () -> Void
    var onDelete: () -> Void

    @AppStorage("selectedCurrency")
    private var currency: String = "USD"

    // MARK: - Budget Calculations

    private var status: BudgetStatus {
        BudgetMath.status(
            spent: spent,
            budgetAmount: budget.amount
        )
    }

    private var remaining: Double {
        BudgetMath.remaining(
            spent: spent,
            budgetAmount: budget.amount
        )
    }

    private var overspend: Double {
        BudgetMath.overspend(
            spent: spent,
            budgetAmount: budget.amount
        )
    }

    private var progress: Double {
        BudgetMath.clampedProgress(
            spent: spent,
            budgetAmount: budget.amount
        )
    }

    private var progressPercent: Int {
        Int(
            (
                BudgetMath.progress(
                    spent: spent,
                    budgetAmount: budget.amount
                ) * 100
            ).rounded()
        )
    }

    // MARK: - Appearance

    private var categoryColor: Color {
        CategoryManager.color(for: budget.category)
    }

    private var categoryIcon: String {
        CategoryManager.icon(
            for: budget.category,
            type: "Expense"
        ) ?? "square.grid.2x2.fill"
    }

    private var statusColor: Color {
        switch status {
        case .onTrack:
            return AppColors.success
        case .nearLimit:
            return AppColors.warning
        case .exceeded:
            return AppColors.danger
        }
    }

    private var formattedSpent: String {
        CurrencyManager.string(
            for: spent,
            currencyCode: currency
        )
    }

    private var formattedBudget: String {
        CurrencyManager.string(
            for: budget.amount,
            currencyCode: currency
        )
    }

    // MARK: - Body

    var body: some View {

        VStack(alignment: .leading, spacing: 16) {

            // MARK: Category Header

            HStack(spacing: 12) {

                Image(systemName: categoryIcon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(categoryColor)
                    .frame(width: 44, height: 44)
                    .background(
                        categoryColor.opacity(0.12)
                    )
                    .clipShape(
                        RoundedRectangle(cornerRadius: 13)
                    )

                VStack(alignment: .leading, spacing: 5) {

                    Text(budget.category)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)

                    Text(status.label)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(statusColor)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(
                            statusColor.opacity(0.12)
                        )
                        .clipShape(Capsule())

                }

                Spacer(minLength: 4)

                Menu {

                    Button {
                        onEdit()
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }

                } label: {

                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())

                }
                .accessibilityLabel("Budget options")

            }

            // MARK: Spending Amounts

            VStack(alignment: .leading, spacing: 6) {

                HStack(alignment: .firstTextBaseline, spacing: 4) {

                    Text(formattedSpent)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)

                    Text("/ \(formattedBudget)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppColors.textSecondary)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)

                }
                .monospacedDigit()

                Text("Spent of total budget")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textSecondary)

            }

            // MARK: Progress

            VStack(spacing: 8) {

                GeometryReader { geometry in

                    ZStack(alignment: .leading) {

                        Capsule()
                            .fill(statusColor.opacity(0.12))

                        Capsule()
                            .fill(statusColor)
                            .frame(
                                width: geometry.size.width * progress
                            )

                    }

                }
                .frame(height: 8)

                HStack {

                    Text("\(progressPercent)% used")
                        .foregroundStyle(statusColor)

                    Spacer()

                    Text(status.label)
                        .foregroundStyle(AppColors.textSecondary)

                }
                .font(.system(size: 12, weight: .medium))

            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Budget progress")
            .accessibilityValue(
                "\(progressPercent) percent used, \(status.label)"
            )

            // MARK: Remaining Balance

            Rectangle()
                .fill(AppColors.textSecondary.opacity(0.12))
                .frame(height: 1)

            HStack {

                Text(
                    remaining < 0
                    ? "Over Budget"
                    : "Remaining"
                )
                .font(.system(size: 13))
                .foregroundStyle(AppColors.textSecondary)

                Spacer()

                Text(
                    CurrencyManager.string(
                        for: remaining < 0 ? overspend : remaining,
                        currencyCode: currency
                    )
                )
                .font(.system(size: 15, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(
                    remaining < 0
                    ? AppColors.danger
                    : AppColors.success
                )

            }

        }
        .padding(18)
        .background(AppColors.card)
        .clipShape(
            RoundedRectangle(cornerRadius: 20)
        )
        .shadow(
            color: AppColors.shadow,
            radius: 6,
            x: 0,
            y: 3
        )

    }

}
