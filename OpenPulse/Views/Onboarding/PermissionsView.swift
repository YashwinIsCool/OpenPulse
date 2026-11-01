import SwiftUI

struct PermissionsView: View {
    @ObservedObject var permissions: PermissionsManager
    let onNext: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.xxl) {
            VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
                Text("Allow access")
                    .font(Tokens.Fonts.screenTitle)
                    .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                Text("Everything is measured on this phone. No photos, video, or audio are uploaded.")
                    .font(Tokens.Fonts.bodyText)
                    .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, Tokens.Spacing.xxl)

            ListCard {
                row(icon: "camera", title: "Camera",
                    detail: "Measures your heart rate from tiny color changes in your fingertip.",
                    granted: permissions.cameraGranted) { permissions.requestCamera() }
                ListDivider()
                row(icon: "bell", title: "Notifications",
                    detail: "Gentle reminders for your daily check.",
                    granted: permissions.notificationsGranted) { permissions.requestNotifications() }
            }

            Text("You can skip these and allow them later.")
                .font(Tokens.Fonts.secondaryText)
                .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)

            Spacer()

            PrimaryButton(title: "Continue", action: onNext)
                .padding(.bottom, Tokens.Spacing.xl)
        }
        .padding(.horizontal, Tokens.Spacing.xl)
    }

    private func row(icon: String, title: String, detail: String, granted: Bool, action: @escaping () -> Void) -> some View {
        HStack(alignment: .top, spacing: Tokens.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                .frame(width: 24)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Tokens.Fonts.bodyText.weight(.semibold))
                    .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                Text(detail)
                    .font(Tokens.Fonts.secondaryText)
                    .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: Tokens.Spacing.sm)
            if granted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Tokens.Colors.statusGood)
                    .accessibilityLabel("Allowed")
            } else {
                Button("Allow", action: action)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .overlay(Capsule().stroke(Tokens.Colors.adaptiveBorder, lineWidth: 1))
            }
        }
        .padding(.vertical, 14)
    }
}
