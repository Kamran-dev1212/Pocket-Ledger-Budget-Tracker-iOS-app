import Foundation
import CloudKit

struct SharedGroup: Identifiable {

    let id: CKRecord.ID
    let name: String
    let createdAt: Date
    let record: CKRecord
    let database: CKDatabase

    init?(record: CKRecord, database: CKDatabase) {

        guard
            let name = record["name"] as? String,
            let createdAt = record["createdAt"] as? Date
        else {
            return nil
        }

        self.id = record.recordID
        self.name = name
        self.createdAt = createdAt
        self.record = record
        self.database = database

    }

}
