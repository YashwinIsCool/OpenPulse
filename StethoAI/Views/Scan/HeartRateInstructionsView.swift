import SwiftUI

struct HeartRateInstructionsView: View {
    let onStart: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
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

            ScrollView {
                VStack(spacing: Tokens.Spacing.xl) {
                    Text("Heart rate check")
                        .font(Tokens.Fonts.pageTitle)
                        .tracking(Tokens.Tracking.pageTitle)
                        .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)

                    FingerPlacementDiagram()

                    Text("Cover the rear camera **and** the flash with your fingertip, so no light leaks out.")
                        .font(Tokens.Fonts.body)
                        .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Tokens.Spacing.xxl)

                    VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
                        tip(icon: "hand.point.up.left.fill", text: "Rest your fingertip flat over the camera — gently, don't press hard.")
                        tip(icon: "lightbulb.fill", text: "Your fingertip should glow red once the flash turns on.")
                        tip(icon: "checkmark.circle.fill", text: "Hold still and wait — the timer starts once it finds a good signal.")
                    }
                    .padding(Tokens.Spacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Tokens.Colors.adaptiveCard)
                    .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.card, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Tokens.Radius.card, style: .continuous)
                            .stroke(Tokens.Colors.adaptiveBorder, lineWidth: 1)
                    )
                    .padding(.horizontal, Tokens.Spacing.lg)
                }
                .padding(.vertical, Tokens.Spacing.xl)
            }

            PrimaryButton(title: "Start", icon: "play.fill", action: onStart)
                .padding(.horizontal, Tokens.Spacing.xl)
                .padding(.bottom, Tokens.Spacing.xl)
        }
    }

    private func tip(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: Tokens.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Tokens.Colors.primaryRed)
                .frame(width: 24)
            Text(text)
                .font(Tokens.Fonts.body)
                .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// A small illustration of the back of a phone showing a fingertip resting over the
/// rear camera lens and flash — the correct position for a PPG heart-rate reading.
private struct FingerPlacementDiagram: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Tokens.Colors.adaptiveSoftRedSurface)
                .frame(width: 240, height: 250)

            // Phone body (viewed from the back).
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color(white: 0.16))
                .frame(width: 132, height: 212)
                .overlay(alignment: .topLeading) {
                    cameraCluster
                        .padding(14)
                }

            // Fingertip resting over the camera cluster, glowing red where the
            // flash shines through it.
            fingertip
                .offset(x: -18, y: -44)
        }
        .frame(height: 250)
    }

    private var cameraCluster: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(white: 0.24))
                .frame(width: 68, height: 68)

            lens.offset(x: -14, y: -14)
            flash.offset(x: 14, y: -14)
            lens.offset(x: 14, y: 14)
        }
    }

    private var lens: some View {
        Circle()
            .fill(Color(white: 0.05))
            .frame(width: 26, height: 26)
            .overlay(Circle().stroke(Color(white: 0.35), lineWidth: 2))
            .overlay(Circle().fill(Color(red: 0.1, green: 0.2, blue: 0.4)).frame(width: 11, height: 11))
    }

    private var flash: some View {
        Circle()
            .fill(Color(red: 1.0, green: 0.9, blue: 0.6))
            .frame(width: 13, height: 13)
    }

    private var fingertip: some View {
        ZStack {
            Ellipse()
                .fill(Color(red: 0.89, green: 0.63, blue: 0.52))
                .frame(width: 84, height: 116)
            Ellipse()
                .fill(Tokens.Colors.primaryRed.opacity(0.55))
                .frame(width: 48, height: 64)
            Ellipse()
                .fill(Color(red: 0.98, green: 0.45, blue: 0.42))
                .frame(width: 24, height: 34)
        }
        .overlay(alignment: .bottom) {
            // Fingernail hint at the base of the finger.
            Ellipse()
                .fill(Color(red: 0.95, green: 0.78, blue: 0.72))
                .frame(width: 40, height: 22)
                .offset(y: 8)
        }
    }
}
