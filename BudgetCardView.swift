import SwiftUI

struct BudgetCardView: View {

    let budget: Budget
    let spent: Double
    var onEdit: () -> Void
    var onDelete: () -> Void

    @AppStorage("selectedCurrency") private var currency: String = "PKR"

    private var remaining: Double {
        max(0, budget.amount - spent)
    }

    private var progress: Double {
        budget.amount > 0 ? min(spent / budget.amount, 1.0) : 0
    }

    private var progressColor: Color {

        if progress < 0.6 {
            return AppColors.success
        } else if progress < 0.8 {
            return AppColors.warning
        } else {
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
                Spacer()

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

            }

            Divider()

            // MARK: Amounts

            VStack(spacing: 14) {

                HStack {

                    Text("Budget")
                        .foregroundStyle(AppColors.textSecondary)

                    Spacer()

                    Text("\(CurrencyManager.symbol(for: currency))\(Int(budget.amount).formatted())")
                        .fontWeight(.bold)

                }

                HStack {

                    Text("Spent")
                        .foregroundStyle(AppColors.textSecondary)

                    Spacer()

                    Text("\(CurrencyManager.symbol(for: currency))\(Int(spent).formatted())")
                        .fontWeight(.bold)
                        .foregroundStyle(AppColors.expense)

                }

                HStack {

                    Text("Remaining")
                        .foregroundStyle(AppColors.textSecondary)

                    Spacer()

                    Text("\(CurrencyManager.symbol(for: currency))\(Int(remaining).formatted())")
                        .fontWeight(.bold)
                        .foregroundStyle(AppColors.success)

                }

            }

            // MARK: Progress Bar

            ProgressView(value: progress)
                .tint(progressColor)

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

        let formatter = DateFormatter()

        return "\(formatter.monthSymbols[month - 1]) \(year)"

    }

    private func formatDate(_ date: Date) -> String {

        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"

        return formatter.string(from: date)

    }

}
