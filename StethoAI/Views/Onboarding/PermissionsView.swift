import SwiftUI

struct PermissionsView: View {
    @ObservedObject var permissions: PermissionsManager
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: Tokens.Spacing.xl) {
            VStack(spacing: Tokens.Spacing.xs) {
                Text("A couple permissions")
                    .font(Tokens.Fonts.pageTitle)
                    .tracking(Tokens.Tracking.pageTitle)
                    .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                Text("StethoAI uses your camera and microphone on-device only.")
                    .font(Tokens.Fonts.body)
                    .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, Tokens.Spacing.xxl)

            VStack(spacing: Tokens.Spacing.md) {
                permissionCard(
                    icon: "camera.fill",
                    title: "Camera",
                    explanation: "Used to measure your heart rate by detecting subtle color changes in your fingertip.",
                    granted: permissions.cameraGranted,
                    action: { permissions.requestCamera() }
                )

                permissionCard(
                    icon: "mic.fill",
                    title: "Microphone",
                    explanation: "Used to record heart sounds when you hold your phone against your chest.",
                    granted: permissions.microphoneGranted,
                    action: { permissions.requestMicrophone() }
                )

                permissionCard(
                    icon: "bell.fill",
                    title: "Notifications",
                    explanation: "Get gentle reminders for daily checks and breathing exercises.",
                    granted: permissions.notificationsGranted,
                    action: { permissions.requestNotifications() }
                )
            }
            .padding(.horizontal, Tokens.Spacing.xl)

            Spacer()

            PrimaryButton(title: "Continue", icon: "arrow.right", action: onNext)
                .padding(.horizontal, Tokens.Spacing.xl)
                .padding(.bottom, Tokens.Spacing.xl)
        }
    }

    private func permissionCard(icon: String, title: String, explanation: String, granted: Bool, action: @escaping () -> Void) -> some View {
        Card {
            HStack(alignment: .top, spacing: Tokens.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Tokens.Colors.primaryRed)
                    .frame(width: 32, height: 32)
                    .background(Tokens.Colors.adaptiveSoftRedSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
                    Text(title)
                        .font(Tokens.Fonts.cardTitle)
                        .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                    Text(explanation)
                        .font(Tokens.Fonts.body)
                        .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                }

                Spacer()

                if granted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Tokens.Colors.successGreen)
                } else {
                    Button("Grant", action: action)
                        .font(Tokens.Fonts.caption)
                        .foregroundStyle(Tokens.Colors.primaryRed)
                        .padding(.horizontal, Tokens.Spacing.sm)
                        .padding(.vertical, Tokens.Spacing.xs)
                        .background(Tokens.Colors.adaptiveSoftRedSurface)
                        .clipShape(Capsule())
                }
            }
        }
    }
}
