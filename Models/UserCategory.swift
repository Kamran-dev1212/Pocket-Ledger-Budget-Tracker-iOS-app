import Foundation
import SwiftData

@Model
final class UserCategory {

    var name: String = ""
    var icon: String = "circle"
    var type: String = "Expense"

    /// True for the categories the app seeds on first launch. They can be
    /// renamed and deleted like any other — this only records where they
    /// came from.
    var isDefault: Bool = false

    /// The built-in name this row was seeded from, kept even after the
    /// user renames it. Two jobs: recognising the same default across
    /// devices so CloudKit can't leave duplicates, and keeping the
    /// category's colour after a rename.
    var seedKey: String = ""

    init(
        name: String,
        icon: String,
        type: String,
        isDefault: Bool = false,
        seedKey: String = ""
    ) {

        self.name = name
        self.icon = icon
        self.type = type
        self.isDefault = isDefault
        self.seedKey = seedKey

    }

}
