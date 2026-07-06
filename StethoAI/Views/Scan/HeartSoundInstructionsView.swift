import SwiftUI

struct HeartSoundInstructionsView: View {
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
                Image(systemName: "iphone.gen3")
                    .font(.system(size: 64))
                    .foregroundStyle(Tokens.Colors.primaryRed)
            }

            VStack(spacing: Tokens.Spacing.md) {
                Text("Heart Sound Scan")
                    .font(Tokens.Fonts.pageTitle)
                    .tracking(Tokens.Tracking.pageTitle)
                    .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)

                Text("Hold the phone microphone flat against your chest, just left of your breastbone. Breathe normally. Hold still for 30 seconds.")
                    .font(Tokens.Fonts.body)
                    .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Tokens.Spacing.xxl)

                Text("Tip: for clearest results, use in a quiet room.")
                    .font(Tokens.Fonts.caption)
                    .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
            }

            Spacer()
            Spacer()

            PrimaryButton(title: "Start Recording", icon: "mic.fill", action: onStart)
                .padding(.horizontal, Tokens.Spacing.xl)
                .padding(.bottom, Tokens.Spacing.xl)
        }
    }
}
