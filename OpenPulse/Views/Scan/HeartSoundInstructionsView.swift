import SwiftUI

struct HeartSoundInstructionsView: View {
    let onStart: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                        .padding(10)
                        .background(Tokens.Colors.adaptiveCard)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Close")
            }
            .padding(.top, Tokens.Spacing.sm)

            VStack(alignment: .leading, spacing: Tokens.Spacing.xxl) {
                VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
                    Text("Record your heart sound")
                        .font(Tokens.Fonts.screenTitle)
                        .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                    Text("A 30-second recording you can play back or share with a doctor. The app records it; it doesn't diagnose it.")
                        .font(Tokens.Fonts.bodyText)
                        .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: Tokens.Spacing.lg) {
                    step(1, "Find a quiet room.")
                    step(2, "Press the bottom of the phone, where the microphone is, flat against your chest, just left of your breastbone.")
                    step(3, "Breathe normally and hold still. The phone buzzes when the 30 seconds are up.")
                }
            }
            .padding(.top, Tokens.Spacing.lg)

            Spacer()

            PrimaryButton(title: "Start recording", icon: "mic.fill", action: onStart)
                .padding(.bottom, Tokens.Spacing.xl)
        }
        .padding(.horizontal, Tokens.Spacing.xl)
    }

    private func step(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: Tokens.Spacing.md) {
            Text("\(number)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Tokens.Colors.onInk)
                .frame(width: 26, height: 26)
                .background(Tokens.Colors.ink)
                .clipShape(Circle())
            Text(text)
                .font(Tokens.Fonts.bodyText)
                .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
