import Foundation
import CloudKit

struct GroupParticipant: Identifiable, Hashable {

    let id: String
    let displayName: String

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

    }

    var amountPerPerson: Double {

        guard !splitAmongUserRecordIDs.isEmpty else {
            return amount
        }

        return CurrencyManager.rounded(
            amount / Double(splitAmongUserRecordIDs.count)
        )

    }

}
