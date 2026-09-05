import Foundation

struct Balance {

    let participantID: String
    let displayName: String
    let netAmount: Double

}

struct SettlementPayment {

    let fromID: String
    let fromName: String
    let toID: String
    let toName: String
    let amount: Double

}

struct SettlementCalculator {

    static func balances(
        for expenses: [SharedExpense],
        participants: [GroupParticipant]
    ) -> [Balance] {

        var netByID: [String: Double] = [:]

        for participant in participants {
            netByID[participant.id] = 0
        }

        for expense in expenses {

            netByID[expense.paidByUserRecordID, default: 0] += expense.amount

            let share = expense.amountPerPerson

            for participantID in expense.splitAmongUserRecordIDs {
                netByID[participantID, default: 0] -= share
            }

        }

        return participants.map { participant in

            Balance(
                participantID: participant.id,
                displayName: participant.displayName,
                netAmount: CurrencyManager.rounded(netByID[participant.id] ?? 0)
            )

        }

    }

    static func settlementPlan(from balances: [Balance]) -> [SettlementPayment] {

        var creditors = balances
            .filter { $0.netAmount > 0.01 }
            .sorted { $0.netAmount > $1.netAmount }

        var debtors = balances
            .filter { $0.netAmount < -0.01 }
            .sorted { $0.netAmount < $1.netAmount }

        var payments: [SettlementPayment] = []

        var creditorIndex = 0
        var debtorIndex = 0

        while creditorIndex < creditors.count && debtorIndex < debtors.count {

            let creditor = creditors[creditorIndex]
            let debtor = debtors[debtorIndex]

            let amount = CurrencyManager.rounded(
                min(creditor.netAmount, -debtor.netAmount)
            )

            if amount > 0 {

                payments.append(
                    SettlementPayment(
                        fromID: debtor.participantID,
                        fromName: debtor.displayName,
                        toID: creditor.participantID,
                        toName: creditor.displayName,
                        amount: amount
                    )
                )

            }

            creditors[creditorIndex] = Balance(
                participantID: creditor.participantID,
                displayName: creditor.displayName,
                netAmount: CurrencyManager.rounded(creditor.netAmount - amount)
            )

            debtors[debtorIndex] = Balance(
                participantID: debtor.participantID,
                displayName: debtor.displayName,
                netAmount: CurrencyManager.rounded(debtor.netAmount + amount)
            )

            if creditors[creditorIndex].netAmount < 0.01 {
                creditorIndex += 1
            }

            if debtors[debtorIndex].netAmount > -0.01 {
                debtorIndex += 1
            }

        }

        return payments

    }

}
