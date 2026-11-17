
import Foundation

// MARK: - Pocket Ledger Backup Format

struct PocketLedgerBackup: Codable {

    let formatVersion: Int
    let exportedAt: Date
    let appName: String
    let selectedCurrency: String

    let transactions: [TransactionBackup]
    let budgets: [BudgetBackup]
    let categories: [CategoryBackup]
    let profiles: [ProfileBackup]
}

// MARK: - Transaction Backup

struct TransactionBackup: Codable {

    let title: String
    let amount: Double
    let category: String
    let type: String
    let date: Date
    let isArchived: Bool
}

// MARK: - Budget Backup

struct BudgetBackup: Codable {

    let category: String
    let amount: Double
    let month: Int
    let year: Int
    let dateCreated: Date
}

// MARK: - Category Backup

struct CategoryBackup: Codable {

    let name: String
    let icon: String
    let type: String
    let isDefault: Bool
    let seedKey: String
}

// MARK: - Profile Backup

struct ProfileBackup: Codable {

    let fullName: String
    let email: String
    let phoneNumber: String
    let occupation: String
    let bio: String
    let profileImageData: Data?
    
}
