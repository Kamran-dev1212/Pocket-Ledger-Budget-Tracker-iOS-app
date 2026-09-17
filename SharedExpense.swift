import Foundation
import CloudKit

struct GroupParticipant: Identifiable, Hashable {

    /// Preferred stable identifier. A CloudKit user record name once the
    /// person has accepted; before that, their invited email/phone.
    let id: String

    let displayName: String

    /// Every other identifier this same person may have been recorded
    /// under. An expense saved while they were still "invited" stores the
    /// email-based id, so after they accept we still need to recognise it.
    let alternateIDs: [String]

    let isCurrentUser: Bool

    var allIDs: [String] {
        [id] + alternateIDs
    }

}

struct SharedExpense: Identifiable {

    let id: CKRecord.ID
    let title: String
    let amount: Double
    let paidByUserRecordID: String
    let paidByDisplayName: String
    let splitAmongUserRecordIDs: [String]
    let date: Date
    let record: CKRecord

    /// A repayment rather than a shared cost. Stored as an expense so the
    /// balance maths works unchanged — the payer is credited the amount
    /// and the payee alone is debited it, which cancels the debt — but
    /// kept out of "total spent" and shown separately.
    let isSettlement: Bool

    init?(record: CKRecord) {

        guard
            let title = record["title"] as? String,
            let amount = record["amount"] as? Double,
            let paidByUserRecordID = record["paidByUserRecordID"] as? String,
            let paidByDisplayName = record["paidByDisplayName"] as? String,
            let splitAmongUserRecordIDs = record["splitAmongUserRecordIDs"] as? [String],
            let date = record["date"] as? Date
        else {
            return nil
        }

        self.id = record.recordID
        self.title = title
        self.amount = amount
        self.paidByUserRecordID = paidByUserRecordID
        self.paidByDisplayName = paidByDisplayName
        self.splitAmongUserRecordIDs = splitAmongUserRecordIDs
        self.date = date
        self.record = record

        // Absent on every expense saved before settlements existed, which
        // correctly reads as false.
        let flag = (record["isSettlement"] as? Int64)
            ?? Int64((record["isSettlement"] as? Int) ?? 0)

        self.isSettlement = flag == 1

    }

    /// Who received the money, for a settlement.
    var settlementPayeeID: String? {

        isSettlement ? splitAmongUserRecordIDs.first : nil

    }

    /// Display only. The authoritative split lives in
    /// SettlementCalculator, which distributes the rounding remainder so
    /// the shares always add back up to the full amount.
    var amountPerPerson: Double {

        guard !splitAmongUserRecordIDs.isEmpty else {
            return amount
        }

        return CurrencyManager.rounded(
            amount / Double(splitAmongUserRecordIDs.count)
        )

    }

}
