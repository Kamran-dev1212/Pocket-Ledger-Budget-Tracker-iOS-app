import SwiftUI
import UIKit

/// Applies the selected appearance to the UIKit window.
///
/// AppColors uses dynamic UIColors that resolve against the UIKit
/// trait collection. Applying the interface style at the window level
/// ensures the selected appearance is also respected by presented sheets.
enum AppearanceManager {

    static func apply(_ appearance: AppAppearance) {

        let style: UIUserInterfaceStyle

        switch appearance {

        case .light:
            style = .light

        case .dark:
            style = .dark

        case .system:
            style = .unspecified

        }

        for scene in UIApplication.shared.connectedScenes {

            guard let windowScene = scene as? UIWindowScene else {
                continue
            }

            for window in windowScene.windows {

                window.overrideUserInterfaceStyle = style

            }

        }

    }

}
