import Foundation
import SwiftData

@Model
final class Budget {

    var category: String
    var amount: Double
    var month: Int
    var year: Int
    var dateCreated: Date

    init(
        category: String,
        amount: Double,
        month: Int,
        year: Int,
        dateCreated: Date = .now
    ) {
        self.category = category
        self.amount = amount
        self.month = month
        self.year = year
        self.dateCreated = dateCreated
    }

}
