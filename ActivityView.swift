import SwiftUI

/// Thin wrapper around UIActivityViewController (the native iOS share
/// sheet), used for exporting a backup file. SwiftUI's own ShareLink
/// requires the shared item to already exist when the view renders;
/// here the file is generated fresh at the moment the user taps
/// Export, so a ShareLink can't be wired up in advance.
struct ActivityView: UIViewControllerRepresentable {

    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {

        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )

    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }

}
