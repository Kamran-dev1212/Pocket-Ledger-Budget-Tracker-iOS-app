import Foundation
import CloudKit

/// Turns CloudKit's errors into something a person can act on.
///
/// Left raw, these reach the user as "Quota exceeded" or
/// "CKErrorDomain error 4" — which reads as the app being broken when
/// the actual problem is a full iCloud account or no signal.
enum CloudKitMessage {

    enum Context {

        /// Anything that reads or writes group data.
        case general

        /// Looking someone up by email or phone to add them to a share,
        /// where "not found" means their address, not a missing record.
        case invite

    }

    static func message(
        for error: Error,
        context: Context = .general
    ) -> String {

        guard let ckError = error as? CKError else {
            return error.localizedDescription
        }

        switch ckError.code {

        case .quotaExceeded:
            return "Your iCloud storage is full, so this couldn't be saved. Free up space in Settings → iCloud → Manage Account Storage, or upgrade your plan, then try again."

        case .notAuthenticated:
            return "You're not signed in to iCloud on this device. Open Settings, sign in, and make sure iCloud Drive is on."

        case .networkUnavailable, .networkFailure:
            return "Couldn't reach iCloud. Check your internet connection and try again."

        case .serviceUnavailable, .requestRateLimited:
            return "iCloud is busy right now. Give it a moment and try again."

        case .accountTemporarilyUnavailable:
            return "Your iCloud account isn't available at the moment. This usually clears on its own — try again shortly."

        case .managedAccountRestricted:
            return "This Apple Account isn't allowed to share data. Managed and child accounts can't join or create shared groups."

        case .permissionFailure:
            return "You don't have permission to make that change. The group's owner may have removed you or stopped sharing."

        case .zoneNotFound, .userDeletedZone:
            return "This group no longer exists. The owner may have deleted it."

        case .serverRecordChanged:
            return "Someone else changed this at the same time. Pull to refresh and try again."

        case .unknownItem:

            switch context {

            case .invite:
                return "No iCloud account is registered to that email or phone number. Ask them to check Settings → their name on their iPhone, and use the address shown there."

            case .general:
                return "That item couldn't be found in iCloud. It may have been deleted on another device."

            }

        case .participantMayNeedVerification:
            return "They need to sign in to iCloud on their device before they can be added to a shared group."

        case .alreadyShared:
            return "This group is already shared."

        case .tooManyParticipants:
            return "This group has reached iCloud's limit on how many people can join."

        default:
            return error.localizedDescription

        }

    }

}
