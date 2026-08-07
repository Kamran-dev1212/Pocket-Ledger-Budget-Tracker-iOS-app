import SwiftUI

struct BudgetCardView: View {

    let budget: Budget
    let spent: Double
    var onEdit: () -> Void
    var onDelete: () -> Void

    @AppStorage("selectedCurrency") private var currency: String = "PKR"

    // MARK: - Derived Values
    //
    // All of these now come from BudgetMath so this card and the
    // Dashboard's Budget Performance counts can't disagree.

    private var status: BudgetStatus {

        BudgetMath.status(
            spent: spent,
            budgetAmount: budget.amount
        )

    }

    /// Signed. Negative when overspent.
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

    /// Clamped for the bar itself.
    private var progress: Double {

        BudgetMath.clampedProgress(
            spent: spent,
            budgetAmount: budget.amount
        )

    }

    /// Uncapped, for the percentage label — shows 130% when overspent.
    private var progressPercent: Int {

        Int(
            (
                BudgetMath.progress(
                    spent: spent,
                    budgetAmount: budget.amount
                )
                * 100
            )
            .rounded()
        )

    }

    // MARK: - Status Colour
    //
    // The colour mapping lives here rather than on BudgetStatus so
    // that Budget.swift stays free of any SwiftUI dependency.

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

    var body: some View {

        VStack(alignment: .leading, spacing: 18) {

            // MARK: Title

            HStack {

                Text(budget.category)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(CategoryManager.color(for: budget.category))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer()

                // MARK: Status Pill

                Text(status.label)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(statusColor.opacity(0.12))
                    .clipShape(Capsule())

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

                    Image(systemName: "ellipsis.circle.fill")
                        .font(.title2)
                        .foregroundStyle(AppColors.textSecondary)

                }
                .accessibilityLabel("Budget options")

            }

            Divider()

            // MARK: Amounts

            VStack(spacing: 14) {

                HStack {

                    Text("Budget")
                        .foregroundStyle(AppColors.textSecondary)

                    Spacer()

                    Text(
                        CurrencyManager.string(
                            for: budget.amount,
                            currencyCode: currency
                        )
                    )
                    .fontWeight(.bold)
                    .monospacedDigit()

                }

                HStack {

                    Text("Spent")
                        .foregroundStyle(AppColors.textSecondary)

                    Spacer()

                    Text(
                        CurrencyManager.string(
                            for: spent,
                            currencyCode: currency
                        )
                    )
                    .fontWeight(.bold)
                    .monospacedDigit()
                    .foregroundStyle(AppColors.expense)

                }

                // MARK: Remaining / Over Budget
                //
                // Previously this always read "Remaining" and was
                // clamped at zero, so overspending was invisible.

                HStack {

                    Text(
                        remaining < 0
                        ? "Over Budget"
                        : "Remaining"
                    )
                    .foregroundStyle(AppColors.textSecondary)

                    Spacer()

                    Text(
                        CurrencyManager.string(
                            for: remaining < 0 ? overspend : remaining,
                            currencyCode: currency
                        )
                    )
                    .fontWeight(.bold)
                    .monospacedDigit()
                    .foregroundStyle(
                        remaining < 0
                        ? AppColors.danger
                        : AppColors.success
                    )

                }

            }

            // MARK: Progress Bar

            VStack(alignment: .leading, spacing: 6) {

                ProgressView(value: progress)
                    .tint(statusColor)

                Text("\(progressPercent)% of budget used")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)

            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Budget progress")
            .accessibilityValue(
                "\(progressPercent) percent used, \(status.label)"
            )

            Divider()

            // MARK: Budget Period

            VStack(alignment: .leading, spacing: 6) {

                Label("Budget Period", systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)

                Text(formattedMonthYear(month: budget.month, year: budget.year))
                    .font(.headline)

            }

            Divider()

            // MARK: Created Date

            VStack(alignment: .leading, spacing: 6) {

                Label("Created", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)

                Text(formatDate(budget.dateCreated))
                    .font(.headline)

            }

        }
        .padding()
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(
            color: AppColors.shadow,
            radius: 6,
            x: 0,
            y: 4
        )

    }

    // MARK: - Helper Functions

    private func formattedMonthYear(month: Int, year: Int) -> String {

        // Guarded: an out-of-range month would crash on subscript.
        // Nothing writes one today, but this is a hard crash if it
        // ever happens, and the guard costs nothing.

        let symbols = Calendar.current.monthSymbols

        guard month >= 1, month <= symbols.count else {
            return String(year)
        }

        return "\(symbols[month - 1]) \(year)"

    }

    private func formatDate(_ date: Date) -> String {

        date.formatted(date: .abbreviated, time: .omitted)

    }

}

#Preview {

    ZStack {

        AppColors.background
            .ignoresSafeArea()

        ScrollView {

            VStack(spacing: 18) {

                BudgetCardView(
                    budget: Budget(
                        category: "Food",
                        amount: 20000,
                        month: 8,
                        year: 2026
                    ),
                    spent: 9500,
                    onEdit: {},
                    onDelete: {}
                )

                BudgetCardView(
                    budget: Budget(
                        category: "Transport",
                        amount: 10000,
                        month: 8,
                        year: 2026
                    ),
                    spent: 8600,
                    onEdit: {},
                    onDelete: {}
                )

                BudgetCardView(
                    budget: Budget(
                        category: "Shopping",
                        amount: 15000,
                        month: 8,
                        year: 2026
                    ),
                    spent: 19500.75,
                    onEdit: {},
                    onDelete: {}
                )

            }
            .padding()

        }

    }

}
