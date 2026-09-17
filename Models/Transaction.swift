import Foundation
import SwiftData

@Model
final class Transaction {

    var title: String = ""
    var amount: Double = 0
    var category: String = ""
    var type: String = "Expense"
    var date: Date = Date()
    /// Archived by "Start New Month". An archived transaction must be
    /// excluded from EVERY live figure — balance, budgets, reports,
    /// insights, income/expense lists and the PDF statement. The only
    /// place it appears is the Archived tab in Transaction History.
    var isArchived: Bool = false

    init(
        title: String,
        amount: Double,
        category: String,
        type: String,
        date: Date = Date(),
        isArchived: Bool = false
    ) {
        self.title = title
        self.amount = amount
        self.category = category
        self.type = type
        self.date = date
        self.isArchived = isArchived
    }
}
