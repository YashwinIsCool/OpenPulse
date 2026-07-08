import SwiftUI

/// Wraps UIActivityViewController so any screen can present the native share sheet
/// (used to share heart-sound recordings and results with a doctor).
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
