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
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                        .padding(10)
                        .background(Tokens.Colors.adaptiveCard)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Close")
            }
            .padding(.horizontal, Tokens.Spacing.xl)
            .padding(.top, Tokens.Spacing.sm)

            ScrollView {
                VStack(alignment: .leading, spacing: Tokens.Spacing.xxl) {
                    Text("Heart rate check")
                        .font(Tokens.Fonts.screenTitle)
                        .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)

                    FingerPlacementDiagram()
                        .frame(maxWidth: .infinity)

                    VStack(alignment: .leading, spacing: Tokens.Spacing.lg) {
                        step(1, "Cover the camera lens and the flash beside it with one fingertip. Your middle finger reaches most easily.")
                        step(2, "Rest it lightly. Pressing hard hides your pulse.")
                        step(3, "Sit still for 30 seconds. On the next screen, a circle turns bright red when your finger is in the right spot.")
                    }
                }
                .padding(.horizontal, Tokens.Spacing.xl)
                .padding(.vertical, Tokens.Spacing.lg)
            }

            PrimaryButton(title: "Start", action: onStart)
                .padding(.horizontal, Tokens.Spacing.xl)
                .padding(.bottom, Tokens.Spacing.xl)
        }
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

/// An animated illustration of the back of a phone: a fingertip slides in from the
/// side, settles over the rear camera + flash, and glows red where the flash shines
/// through it — then repeats. Shows users exactly where and how to place their finger.
private struct FingerPlacementDiagram: View {
    @State private var inPlace = false
    private let timer = Timer.publish(every: 4.4, on: .main, in: .common).autoconnect()

    // Finger group rest position (fingertip over the camera) vs. off-screen start.
    // The finger enters from the left, tip pointing right toward the camera.
    private let targetX: CGFloat = -66
    private let startX: CGFloat = -220
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
        // A horizontal finger: rounded fingertip on the right, extending off to the
        // left. Drawn as a capsule so the tip is naturally rounded.
        ZStack(alignment: .trailing) {
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
                        .offset(x: -34)
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
            .offset(x: -6)
            .animation(.easeInOut(duration: 0.5).delay(glow > 0 ? 0.9 : 0), value: glow)
        }
    }
}
