import Foundation
import CloudKit

final class GroupSharingManager {

    static let shared = GroupSharingManager()

    private init() {}

    private let container = CKContainer(identifier: "iCloud.com.kamranzaidi.pocketledger")

    static let groupRecordType = "SharedGroup"
    static let expenseRecordType = "SharedExpense"

    /// CloudKit reports the current user's record name as
    /// "__defaultOwner__" on their own device — a placeholder meaning
    /// "me", which therefore resolves to a DIFFERENT person on every
    /// phone. It must never be stored in a record or compared across
    /// devices, so it is swapped for the account's real record name.
    private var cachedUserRecordName: String?

    // MARK: - Groups

    func createGroup(named name: String) async throws -> SharedGroup {

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

        // Invite-only by default. The owner can switch this on per group
        // from the Members screen if they want an open link.
        share.publicPermission = .none

        let result = try await container.privateCloudDatabase.modifyRecords(
            saving: [groupRecord, share],
            deleting: []
        )

        var savedGroupRecord: CKRecord?

        for (recordID, saveResult) in result.saveResults {

            switch saveResult {

            case .failure(let error):
                throw error

            case .success(let record):

                if recordID == groupRecordID {
                    savedGroupRecord = record
                }

            }

        }

        // The server copy is the one that carries the share reference —
        // the local copy doesn't, and would look like an unshared group.
        guard
            let savedGroupRecord,
            let sharedGroup = SharedGroup(
                record: savedGroupRecord,
                database: container.privateCloudDatabase
            )
        else {

            throw NSError(
                domain: "GroupSharing",
                code: -4,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "The group was created but couldn't be read back."
                ]
            )

        }

