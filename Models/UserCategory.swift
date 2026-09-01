import Foundation
import SwiftData

@Model
final class UserCategory {

    var name: String = ""
    var icon: String = "circle"
    var type: String = "Expense"
    var isDefault: Bool = false

    init(
        name: String,
        icon: String,
        type: String,
        isDefault: Bool = false
    ) {

        self.name = name
        self.icon = icon
        self.type = type
        self.isDefault = isDefault

    }

}
