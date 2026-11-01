import AVFoundation
import UserNotifications
import Combine

final class PermissionsManager: ObservableObject {
    @Published var cameraGranted: Bool = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    @Published var notificationsGranted: Bool = false

    func requestCamera(completion: @escaping (Bool) -> Void = { _ in }) {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.cameraGranted = granted
                completion(granted)
            }
        }
    }

    func requestNotifications(completion: @escaping (Bool) -> Void = { _ in }) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, _ in
            DispatchQueue.main.async {
                self?.notificationsGranted = granted
                completion(granted)
            }
        }
    }
}
