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

    /// Spending at or above this fraction of the budget is a warning.
    /// Set to 0.6 if you prefer the earlier, more aggressive warning.
    static let nearLimitThreshold: Double = 0.8

    /// Above this fraction the budget is genuinely overspent.
    /// This is the bug that was being reported as "Exceeded" at 0.8.
    static let exceededThreshold: Double = 1.0

    // MARK: Derivation

    static func status(
        spent: Double,
        budgetAmount: Double
    ) -> BudgetStatus {

        // A zero or negative budget can't be exceeded in any
        // meaningful sense, and dividing by it would produce
        // infinity. Treat it as on track.

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
//
// Kept as free functions on a namespace rather than as computed
// properties on Budget, because `spent` is derived from the
// Transaction store and isn't known to the model itself.

struct BudgetMath {

    /// Raw progress, uncapped. Can exceed 1.0 when overspent —
    /// callers that drive a ProgressView should clamp separately.
    static func progress(
        spent: Double,
        budgetAmount: Double
    ) -> Double {

        guard budgetAmount > 0 else {
            return 0
        }

        return spent / budgetAmount

    }

    /// Progress clamped to 0...1, for progress bars.
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

    /// What's left. Goes negative when overspent.
    ///
    /// The previous `max(0, ...)` meant someone 5,000 over budget
    /// saw "Remaining 0" and a full bar, with no indication of how
    /// far over they were. Callers decide how to present a negative.
    static func remaining(
        spent: Double,
        budgetAmount: Double
    ) -> Double {

        CurrencyManager.rounded(
            budgetAmount - spent
        )

    }

    /// Amount overspent, or zero when within budget.
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