        return sharedGroup

    }

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

    func fetchAllGroups() async throws -> [SharedGroup] {

        async let owned = fetchGroups(from: container.privateCloudDatabase)
        async let sharedWithMe = fetchGroups(from: container.sharedCloudDatabase)

        return try await owned + sharedWithMe

    }

    private func fetchGroups(from database: CKDatabase) async throws -> [SharedGroup] {

        let zones = try await database.allRecordZones()

        let groupZones = zones.filter {
            $0.zoneID.zoneName.hasPrefix("Group-")
        }

        return await withTaskGroup(of: [SharedGroup].self) { taskGroup in

            for zone in groupZones {

                taskGroup.addTask {

                    let query = CKQuery(
                        recordType: Self.groupRecordType,
                        predicate: NSPredicate(value: true)
                    )

                    do {

                        let (matchResults, _) = try await database.records(
                            matching: query,
                            inZoneWith: zone.zoneID
                        )

                        return matchResults.compactMap { _, result -> SharedGroup? in

                            guard case .success(let record) = result else {
                                return nil
                            }

                            return SharedGroup(record: record, database: database)

                        }

                    } catch {

                        print("GroupSharing: failed to query zone \(zone.zoneID.zoneName): \(error)")
                        return []

                    }

                }

            }

            var allGroups: [SharedGroup] = []

            for await groupsInZone in taskGroup {
                allGroups.append(contentsOf: groupsInZone)
            }

            return allGroups

        }

    }

    func renameGroup(_ group: SharedGroup, to newName: String) async throws {

        group.record["name"] = newName as CKRecordValue

        _ = try await group.database.save(group.record)

    }

    /// The owner deleting the group for everyone. Only works on a zone in
    /// the owner's own private database.
    func deleteGroup(_ group: SharedGroup) async throws {

        _ = try await group.database.deleteRecordZone(
            withID: group.record.recordID.zoneID
        )

    }

    /// A participant removing themselves from someone else's group. They
    /// cannot delete the owner's zone — deleting the share record from the
    /// shared database is how CloudKit models "leave".
    func leaveGroup(_ group: SharedGroup) async throws {

        guard let shareReference = group.record.share else {

            throw NSError(
                domain: "GroupSharing",
                code: -2,
                userInfo: [
                    NSLocalizedDescriptionKey: "This group is no longer shared."
                ]
            )

        }

        _ = try await container.sharedCloudDatabase.deleteRecord(
            withID: shareReference.recordID
        )

    }

    // MARK: - Sharing

    /// The group's existing share. Creates one only if the group genuinely
    /// has none.
    func share(for group: SharedGroup) async throws -> CKShare {

        if let existing = try await fetchShare(for: group) {
            return existing
        }

        let newShare = CKShare(rootRecord: group.record)
        newShare[CKShare.SystemFieldKey.title] = group.name as CKRecordValue
        newShare.publicPermission = .none

        let result = try await group.database.modifyRecords(
            saving: [group.record, newShare],
            deleting: []
        )

        for (_, saveResult) in result.saveResults {

            if case .failure(let error) = saveResult {
                throw error
            }

        }

        return newShare

    }

    /// The invite URL, for sending through any app at all.
    func shareURL(for group: SharedGroup) async throws -> URL {

        let groupShare = try await share(for: group)

        guard let url = groupShare.url else {

            throw NSError(
                domain: "GroupSharing",
                code: -3,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "The invite link isn't ready yet. Give it a moment and try again."
                ]
            )

        }

        return url

    }

    /// Registers someone as a participant using the email or phone number
    /// their Apple ID is signed in with. This is what lets the invite link
    /// be sent through WhatsApp, email or anything else — CloudKit only
    /// opens a private share for people who are already participants, and
    /// copying the link on its own registers nobody.
    func inviteParticipant(
        emailOrPhone: String,
        to group: SharedGroup
    ) async throws -> String {

        let groupShare = try await share(for: group)

        let trimmed = emailOrPhone.trimmingCharacters(in: .whitespacesAndNewlines)

        let participant: CKShare.Participant

        if trimmed.contains("@") {

            participant = try await container.shareParticipant(
                forEmailAddress: trimmed
            )

        } else {

            participant = try await container.shareParticipant(
                forPhoneNumber: trimmed
            )

        }

        participant.permission = .readWrite
        participant.role = .privateUser

        groupShare.addParticipant(participant)

        let result = try await group.database.modifyRecords(
            saving: [groupShare],
            deleting: []
        )

        for (_, saveResult) in result.saveResults {

            if case .failure(let error) = saveResult {
                throw error
            }

        }

        let formattedName = participant.userIdentity.nameComponents.flatMap {
            PersonNameComponentsFormatter().string(from: $0)
        }

        return (formattedName?.isEmpty == false ? formattedName : nil) ?? trimmed

    }

    /// True when anyone holding the link can join, false when only invited
    /// people can.
    func isLinkSharingEnabled(for group: SharedGroup) async throws -> Bool {

        guard let groupShare = try await fetchShare(for: group) else {
            return false
        }

        return groupShare.publicPermission != .none

    }

    func setLinkSharingEnabled(_ enabled: Bool, for group: SharedGroup) async throws {

        let groupShare = try await share(for: group)

        groupShare.publicPermission = enabled ? .readWrite : .none

        let result = try await group.database.modifyRecords(
            saving: [groupShare],
            deleting: []
        )

        for (_, saveResult) in result.saveResults {

            if case .failure(let error) = saveResult {
                throw error
            }

        }

    }

    private func fetchShare(for group: SharedGroup) async throws -> CKShare? {

        // Re-read the group record from the server first. A locally built
        // copy carries no share reference, which would otherwise look like
        // an unshared group and cause a second share to be created.
        let freshRecord = try await group.database.record(
            for: group.record.recordID
        )

        guard let shareReference = freshRecord.share else {
            return nil
        }

        let shareRecord = try await group.database.record(
            for: shareReference.recordID
        )

        return shareRecord as? CKShare

    }

    // MARK: - Participants

    private func currentUserRecordName() async throws -> String {

        if let cachedUserRecordName {
            return cachedUserRecordName
        }

        let recordName = try await container.userRecordID().recordName

        cachedUserRecordName = recordName

        return recordName

    }

    func fetchParticipants(for group: SharedGroup) async throws -> [GroupParticipant] {

        let myRecordName = try await currentUserRecordName()

        guard let groupShare = try await fetchShare(for: group) else {

            return [
                GroupParticipant(
                    id: myRecordName,
                    displayName: "You",
                    alternateIDs: [],
                    isCurrentUser: true
                )
            ]

        }

        var built: [GroupParticipant] = []

        for participant in groupShare.participants {

            guard participant.acceptanceStatus != .removed else {
                continue
            }

            let identity = participant.userIdentity

            var recordName = identity.userRecordID?.recordName

            if recordName == CKCurrentUserDefaultName {
                recordName = myRecordName
            }

            let email = identity.lookupInfo?.emailAddress?.lowercased()
            let phone = identity.lookupInfo?.phoneNumber

            var aliases: [String] = []

            if let email {
                aliases.append("email:\(email)")
            }

            if let phone {
                aliases.append("phone:\(phone)")
            }

            // Someone who has accepted is identified by their record name.
            // Someone still pending has no record name yet, so the email or
            // phone they were invited with stands in until they accept —
            // and stays on as an alias afterwards, so expenses recorded
            // while they were pending still match them.
            guard let primaryID = recordName ?? aliases.first else {
                continue
            }

            let isCurrentUser = (recordName != nil && recordName == myRecordName)

            let formattedName = identity.nameComponents.flatMap {
                PersonNameComponentsFormatter().string(from: $0)
            }

            var displayName: String

            if isCurrentUser {

                displayName = "You"

            } else {

                displayName = (formattedName?.isEmpty == false ? formattedName : nil)
                    ?? email
                    ?? phone
                    ?? "Member"

                if participant.acceptanceStatus == .pending {
                    displayName += " (invited)"
                }

            }

            built.append(
                GroupParticipant(
                    id: primaryID,
                    displayName: displayName,
                    alternateIDs: aliases.filter { $0 != primaryID },
                    isCurrentUser: isCurrentUser
                )
            )

        }

        // An email or phone CloudKit reports for more than one participant
        // is useless as an identifier — drop it rather than let it merge
        // two people into one.
        var aliasCounts: [String: Int] = [:]

        for participant in built {

            for alias in participant.alternateIDs {
                aliasCounts[alias, default: 0] += 1
            }

        }

        let participants = built.map { participant in

            GroupParticipant(
                id: participant.id,
                displayName: participant.displayName,
                alternateIDs: participant.alternateIDs.filter { aliasCounts[$0] == 1 },
                isCurrentUser: participant.isCurrentUser
            )

        }

        // You first, then everyone else alphabetically.
        return participants.sorted { lhs, rhs in

            if lhs.isCurrentUser != rhs.isCurrentUser {
                return lhs.isCurrentUser
            }

            return lhs.displayName < rhs.displayName

        }

    }

    // MARK: - Expenses

    func addExpense(
        title: String,
        amount: Double,
        paidBy: GroupParticipant,
        splitAmong: [GroupParticipant],
        in group: SharedGroup
    ) async throws -> SharedExpense {

        let expenseRecordID = CKRecord.ID(
            recordName: UUID().uuidString,
            zoneID: group.record.recordID.zoneID
        )

        let expenseRecord = CKRecord(
            recordType: Self.expenseRecordType,
            recordID: expenseRecordID
        )

        // Attach the expense to the group record so it belongs to the
        // CKShare hierarchy. CKShare(rootRecord:) shares the root record
        // and its parent-linked descendants only — without this the
        // expense stays private to the owner and participants never see it.
        expenseRecord.parent = CKRecord.Reference(
            recordID: group.record.recordID,
            action: .none
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

        guard let expense = SharedExpense(record: expenseRecord) else {

            throw NSError(
                domain: "GroupSharing",
                code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Could not read back the expense that was just saved."
                ]
            )

        }

        return expense

    }

    func updateExpense(
        _ expense: SharedExpense,
        title: String,
        amount: Double,
        paidBy: GroupParticipant,
        splitAmong: [GroupParticipant],
        in group: SharedGroup
    ) async throws -> SharedExpense {

        let record = expense.record

        // The original date is deliberately left alone — fixing a typo in
        // an amount shouldn't move the expense to today.
        record["title"] = title as CKRecordValue
        record["amount"] = amount as CKRecordValue
        record["paidByUserRecordID"] = paidBy.id as CKRecordValue
        record["paidByDisplayName"] = paidBy.displayName as CKRecordValue
        record["splitAmongUserRecordIDs"] = splitAmong.map(\.id) as CKRecordValue

        let result = try await group.database.modifyRecords(
            saving: [record],
            deleting: []
        )

        for (_, saveResult) in result.saveResults {

            if case .failure(let error) = saveResult {
                throw error
            }

        }

        guard let updated = SharedExpense(record: record) else {

            throw NSError(
                domain: "GroupSharing",
                code: -5,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Could not read back the expense that was just updated."
                ]
            )

        }

        return updated

    }

    func deleteExpense(_ expense: SharedExpense, in group: SharedGroup) async throws {

        _ = try await group.database.deleteRecord(withID: expense.id)

    }

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
