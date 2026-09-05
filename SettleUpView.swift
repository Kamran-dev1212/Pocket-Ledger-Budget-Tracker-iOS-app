import SwiftUI

struct SettleUpView: View {

    let group: SharedGroup

    @State private var balances: [Balance] = []
    @State private var payments: [SettlementPayment] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false

    @AppStorage("selectedCurrency") private var currency: String = "PKR"

    var body: some View {

        ZStack {

            AppColors.background
                .ignoresSafeArea()

            if isLoading {

                ProgressView()

            } else {

                List {

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

                    Section("Settle Up") {

                        if payments.isEmpty {

                            Text("Everyone is settled up.")
                                .font(.subheadline)
                                .foregroundStyle(AppColors.textSecondary)

                        } else {

                            ForEach(payments.indices, id: \.self) { index in

                                let payment = payments[index]

                                HStack {

                                    Text("\(payment.fromName) → \(payment.toName)")
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

            }

        }
        .navigationTitle("Settle Up")
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

    private func balanceLabel(for balance: Balance) -> String {

        let amountString = CurrencyManager.string(
            for: abs(balance.netAmount),
            currencyCode: currency
        )

        if balance.netAmount > 0.01 {
            return "is owed \(amountString)"
        } else if balance.netAmount < -0.01 {
            return "owes \(amountString)"
        } else {
            return "settled up"
        }

    }

    private func load() async {

        isLoading = true

        do {

            let participants = try await GroupSharingManager.shared.fetchParticipants(for: group)
            let expenses = try await GroupSharingManager.shared.fetchExpenses(for: group)

            balances = SettlementCalculator.balances(for: expenses, participants: participants)
            payments = SettlementCalculator.settlementPlan(from: balances)

        } catch {

            errorMessage = error.localizedDescription
            showError = true

        }

        isLoading = false

    }

}
