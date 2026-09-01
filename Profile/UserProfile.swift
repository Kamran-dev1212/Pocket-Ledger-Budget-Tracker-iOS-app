import Foundation
import SwiftData

@Model
final class UserProfile {

    var fullName: String = ""
    var email: String = ""
    var phoneNumber: String = ""
    var occupation: String = ""
    var bio: String = ""
    var profileImageData: Data?

    init(
        fullName: String = "",
        email: String = "",
        phoneNumber: String = "",
        occupation: String = "",
        bio: String = "",
        profileImageData: Data? = nil
    ) {
        self.fullName = fullName
        self.email = email
        self.phoneNumber = phoneNumber
        self.occupation = occupation
        self.bio = bio
        self.profileImageData = profileImageData
    }

}
