import Foundation

/// The app's name and version in one place, so a rename only touches this file
/// (plus CFBundleDisplayName in project.yml).
enum AppInfo {
    static let name = "OpenPulse"

    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
}
