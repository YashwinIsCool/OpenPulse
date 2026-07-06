import SwiftUI

struct WelcomeView: View {
    let onNext: () -> Void

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: Tokens.Spacing.lg) {
                Image(systemName: "waveform.path.ecg.rectangle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Tokens.Colors.primaryRed)

                Text("StethoAI")
                    .font(Tokens.Fonts.display)
                    .tracking(Tokens.Tracking.display)
                    .foregroundStyle(Tokens.Colors.primaryRed)

                Text("Understand your heart in seconds")
                    .font(Tokens.Fonts.sectionHeading)
                    .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                    .multilineTextAlignment(.center)

                VStack(spacing: Tokens.Spacing.xs) {
                    Text("Check your heart rate daily with just your camera.")
                    Text("Track heart sounds, trends, and habits over time.")
                }
                .font(Tokens.Fonts.body)
                .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Tokens.Spacing.xxl)

            Spacer()
            Spacer()

            VStack(spacing: Tokens.Spacing.sm) {
                PrimaryButton(title: "Get Started", icon: "arrow.right", action: onNext)
                Text("Wellness & education only — not a medical device.")
                    .font(Tokens.Fonts.caption)
                    .foregroundStyle(Tokens.Colors.adaptiveTextQuaternary)
            }
            .padding(.horizontal, Tokens.Spacing.xxl)
            .padding(.bottom, Tokens.Spacing.xl)
        }
    }
}
