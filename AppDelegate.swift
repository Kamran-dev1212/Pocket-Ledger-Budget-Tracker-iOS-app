import UIKit
import CloudKit

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata
    ) {

        let groupName =
            cloudKitShareMetadata.share[CKShare.SystemFieldKey.title] as? String
            ?? "Group"

        Task {

            do {

                try await GroupSharingManager.shared.acceptShare(
                    metadata: cloudKitShareMetadata
                )

                await MainActor.run {

                    ShareAcceptanceCoordinator.shared.lastResult =
                        .success(groupName: groupName)

                }

                NotificationCenter.default.post(
                    name: .didAcceptGroupShare,
                    object: nil
                )

            } catch {

                print("Failed to accept group share: \(error)")

                await MainActor.run {

                    ShareAcceptanceCoordinator.shared.lastResult =
                        .failure(message: error.localizedDescription)

                }

            }

        }

    }

}

extension Notification.Name {

    static let didAcceptGroupShare = Notification.Name("didAcceptGroupShare")

}
