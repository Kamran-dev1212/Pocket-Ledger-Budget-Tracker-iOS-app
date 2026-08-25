import Foundation
import SwiftData

@Model
final class UserCategory {

    var name: String
    var icon: String
    var type: String
    var isDefault: Bool

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
