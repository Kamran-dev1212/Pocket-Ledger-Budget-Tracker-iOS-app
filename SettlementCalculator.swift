import Foundation

struct Balance {

    let participantID: String
    let displayName: String
    let netAmount: Double
    let isCurrentUser: Bool

}

struct SettlementPayment {

    let fromID: String
    let fromName: String
    let toID: String
    let toName: String
    let amount: Double

}

/// Maps whatever identifier is stored in an expense record back to the
/// person it belongs to. An expense saved while someone was still
/// "invited" stores their email/phone, so this has to look through
/// aliases as well as primary ids.
struct ParticipantResolver {

    private let canonicalID: [String: String]
    private let nameByID: [String: String]

    init(participants: [GroupParticipant]) {

        var canonicalID: [String: String] = [:]
        var nameByID: [String: String] = [:]

        for participant in participants {

            for identifier in participant.allIDs {
                canonicalID[identifier] = participant.id
            }

            nameByID[participant.id] = participant.displayName

        }

        self.canonicalID = canonicalID
        self.nameByID = nameByID

    }

    func id(for rawID: String) -> String {

        canonicalID[rawID] ?? rawID

    }

    /// `storedName` is the name saved into the record on whichever device
    /// created it — so it can literally be the string "You", which means
    /// somebody else on this phone. Only used when the person is no longer
    /// in the group.
    func name(for rawID: String, storedName: String? = nil) -> String {

        if let name = nameByID[id(for: rawID)] {
            return name
        }

        if let storedName, storedName != "You", !storedName.isEmpty {
            return storedName
        }

        return "Former member"

    }

}

struct SettlementCalculator {

    // MARK: - Balances

    static func balances(
        for expenses: [SharedExpense],
        participants: [GroupParticipant]
    ) -> [Balance] {

        let resolver = ParticipantResolver(participants: participants)

        var nameByID: [String: String] = [:]
        var currentUserIDs: Set<String> = []
        var order: [String] = []
        var netByID: [String: Double] = [:]

        for participant in participants {

            nameByID[participant.id] = participant.displayName
            netByID[participant.id] = 0
            order.append(participant.id)

            if participant.isCurrentUser {
                currentUserIDs.insert(participant.id)
            }

        }

        // Someone who paid or was split with but has since left the group.
        // Without this their money vanishes and balances stop netting to
        // zero.
        func register(_ id: String, fallbackName: String) {

            guard netByID[id] == nil else { return }

            netByID[id] = 0
            nameByID[id] = fallbackName
            order.append(id)

        }

        for expense in expenses {

            let payerID = resolver.id(for: expense.paidByUserRecordID)

            register(
                payerID,
                fallbackName: resolver.name(
                    for: expense.paidByUserRecordID,
                    storedName: expense.paidByDisplayName
                )
            )

            netByID[payerID, default: 0] += expense.amount

            var seen: Set<String> = []

            let splitIDs = expense.splitAmongUserRecordIDs
                .map { resolver.id(for: $0) }
                .filter { seen.insert($0).inserted }

            guard !splitIDs.isEmpty else { continue }

            let shares = shares(of: expense.amount, among: splitIDs.count)

            for (index, id) in splitIDs.enumerated() {

                register(id, fallbackName: "Former member")

                netByID[id, default: 0] -= shares[index]

            }

        }

        return order.map { id in

            Balance(
                participantID: id,
                displayName: nameByID[id] ?? "Member",
                netAmount: CurrencyManager.rounded(netByID[id] ?? 0),
                isCurrentUser: currentUserIDs.contains(id)
            )

        }

    }

    // MARK: - Splitting

    /// Splits an amount into `count` shares that add back up to exactly
    /// the original. 1000 across 3 gives 333.34 / 333.33 / 333.33.
    private static func shares(of amount: Double, among count: Int) -> [Double] {

        guard count > 0 else { return [] }

        let totalUnits = (amount * 100).rounded()
        let baseUnits = (totalUnits / Double(count)).rounded(.down)

        var remainder = Int(totalUnits - baseUnits * Double(count))

        return (0 ..< count).map { _ -> Double in

            var units = baseUnits

            if remainder > 0 {
                units += 1
                remainder -= 1
            }

            return units / 100

        }

    }

    // MARK: - Who Pays Whom

    static func settlementPlan(from balances: [Balance]) -> [SettlementPayment] {

        var creditors = balances
            .filter { $0.netAmount > 0.005 }
            .sorted { $0.netAmount > $1.netAmount }

        var debtors = balances
            .filter { $0.netAmount < -0.005 }
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

            guard amount > 0 else { break }

            payments.append(
                SettlementPayment(
                    fromID: debtor.participantID,
                    fromName: debtor.displayName,
                    toID: creditor.participantID,
                    toName: creditor.displayName,
                    amount: amount
                )
            )

            creditors[creditorIndex] = Balance(
                participantID: creditor.participantID,
                displayName: creditor.displayName,
                netAmount: CurrencyManager.rounded(creditor.netAmount - amount),
                isCurrentUser: creditor.isCurrentUser
            )

            debtors[debtorIndex] = Balance(
                participantID: debtor.participantID,
                displayName: debtor.displayName,
                netAmount: CurrencyManager.rounded(debtor.netAmount + amount),
                isCurrentUser: debtor.isCurrentUser
            )

            if creditors[creditorIndex].netAmount <= 0.005 {
                creditorIndex += 1
            }

            if debtors[debtorIndex].netAmount >= -0.005 {
                debtorIndex += 1
            }

        }

        return payments

    }

}
