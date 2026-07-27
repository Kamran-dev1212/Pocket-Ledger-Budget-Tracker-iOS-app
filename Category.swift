import Foundation
import SwiftUI

struct Category: Identifiable, Hashable {

    let id = UUID()
    let name: String
    let icon: String
    let type: String // "Income" or "Expense"

}

struct CategoryManager {

    // MARK: - Expense Categories

    static let expenseCategories: [Category] = [

        Category(name: "Food", icon: "fork.knife", type: "Expense"),
        Category(name: "Shopping", icon: "bag.fill", type: "Expense"),
        Category(name: "Transport", icon: "car.fill", type: "Expense"),
        Category(name: "Fuel", icon: "fuelpump.fill", type: "Expense"),
        Category(name: "Bills", icon: "doc.text.fill", type: "Expense"),
        Category(name: "Healthcare", icon: "cross.case.fill", type: "Expense"),
        Category(name: "Education", icon: "book.fill", type: "Expense"),
        Category(name: "Entertainment", icon: "tv.fill", type: "Expense"),
        Category(name: "Travel", icon: "airplane", type: "Expense"),
        Category(name: "Rent", icon: "house.fill", type: "Expense"),
        Category(name: "Groceries", icon: "cart.fill", type: "Expense"),
        Category(name: "Business", icon: "briefcase.fill", type: "Expense"),
        Category(name: "Others", icon: "ellipsis.circle.fill", type: "Expense")

    ]

    // MARK: - Income Categories

    static let incomeCategories: [Category] = [

        Category(name: "Salary", icon: "banknote.fill", type: "Income"),
        Category(name: "Freelancing", icon: "laptopcomputer", type: "Income"),
        Category(name: "Business", icon: "building.2.fill", type: "Income"),
        Category(name: "Investment", icon: "chart.line.uptrend.xyaxis", type: "Income"),
        Category(name: "Bonus", icon: "star.circle.fill", type: "Income"),
        Category(name: "Gift", icon: "gift.fill", type: "Income"),
        Category(name: "Refund", icon: "arrow.uturn.left.circle.fill", type: "Income"),
        Category(name: "Others", icon: "ellipsis.circle.fill", type: "Income")

    ]

    // MARK: - Lookup

    static func categories(for type: String) -> [Category] {

        type == "Income" ? incomeCategories : expenseCategories

    }

    static func icon(for categoryName: String, type: String) -> String? {

        categories(for: type)
            .first(where: { $0.name == categoryName })?
            .icon

    }

    // MARK: - Category Colors

    static func color(for categoryName: String) -> Color {

        switch categoryName {

        case "Food":
            return .orange

        case "Shopping":
            return .purple

        case "Transport":
            return .blue

        case "Fuel":
            return .red

        case "Bills":
            return .indigo

        case "Healthcare":
            return .pink

        case "Education":
            return .cyan

        case "Entertainment":
            return .mint

        case "Travel":
            return .teal

        case "Rent":
            return .brown

        case "Groceries":
            return .green

        case "Business":
            return .blue

        case "Salary":
            return .green

        case "Freelancing":
            return .blue

        case "Investment":
            return .indigo

        case "Bonus":
            return .yellow

        case "Gift":
            return .pink

        case "Refund":
            return .cyan

        case "Others":
            return .secondary

        default:
            return AppColors.primary

        }

    }

}
