import SwiftUI
import CloudKit

struct CloudSharingView: UIViewControllerRepresentable {

    let share: CKShare
    let container: CKContainer

    func makeUIViewController(context: Context) -> UICloudSharingController {

        let controller = UICloudSharingController(
            share: share,
            container: container
        )

        controller.delegate = context.coordinator
        controller.availablePermissions = [.allowReadWrite, .allowPrivate]

        return controller

    }

    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, UICloudSharingControllerDelegate {

        func itemTitle(for csc: UICloudSharingController) -> String? {

            csc.share?[CKShare.SystemFieldKey.title] as? String

        }

        func cloudSharingController(
            _ csc: UICloudSharingController,
            failedToSaveShareWithError error: Error
        ) {

            print("Failed to save share: \(error)")

        }

        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {

            print("Share saved successfully")

        }

        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {

            print("Sharing stopped")

        }

    }

}
