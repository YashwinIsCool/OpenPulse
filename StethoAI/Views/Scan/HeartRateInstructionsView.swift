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

/// An animated illustration of the back of a phone: a fingertip slides in from the
/// side, settles over the rear camera + flash, and glows red where the flash shines
/// through it — then repeats. Shows users exactly where and how to place their finger.
private struct FingerPlacementDiagram: View {
    @State private var inPlace = false
    private let timer = Timer.publish(every: 4.4, on: .main, in: .common).autoconnect()

    // Finger group rest position (fingertip over the camera) vs. off-screen start.
    private let targetX: CGFloat = 24
    private let startX: CGFloat = 210
    private let fingerY: CGFloat = -64

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

            // A horizontal finger that slides in from the side; its tip covers the
            // lens + flash (the lower lens stays visible) and glows once in place.
            finger(glow: inPlace ? 1 : 0)
                .offset(x: inPlace ? targetX : startX, y: fingerY)
                .animation(.easeInOut(duration: 1.7), value: inPlace)
        }
        .frame(width: 240, height: 250)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .onReceive(timer) { _ in inPlace.toggle() }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { inPlace = true }
        }
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

    private var skin: Color { Color(red: 0.90, green: 0.64, blue: 0.53) }

    private func finger(glow: Double) -> some View {
        // A horizontal finger: rounded fingertip on the left, extending off to the
        // right. Drawn as a capsule so the tip is naturally rounded.
        ZStack(alignment: .leading) {
            Capsule()
                .fill(skin)
                .frame(width: 132, height: 46)
                .overlay(
                    Capsule().stroke(Color(red: 0.72, green: 0.48, blue: 0.40), lineWidth: 1)
                )
                // Subtle knuckle crease for a more finger-like look.
                .overlay(
                    Capsule()
                        .fill(Color(red: 0.72, green: 0.48, blue: 0.40).opacity(0.18))
                        .frame(width: 4, height: 34)
                        .offset(x: 34)
                )

            // Red glow at the very tip, where the flash shines through the finger —
            // fades in only once the finger has arrived over the camera. Small, so
            // it reads as covering just the lens + flash, not the whole phone.
            ZStack {
                Circle()
                    .fill(Tokens.Colors.primaryRed.opacity(0.55))
                    .frame(width: 38, height: 38)
                Circle()
                    .fill(Color(red: 0.98, green: 0.45, blue: 0.42))
                    .frame(width: 18, height: 18)
            }
            .opacity(glow)
            .offset(x: 6)
            .animation(.easeInOut(duration: 0.5).delay(glow > 0 ? 0.9 : 0), value: glow)
        }
    }
}
