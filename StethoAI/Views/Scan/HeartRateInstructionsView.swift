import SwiftUI

struct HeartRateInstructionsView: View {
    let onStart: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: Tokens.Spacing.xl) {
            HStack {
                Spacer()
                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                        .padding(Tokens.Spacing.sm)
                        .background(Tokens.Colors.adaptiveCard)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, Tokens.Spacing.lg)
            .padding(.top, Tokens.Spacing.sm)

            Spacer()

            ZStack {
                Circle()
                    .fill(Tokens.Colors.adaptiveSoftRedSurface)
                    .frame(width: 180, height: 180)
                Image(systemName: "hand.point.up.left.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Tokens.Colors.primaryRed)
            }

            VStack(spacing: Tokens.Spacing.md) {
                Text("Heart Rate Check")
                    .font(Tokens.Fonts.pageTitle)
                    .tracking(Tokens.Tracking.pageTitle)
                    .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)

                Text("Place your finger gently over the rear camera and flash. Hold still for 30 seconds.")
                    .font(Tokens.Fonts.body)
                    .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Tokens.Spacing.xxl)
            }

            Spacer()
            Spacer()

            PrimaryButton(title: "Start", icon: "play.fill", action: onStart)
                .padding(.horizontal, Tokens.Spacing.xl)
                .padding(.bottom, Tokens.Spacing.xl)
        }
    }
}
