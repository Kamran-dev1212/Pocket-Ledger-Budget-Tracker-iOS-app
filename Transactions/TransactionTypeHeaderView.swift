import SwiftUI

// MARK: - Reusable premium page header (large title + subtitle)
// Used by IncomeView and ExpenseView so both share one definition.

struct TransactionTypeHeaderView: View {

    let title: String
    let subtitle: String

    var body: some View {

        VStack(alignment: .leading, spacing: 5) {

            Text(title)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)

        }
        .frame(maxWidth: .infinity, alignment: .leading)

    }

}

#Preview {

    ZStack {

        AppColors.background
            .ignoresSafeArea()

        TransactionTypeHeaderView(
            title: "Income",
            subtitle: "Track your earnings"
        )
        .padding()

    }

}
