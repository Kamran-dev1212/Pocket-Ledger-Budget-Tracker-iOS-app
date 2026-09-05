import Foundation
import CloudKit

final class GroupSharingManager {

    static let shared = GroupSharingManager()

    private init() {}

    private let container = CKContainer(identifier: "iCloud.com.kamranzaidi.pocketledger")

    static let groupRecordType = "SharedGroup"
    static let expenseRecordType = "SharedExpense"

    // MARK: - Create a Group

    func createGroup(named name: String) async throws -> (share: CKShare, group: CKRecord) {

        let zoneID = CKRecordZone.ID(
            zoneName: "Group-\(UUID().uuidString)",
            ownerName: CKCurrentUserDefaultName
        )

        let zone = CKRecordZone(zoneID: zoneID)

        _ = try await container.privateCloudDatabase.save(zone)

        let groupRecordID = CKRecord.ID(
            recordName: UUID().uuidString,
            zoneID: zoneID
        )

        let groupRecord = CKRecord(
            recordType: Self.groupRecordType,
            recordID: groupRecordID
        )

        groupRecord["name"] = name as CKRecordValue
        groupRecord["createdAt"] = Date() as CKRecordValue

        let share = CKShare(rootRecord: groupRecord)
        share[CKShare.SystemFieldKey.title] = name as CKRecordValue

        let result = try await container.privateCloudDatabase.modifyRecords(
            saving: [groupRecord, share],
            deleting: []
        )

        for (_, saveResult) in result.saveResults {

            if case .failure(let error) = saveResult {
                throw error
            }

        }

        return (share, groupRecord)

    }

    // MARK: - Accept an Incoming Share

    func acceptShare(metadata: CKShare.Metadata) async throws {

        let operation = CKAcceptSharesOperation(shareMetadatas: [metadata])

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in

            operation.acceptSharesResultBlock = { result in

                switch result {

                case .success:
                    continuation.resume()

                case .failure(let error):
                    continuation.resume(throwing: error)

                }

            }

            container.add(operation)

        }

    }

    // MARK: - Fetch All Groups

    func fetchAllGroups() async throws -> [SharedGroup] {

        async let owned = fetchGroups(from: container.privateCloudDatabase)
        async let sharedWithMe = fetchGroups(from: container.sharedCloudDatabase)

        return try await owned + sharedWithMe

    }

    private func fetchGroups(from database: CKDatabase) async throws -> [SharedGroup] {

        let zones = try await database.allRecordZones()

        var allGroups: [SharedGroup] = []

        for zone in zones {

            let query = CKQuery(
                recordType: Self.groupRecordType,
                predicate: NSPredicate(value: true)
            )

            guard let (matchResults, _) = try? await database.records(
                matching: query,
                inZoneWith: zone.zoneID
            ) else {
                continue
            }

            for (_, result) in matchResults {

                if
                    case .success(let record) = result,
                    let group = SharedGroup(record: record, database: database)
                {
                    allGroups.append(group)
                }

            }

        }

        return allGroups

    }
    // MARK: - Rename a Group

    /// Groups only have one editable field. Mutating group.record's
    /// field directly is safe even though SharedGroup's own
    /// properties are immutable — CKRecord is a reference type, so
    /// this changes the same record object the rest of the app
    /// already holds a reference to.
    func renameGroup(_ group: SharedGroup, to newName: String) async throws {

        group.record["name"] = newName as CKRecordValue

        _ = try await group.database.save(group.record)

    }
    // MARK: - Delete a Group

    /// Deletes the group's entire zone, not just its record. Since
    /// the group's record, its CKShare, and every expense inside it
    /// all live in that one custom zone, deleting the zone removes
    /// all of it in a single step and revokes every participant's
    /// access at the same time.
    ///
    /// This only succeeds for the zone's actual owner. If a group
    /// was shared TO you rather than created by you, this will fail
    /// with a permissions error — deleting someone else's group
    /// isn't something a participant is allowed to do.
    func deleteGroup(_ group: SharedGroup) async throws {

        _ = try await group.database.deleteRecordZone(
            withID: group.record.recordID.zoneID
        )

    }

    // MARK: - Participants

    func fetchParticipants(for group: SharedGroup) async throws -> [GroupParticipant] {

        guard let share = try await fetchShare(for: group) else {
            return []
        }

        return share.participants.compactMap { participant in

            guard let userRecordID = participant.userIdentity.userRecordID else {
                return nil
            }

            let resolvedName = participant.userIdentity.nameComponents
                .flatMap { PersonNameComponentsFormatter().string(from: $0) }

            let displayName = (resolvedName?.isEmpty == false ? resolvedName : nil)
                ?? participant.userIdentity.lookupInfo?.emailAddress
                ?? "Member"

            return GroupParticipant(
                id: userRecordID.recordName,
                displayName: displayName
            )

        }

    }

    private func fetchShare(for group: SharedGroup) async throws -> CKShare? {

        guard let shareReference = group.record.share else {
            return nil
        }

        let shareRecord = try await group.database.record(for: shareReference.recordID)

        return shareRecord as? CKShare

    }

    // MARK: - Add an Expense

    func addExpense(
        title: String,
        amount: Double,
        paidBy: GroupParticipant,
        splitAmong: [GroupParticipant],
        in group: SharedGroup
    ) async throws {

        let expenseRecordID = CKRecord.ID(
            recordName: UUID().uuidString,
            zoneID: group.record.recordID.zoneID
        )

        let expenseRecord = CKRecord(
            recordType: Self.expenseRecordType,
            recordID: expenseRecordID
        )

        expenseRecord["title"] = title as CKRecordValue
        expenseRecord["amount"] = amount as CKRecordValue
        expenseRecord["paidByUserRecordID"] = paidBy.id as CKRecordValue
        expenseRecord["paidByDisplayName"] = paidBy.displayName as CKRecordValue
        expenseRecord["splitAmongUserRecordIDs"] = splitAmong.map(\.id) as CKRecordValue
        expenseRecord["date"] = Date() as CKRecordValue

        let result = try await group.database.modifyRecords(
            saving: [expenseRecord],
            deleting: []
        )

        for (_, saveResult) in result.saveResults {

            if case .failure(let error) = saveResult {
                throw error
            }

        }

    }

    // MARK: - Fetch Expenses

    func fetchExpenses(for group: SharedGroup) async throws -> [SharedExpense] {

        let query = CKQuery(
            recordType: Self.expenseRecordType,
            predicate: NSPredicate(value: true)
        )

        let (matchResults, _) = try await group.database.records(
            matching: query,
            inZoneWith: group.record.recordID.zoneID
        )

        var expenses: [SharedExpense] = []

        for (_, result) in matchResults {

            if
                case .success(let record) = result,
                let expense = SharedExpense(record: record)
            {
                expenses.append(expense)
            }

        }

        return expenses.sorted { $0.date > $1.date }

    }

}
