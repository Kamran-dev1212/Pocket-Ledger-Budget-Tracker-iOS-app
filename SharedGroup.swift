import Foundation
import CloudKit

struct SharedGroup: Identifiable {

    let id: CKRecord.ID
    let name: String
    let createdAt: Date
    let record: CKRecord
    let database: CKDatabase

    /// A zone in the current user's own private database carries the
    /// placeholder owner name; a zone reached through the shared database
    /// carries the real owner's record name. So this is true only for the
    /// person who created the group.
    var isOwnedByCurrentUser: Bool {

        record.recordID.zoneID.ownerName == CKCurrentUserDefaultName

    }

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
