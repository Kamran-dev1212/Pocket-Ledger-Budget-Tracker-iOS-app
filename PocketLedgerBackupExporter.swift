
import Foundation
import SwiftData

@MainActor
enum PocketLedgerBackupExporter {

    // MARK: - Create Backup Data

    static func createBackup(
        from context: ModelContext,
        selectedCurrency: String
    ) throws -> PocketLedgerBackup {

        let transactions = try context.fetch(
            FetchDescriptor<Transaction>()
        )

        let budgets = try context.fetch(
            FetchDescriptor<Budget>()
        )

        let categories = try context.fetch(
            FetchDescriptor<UserCategory>()
        )

        let profiles = try context.fetch(
            FetchDescriptor<UserProfile>()
        )

        return PocketLedgerBackup(
            formatVersion: 1,
            exportedAt: Date(),
            appName: "Pocket Ledger",
            selectedCurrency: selectedCurrency,

            transactions: transactions.map {
                TransactionBackup(
                    title: $0.title,
                    amount: $0.amount,
                    category: $0.category,
                    type: $0.type,
                    date: $0.date,
                    isArchived: $0.isArchived
                )
            },

            budgets: budgets.map {
                BudgetBackup(
                    category: $0.category,
                    amount: $0.amount,
                    month: $0.month,
                    year: $0.year,
                    dateCreated: $0.dateCreated
                )
            },

            categories: categories.map {
                CategoryBackup(
                    name: $0.name,
                    icon: $0.icon,
                    type: $0.type,
                    isDefault: $0.isDefault,
                    seedKey: $0.seedKey
                )
            },

            profiles: profiles.map {
                ProfileBackup(
                    fullName: $0.fullName,
                    email: $0.email,
                    phoneNumber: $0.phoneNumber,
                    occupation: $0.occupation,
                    bio: $0.bio,
                    profileImageData: $0.profileImageData
                )
            }
        )
    }

    // MARK: - JSON Backup File Generation

    static func createBackupFile(
        from context: ModelContext,
        selectedCurrency: String
    ) throws -> URL {

        let backup = try createBackup(
            from: context,
            selectedCurrency: selectedCurrency
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [
            .prettyPrinted,
            .sortedKeys
        ]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(backup)

        let filename = "PocketLedger-Backup-\(UUID().uuidString).json"

        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(filename)

        try data.write(
            to: fileURL,
            options: .atomic
        )

        return fileURL
    }
}
