import AVFoundation
import UserNotifications
import Combine

final class PermissionsManager: ObservableObject {
    @Published var cameraGranted: Bool = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    @Published var microphoneGranted: Bool = AVAudioApplication.shared.recordPermission == .granted
    @Published var notificationsGranted: Bool = false

    func requestCamera(completion: @escaping (Bool) -> Void = { _ in }) {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.cameraGranted = granted
                completion(granted)
            }
        }
    }

    func requestMicrophone(completion: @escaping (Bool) -> Void = { _ in }) {
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                self?.microphoneGranted = granted
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
