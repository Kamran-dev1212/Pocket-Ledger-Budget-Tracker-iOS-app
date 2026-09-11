import UIKit
import CloudKit

final class AppDelegate: NSObject, UIApplicationDelegate {

    // Routes every scene through our own SceneDelegate. In a SwiftUI
    // (scene-based) app, CloudKit share acceptance is delivered to the
    // SCENE delegate — the UIApplicationDelegate version below is never
    // called on modern iOS, and is kept only as a safety net.
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {

        let configuration = UISceneConfiguration(
            name: nil,
            sessionRole: connectingSceneSession.role
        )

        configuration.delegateClass = SceneDelegate.self

        return configuration

    }

    func application(
        _ application: UIApplication,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata
    ) {

        ShareAcceptance.handle(metadata: cloudKitShareMetadata)

    }

}

// Do NOT create a UIWindow here — SwiftUI still owns the window.
final class SceneDelegate: NSObject, UIWindowSceneDelegate {

    // Cold launch: the app was not running when the invite was tapped.
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {

        if let metadata = connectionOptions.cloudKitShareMetadata {

            ShareAcceptance.handle(metadata: metadata)

        }

    }

    // Warm launch: the app was already running or suspended.
    func windowScene(
        _ windowScene: UIWindowScene,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata
    ) {

        ShareAcceptance.handle(metadata: cloudKitShareMetadata)

    }

}

enum ShareAcceptance {

    static func handle(metadata: CKShare.Metadata) {

        let groupName =
            metadata.share[CKShare.SystemFieldKey.title] as? String
            ?? "Group"

        Task {

            do {

                try await GroupSharingManager.shared.acceptShare(
                    metadata: metadata
                )

                print("GroupSharing: accepted \"\(groupName)\"")

                await MainActor.run {

                    ShareAcceptanceCoordinator.shared.lastResult =
                        .success(groupName: groupName)

                    NotificationCenter.default.post(
                        name: .didAcceptGroupShare,
                        object: nil
                    )

                }

            } catch {

                print("GroupSharing: failed to accept \"\(groupName)\": \(error)")

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
