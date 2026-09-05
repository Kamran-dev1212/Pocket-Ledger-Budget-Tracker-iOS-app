import UIKit
import CloudKit

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata
    ) {

        Task {

            do {

                try await GroupSharingManager.shared.acceptShare(
                    metadata: cloudKitShareMetadata
                )

                NotificationCenter.default.post(
                    name: .didAcceptGroupShare,
                    object: nil
                )

            } catch {

                print("Failed to accept group share: \(error)")

            }

        }

    }

}

extension Notification.Name {

    static let didAcceptGroupShare = Notification.Name("didAcceptGroupShare")

}
