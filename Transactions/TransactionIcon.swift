import SwiftUI

struct TransactionIcon {

    static func icon(for category: String, type: String) -> String {

        // MARK: - Step 1: Try exact match from CategoryManager first

        if let exactIcon = CategoryManager.icon(for: category, type: type) {
            return exactIcon
        }

        // MARK: - Step 2: Fallback fuzzy matching (for legacy data)

        let value = category.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        switch value {

        // MARK: Income

        case "salary", "pay", "income", "wage", "monthly salary":
            return "briefcase.fill"

        case "business", "company":
            return "building.2.fill"

        case "freelance", "freelancing", "project":
            return "laptopcomputer"

        case "investment", "stocks", "crypto", "profit":
            return "chart.line.uptrend.xyaxis"

        case "gift":
            return "gift.fill"

        case "rent income":
            return "house.fill"

        // MARK: Food

        case "food",
             "lunch",
             "dinner",
             "breakfast",
             "restaurant",
             "cafe",
             "coffee",
             "pizza",
             "burger":
            return "fork.knife"

        // MARK: Shopping

        case "shopping",
             "clothes",
             "fashion",
             "grocery",
             "groceries",
             "supermarket",
             "mall",
             "amazon":
            return "cart.fill"

        // MARK: Fuel & Transport

        case "fuel",
             "petrol",
             "diesel",
             "gas":
            return "fuelpump.fill"

        case "transport",
             "car",
             "taxi",
             "uber",
             "bus",
             "train":
            return "car.fill"

        // MARK: Bills

        case "bills",
             "electricity",
             "water",
             "internet",
             "wifi",
             "phone",
             "mobile":
            return "doc.text.fill"

        // MARK: Health

        case "health",
             "doctor",
             "medicine",
             "hospital",
             "pharmacy":
            return "cross.case.fill"

        // MARK: Entertainment

        case "entertainment",
             "movie",
             "movies",
             "netflix",
             "gaming":
            return "tv.fill"

        // MARK: Travel

        case "travel",
             "flight",
             "hotel",
             "vacation":
            return "airplane"

        // MARK: Education

        case "education",
             "school",
             "college",
             "university",
             "course",
             "books":
            return "book.fill"

        // MARK: Rent

        case "rent":
            return "house.fill"

        // MARK: Pets

        case "pet",
             "pets",
             "cat",
             "dog",
             "bird":
            return "pawprint.fill"

        // MARK: Family

        case "family",
             "kids",
             "children":
            return "person.2.fill"

        // MARK: Default

        default:
            return type == "Income"
            ? "arrow.down.circle.fill"
            : "arrow.up.circle.fill"
        }
    }
}
