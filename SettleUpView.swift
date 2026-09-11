import SwiftUI

struct SettleUpView: View {

    let group: SharedGroup

    @State private var expenses: [SharedExpense] = []
    @State private var participants: [GroupParticipant] = []
    @State private var balances: [Balance] = []
    @State private var payments: [SettlementPayment] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false

    @AppStorage("selectedCurrency") private var currency: String = "PKR"

    // MARK: - Derived

    private struct PayerGroup: Identifiable {

        let id: String
        let name: String
        let total: Double
        let expenses: [SharedExpense]

    }

    private var total: Double {

        expenses.reduce(0) { $0 + $1.amount }

    }

    private var perPersonShare: Double {

        guard !participants.isEmpty else { return 0 }

        return CurrencyManager.rounded(total / Double(participants.count))

    }

    /// Every expense grouped under whoever paid it, oldest first.
    private var payerGroups: [PayerGroup] {

        let resolver = ParticipantResolver(participants: participants)

        var expensesByPayer: [String: [SharedExpense]] = [:]
        var order: [String] = []

        for expense in expenses.sorted(by: { $0.date < $1.date }) {

            let payerID = resolver.id(for: expense.paidByUserRecordID)

            if expensesByPayer[payerID] == nil {
                order.append(payerID)
            }

            expensesByPayer[payerID, default: []].append(expense)

        }

        return order.map { payerID in

            let items = expensesByPayer[payerID] ?? []

            return PayerGroup(
                id: payerID,
                name: resolver.name(
                    for: payerID,
                    storedName: items.first?.paidByDisplayName
                ),
                total: items.reduce(0) { $0 + $1.amount },
                expenses: items
            )

        }

    }

    // MARK: - Body

    var body: some View {

        ZStack {

            AppColors.background
                .ignoresSafeArea()

            if isLoading {

                ProgressView()

            } else if expenses.isEmpty {

                Text("No expenses to settle yet.")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)

            } else {

                List {

                    // MARK: Summary

                    Section("Summary") {

                        summaryRow(
                            "Total spent",
                            value: total,
                            bold: true
                        )

                        summaryRow(
                            "Each person's share",
                            value: perPersonShare
                        )

                        HStack {

                            Text("Members")
                                .font(.subheadline)
                                .foregroundStyle(AppColors.textSecondary)

                            Spacer()

                            Text("\(participants.count)")
                                .font(.subheadline)
                                .foregroundStyle(AppColors.textSecondary)

                        }

                    }

                    // MARK: Every expense, grouped by who paid

                    ForEach(payerGroups) { payerGroup in

                        Section {

                            ForEach(payerGroup.expenses) { expense in

                                HStack(alignment: .firstTextBaseline) {

                                    VStack(alignment: .leading, spacing: 2) {

                                        Text(expense.title)
                                            .font(.subheadline)
                                            .foregroundStyle(AppColors.textPrimary)

                                        Text(expense.date, style: .date)
                                            .font(.caption)
                                            .foregroundStyle(AppColors.textSecondary)

                                    }

                                    Spacer()

                                    Text(
                                        CurrencyManager.string(
                                            for: expense.amount,
                                            currencyCode: currency
                                        )
                                    )
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(AppColors.textPrimary)

                                }
                                .padding(.vertical, 2)

                            }

                        } header: {

                            HStack {

                                Text("\(payerGroup.name) paid")

                                Spacer()

                                Text(
                                    CurrencyManager.string(
                                        for: payerGroup.total,
                                        currencyCode: currency
                                    )
                                )

                            }

                        }

                    }

                    // MARK: Balances

                    Section("Balances") {

                        ForEach(balances, id: \.participantID) { balance in

                            HStack {

                                Text(balance.displayName)
                                    .font(.subheadline)
                                    .foregroundStyle(AppColors.textPrimary)

                                Spacer()

                                Text(balanceLabel(for: balance))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(
                                        balance.netAmount >= 0
                                            ? AppColors.success
                                            : AppColors.expense
                                    )

                            }
                            .padding(.vertical, 2)

                        }

                    }

                    // MARK: Settlement

                    Section("Who Owes Whom") {

                        if payments.isEmpty {

                            Text("Everyone is settled up.")
                                .font(.subheadline)
                                .foregroundStyle(AppColors.textSecondary)

                        } else {

                            ForEach(payments.indices, id: \.self) { index in

                                let payment = payments[index]

                                HStack {

                                    Text(settlementLine(for: payment))
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(AppColors.textPrimary)

                                    Spacer()

                                    Text(
                                        CurrencyManager.string(
                                            for: payment.amount,
                                            currencyCode: currency
                                        )
                                    )
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(AppColors.primary)

                                }
                                .padding(.vertical, 4)

                            }

                        }

                    }

                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .refreshable {

                    await load(showSpinner: false)

                }

            }

        }
        .navigationTitle("Full Breakdown")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await load()
        }
        .alert("Error", isPresented: $showError) {

            Button("OK", role: .cancel) { }

        } message: {

            Text(errorMessage)

        }

    }

    // MARK: - Rows

    private func summaryRow(
        _ title: String,
        value: Double,
        bold: Bool = false
    ) -> some View {

        HStack {

            Text(title)
                .font(bold ? .headline : .subheadline)
                .foregroundStyle(
                    bold ? AppColors.textPrimary : AppColors.textSecondary
                )

            Spacer()

            Text(
                CurrencyManager.string(
                    for: value,
                    currencyCode: currency
                )
            )
            .font(bold ? .headline : .subheadline)
            .fontWeight(bold ? .bold : .semibold)
            .foregroundStyle(AppColors.textPrimary)

        }

    }

    private func balanceLabel(for balance: Balance) -> String {

        let amountString = CurrencyManager.string(
            for: abs(balance.netAmount),
            currencyCode: currency
        )

        if balance.netAmount > 0.005 {

            return balance.isCurrentUser
                ? "you are owed \(amountString)"
                : "is owed \(amountString)"

        } else if balance.netAmount < -0.005 {

            return balance.isCurrentUser
                ? "you owe \(amountString)"
                : "owes \(amountString)"

        } else {

            return "settled up"

        }

    }

    private func settlementLine(for payment: SettlementPayment) -> String {

        let verb = payment.fromName == "You" ? "owe" : "owes"

        return "\(payment.fromName) \(verb) \(payment.toName)"

    }

    // MARK: - Load

    private func load(showSpinner: Bool = true) async {

        if showSpinner {
            isLoading = true
        }

        do {

            async let fetchedExpenses =
                GroupSharingManager.shared.fetchExpenses(for: group)

            async let fetchedParticipants =
                GroupSharingManager.shared.fetchParticipants(for: group)

            let (loadedExpenses, loadedParticipants) =
                try await (fetchedExpenses, fetchedParticipants)

            let calculatedBalances = SettlementCalculator.balances(
                for: loadedExpenses,
                participants: loadedParticipants
            )

            expenses = loadedExpenses
            participants = loadedParticipants
            balances = calculatedBalances
            payments = SettlementCalculator.settlementPlan(
                from: calculatedBalances
            )

        } catch {

            errorMessage = error.localizedDescription
            showError = true

        }

        if showSpinner {
            isLoading = false
        }

    }

}
