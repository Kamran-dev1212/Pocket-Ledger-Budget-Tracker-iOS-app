
import Foundation

// MARK: - Backup Validation Errors

enum PocketLedgerBackupValidationError: LocalizedError {

    case invalidFile
    case unsupportedVersion
    case invalidAppName
    case invalidCurrency
    case invalidExportDate
    case invalidTransaction
    case invalidBudget
    case invalidCategory
    case invalidProfile

    var errorDescription: String? {
        switch self {
        case .invalidFile:
            return "The selected file is not a valid Pocket Ledger backup."

        case .unsupportedVersion:
            return "This backup version is not supported."

        case .invalidAppName:
            return "This file was not created for Pocket Ledger."

        case .invalidCurrency:
            return "The backup contains an invalid currency code."

        case .invalidExportDate:
            return "The backup contains an invalid export date."

        case .invalidTransaction:
            return "The backup contains an invalid transaction."

        case .invalidBudget:
            return "The backup contains an invalid budget."

        case .invalidCategory:
            return "The backup contains an invalid category."

        case .invalidProfile:
            return "The backup contains invalid profile information."
        }
    }
}

// MARK: - Backup Validator

enum PocketLedgerBackupValidator {

    static func validate(
        data: Data
    ) throws -> PocketLedgerBackup {

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let backup: PocketLedgerBackup

        do {
            backup = try decoder.decode(
                PocketLedgerBackup.self,
                from: data
            )
        } catch {
            throw PocketLedgerBackupValidationError.invalidFile
        }

        // MARK: Backup Identity

        guard backup.formatVersion == 1 else {
            throw PocketLedgerBackupValidationError.unsupportedVersion
        }

        guard backup.appName == "Pocket Ledger" else {
            throw PocketLedgerBackupValidationError.invalidAppName
        }

        guard backup.selectedCurrency.count == 3,
              backup.selectedCurrency.allSatisfy({
                  $0.isASCII && $0.isUppercase
              }) else {
            throw PocketLedgerBackupValidationError.invalidCurrency
        }

        guard backup.exportedAt.timeIntervalSince1970.isFinite else {
            throw PocketLedgerBackupValidationError.invalidExportDate
        }

        // MARK: Transactions

        for transaction in backup.transactions {

            guard !transaction.title
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .isEmpty,
                  !transaction.category
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .isEmpty,
                  transaction.amount.isFinite,
                  transaction.amount > 0,
                  transaction.type == "Income" ||
                  transaction.type == "Expense",
                  transaction.date.timeIntervalSince1970.isFinite else {

                throw PocketLedgerBackupValidationError.invalidTransaction
            }
        }

        // MARK: Budgets

        var budgetKeys = Set<String>()

        for budget in backup.budgets {

            guard !budget.category
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .isEmpty,
                  budget.amount.isFinite,
                  budget.amount > 0,
                  (1...12).contains(budget.month),
                  (1...9999).contains(budget.year),
                  budget.dateCreated.timeIntervalSince1970.isFinite else {

                throw PocketLedgerBackupValidationError.invalidBudget
            }

            let key = "\(budget.category)|\(budget.month)|\(budget.year)"

            guard budgetKeys.insert(key).inserted else {
                throw PocketLedgerBackupValidationError.invalidBudget
            }
        }

        // MARK: Categories

        var defaultCategoryKeys = Set<String>()

        for category in backup.categories {

            guard !category.name
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .isEmpty,
                  !category.icon
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .isEmpty,
                  category.type == "Income" ||
                  category.type == "Expense" else {

                throw PocketLedgerBackupValidationError.invalidCategory
            }

            if category.isDefault {

                guard !category.seedKey.isEmpty else {
                    throw PocketLedgerBackupValidationError.invalidCategory
                }

                let key = "\(category.type)|\(category.seedKey)"

                guard defaultCategoryKeys.insert(key).inserted else {
                    throw PocketLedgerBackupValidationError.invalidCategory
                }
            }
        }

        // MARK: Profiles

        guard backup.profiles.count <= 1 else {
            throw PocketLedgerBackupValidationError.invalidProfile
        }

        return backup
    }
}
