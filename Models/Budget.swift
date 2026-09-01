import Foundation
import SwiftData

@Model
final class Budget {

    var category: String = ""
    var amount: Double = 0
    var month: Int = 1
    var year: Int = 2000
    var dateCreated: Date = Date()

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

// MARK: - Budget Status
//
// Single source of truth for how spending maps to a status band.
// Both BudgetCardView (colour + labels) and InsightsEngine (the
// On Track / Near Limit / Exceeded counts) read from here, so the
// card a user taps and the summary on the Dashboard can no longer
// disagree with each other.

enum BudgetStatus {

    case onTrack
    case nearLimit
    case exceeded

    // MARK: Thresholds

    static let nearLimitThreshold: Double = 0.8
    static let exceededThreshold: Double = 1.0

    // MARK: Derivation

    static func status(
        spent: Double,
        budgetAmount: Double
    ) -> BudgetStatus {

        guard budgetAmount > 0 else {
            return .onTrack
        }

        let ratio = spent / budgetAmount

        if ratio > exceededThreshold {
            return .exceeded
        }

        if ratio >= nearLimitThreshold {
            return .nearLimit
        }

        return .onTrack

    }

    // MARK: Presentation

    var label: String {

        switch self {

        case .onTrack:
            return "On Track"

        case .nearLimit:
            return "Near Limit"

        case .exceeded:
            return "Exceeded"

        }

    }

}

// MARK: - Budget Calculations

struct BudgetMath {

    static func progress(
        spent: Double,
        budgetAmount: Double
    ) -> Double {

        guard budgetAmount > 0 else {
            return 0
        }

        return spent / budgetAmount

    }

    static func clampedProgress(
        spent: Double,
        budgetAmount: Double
    ) -> Double {

        min(
            max(
                progress(
                    spent: spent,
                    budgetAmount: budgetAmount
                ),
                0
            ),
            1
        )

    }

    static func remaining(
        spent: Double,
        budgetAmount: Double
    ) -> Double {

        CurrencyManager.rounded(
            budgetAmount - spent
        )

    }

    static func overspend(
        spent: Double,
        budgetAmount: Double
    ) -> Double {

        max(
            0,
            CurrencyManager.rounded(
                spent - budgetAmount
            )
        )

    }

    static func status(
        spent: Double,
        budgetAmount: Double
    ) -> BudgetStatus {

        BudgetStatus.status(
            spent: spent,
            budgetAmount: budgetAmount
        )

    }

}
