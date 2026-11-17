
import SwiftUI
import SwiftData

struct TransactionDetailView: View {

    // MARK: - Environment

    @Environment(\.dismiss)
    private var dismiss

    // MARK: - Transaction

    let transaction: Transaction

    // MARK: - Data

    @Query
    private var userCategories: [UserCategory]

    @AppStorage("selectedCurrency")
    private var currency: String = "USD"

    // MARK: - State

    @State private var showEdit = false

    // MARK: - Computed Properties

    private var isIncome: Bool {
        transaction.type == "Income"
    }

    private var accentColor: Color {
        isIncome
            ? AppColors.success
            : AppColors.expense
    }

    private var transactionIcon: String {
        TransactionIcon.icon(
            for: transaction.category,
            type: transaction.type,
            in: userCategories
        )
    }

    private static let dateFormatter: DateFormatter = {

        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM yyyy"

        return formatter
    }()

    private static let timeFormatter: DateFormatter = {

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        return formatter
    }()

    // MARK: - Body

    var body: some View {

        NavigationStack {

            ZStack {

                AppColors.dashboardGradient
                    .ignoresSafeArea()

                VStack(spacing: 0) {

                    topHeader

                    ScrollView {

                        VStack(spacing: 20) {

                            transactionSummaryCard

                            transactionInformationCard

                            editTransactionButton

                            footerSection
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 24)
                        .padding(.bottom, 36)
                    }
                    .background(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 28,
                            topTrailingRadius: 28
                        )
                        .fill(AppColors.dashboardSurface)
                        .ignoresSafeArea(edges: .bottom)
                    )
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showEdit) {

                AddTransactionView(
                    transaction: transaction
                )
            }
        }
    }

    // MARK: - Purple Header

    private var topHeader: some View {

        VStack(
            alignment: .leading,
            spacing: 24
        ) {

            HStack {

                Button {
                    dismiss()
                } label: {

                    Text("Done")
                        .font(.system(
                            size: 16,
                            weight: .semibold
                        ))
                        .foregroundStyle(.white)
                }

                Spacer()

                Text("Transaction")
                    .font(.system(
                        size: 17,
                        weight: .semibold
                    ))
                    .foregroundStyle(.white)

                Spacer()

                Text("Done")
                    .font(.system(
                        size: 16,
                        weight: .semibold
                    ))
                    .hidden()
            }

            VStack(
                alignment: .leading,
                spacing: 8
            ) {

                Text("Transaction Details")
                    .font(.system(
                        size: 27,
                        weight: .bold
                    ))
                    .foregroundStyle(.white)

                Text("Review your transaction information")
                    .font(.system(size: 14))
                    .foregroundStyle(
                        .white.opacity(0.85)
                    )
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 14)
        .padding(.bottom, 28)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    // MARK: - Transaction Summary

    private var transactionSummaryCard: some View {

        VStack(spacing: 16) {

            Image(systemName: transactionIcon)
                .font(.system(
                    size: 34,
                    weight: .semibold
                ))
                .foregroundStyle(accentColor)
                .frame(
                    width: 84,
                    height: 84
                )
                .background(
                    accentColor.opacity(0.10),
                    in: Circle()
                )

            Text(transaction.title)
                .font(.system(
                    size: 20,
                    weight: .semibold
                ))
                .foregroundStyle(
                    AppColors.textPrimary
                )
                .multilineTextAlignment(.center)

            Text(
                CurrencyManager.string(
                    for: transaction.amount,
                    currencyCode: currency,
                    forcedSign: isIncome ? "+" : "-"
                )
            )
            .font(.system(
                size: 34,
                weight: .bold
            ))
            .monospacedDigit()
            .foregroundStyle(accentColor)
            .lineLimit(1)
            .minimumScaleFactor(0.6)

            Text(transaction.type)
                .font(.system(
                    size: 13,
                    weight: .semibold
                ))
                .foregroundStyle(accentColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    accentColor.opacity(0.10),
                    in: Capsule()
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 28)
        .background(
            AppColors.card,
            in: RoundedRectangle(
                cornerRadius: 22
            )
        )
    }

    // MARK: - Transaction Information

    private var transactionInformationCard: some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            HStack(spacing: 12) {

                Image(systemName: "doc.text.fill")
                    .font(.system(size: 17))
                    .foregroundStyle(
                        AppColors.dashboardPurple
                    )
                    .frame(
                        width: 38,
                        height: 38
                    )
                    .background(
                        AppColors.dashboardPurple.opacity(0.10),
                        in: RoundedRectangle(
                            cornerRadius: 11
                        )
                    )

                Text("Transaction Information")
                    .font(.system(
                        size: 17,
                        weight: .semibold
                    ))
                    .foregroundStyle(
                        AppColors.textPrimary
                    )
            }

            detailRow(
                label: "Category",
                value: transaction.category
            )

            Divider()
                .overlay(AppColors.divider)

            detailRow(
                label: "Date",
                value: Self.dateFormatter.string(
                    from: transaction.date
                )
            )

            Divider()
                .overlay(AppColors.divider)

            detailRow(
                label: "Time",
                value: Self.timeFormatter.string(
                    from: transaction.date
                )
            )
        }
        .padding(20)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            AppColors.card,
            in: RoundedRectangle(
                cornerRadius: 22
            )
        )
    }

    // MARK: - Detail Row

    private func detailRow(
        label: String,
        value: String
    ) -> some View {

        HStack(
            alignment: .top,
            spacing: 16
        ) {

            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(
                    AppColors.textSecondary
                )

            Spacer(minLength: 8)

            Text(value)
                .font(.system(
                    size: 14,
                    weight: .medium
                ))
                .foregroundStyle(
                    AppColors.textPrimary
                )
                .multilineTextAlignment(.trailing)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
        }
        .padding(.vertical, 4)
    }

    // MARK: - Edit Transaction

    private var editTransactionButton: some View {

        Button {

            showEdit = true

        } label: {

            HStack(spacing: 10) {

                Image(systemName: "pencil")
                    .font(.system(
                        size: 17,
                        weight: .semibold
                    ))

                Text("Edit Transaction")
                    .font(.system(
                        size: 16,
                        weight: .semibold
                    ))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                AppColors.dashboardPurple,
                in: RoundedRectangle(
                    cornerRadius: 16
                )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Footer

    private var footerSection: some View {

        Text("Pocket Ledger: Budget Tracker")
            .font(.system(size: 12))
            .foregroundStyle(
                AppColors.textSecondary
            )
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
    }
}

// MARK: - Preview

#Preview {

    Text("Transaction Detail Preview")
}
