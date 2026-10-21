import SwiftUI

/// The live heart-rate reading. The centerpiece is a circle filled with the exact
/// color the camera sees, so placement is obvious: dark or patchy means the finger
/// isn't covering the lens and flash; bright, even red means it's right. One short
/// instruction underneath always says what to do next.
struct HeartRateRecordingView: View {
    @ObservedObject var camera: PPGCameraManager
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: Tokens.Spacing.xl) {
            HStack {
                Spacer()
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.body.weight(.medium))
                        .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                }
            }
            .padding(.horizontal, Tokens.Spacing.lg)
            .padding(.top, Tokens.Spacing.sm)

            Spacer()

            fingerSwatch

            VStack(spacing: Tokens.Spacing.sm) {
                Text(instruction.title)
                    .font(Tokens.Fonts.headline)
                    .foregroundStyle(instruction.color)
                    .multilineTextAlignment(.center)
                Text(instruction.detail)
                    .font(Tokens.Fonts.bodyText)
                    .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                    .multilineTextAlignment(.center)
                    .frame(minHeight: 44, alignment: .top)
            }
            .padding(.horizontal, Tokens.Spacing.xxl)
            .animation(.easeInOut(duration: 0.2), value: instruction.title)

            WaveformView(samples: camera.waveform)
                .frame(height: 90)
                .padding(.horizontal, Tokens.Spacing.xxl)
                .opacity(camera.signalQuality == .searching ? 0.25 : 1)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Live camera color

    private var fingerSwatch: some View {
        let c = camera.liveColor
        return ZStack {
            Circle()
                .fill(Color(red: c.red, green: c.green, blue: c.blue))
                .frame(width: 168, height: 168)
                .animation(.linear(duration: 0.15), value: c.red)
            Circle()
                .stroke(Tokens.Colors.adaptiveBorder, lineWidth: 2)
                .frame(width: 168, height: 168)

            if camera.isMeasuring && !camera.isExtending && !camera.isPaused {
                Text("\(camera.secondsRemaining)")
                    .font(.system(size: 56, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.25), radius: 4)
            } else if camera.isExtending {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(instruction.title)
    }

    // MARK: - What to do now

    private struct Instruction {
        let title: String
        let detail: String
        let color: Color
    }

    private var instruction: Instruction {
        let ink = Tokens.Colors.adaptiveTextPrimary
        if !camera.cameraAvailable {
            return Instruction(title: "Reading your pulse", detail: "Preparing a simulated reading…", color: ink)
        }
        if camera.isPaused {
            return Instruction(title: "Put your finger back on the camera",
                               detail: "The timer will continue when it's covered again.",
                               color: Tokens.Colors.statusWatch)
        }
        if camera.signalQuality == .searching {
            return Instruction(title: "Cover the camera and the flash",
                               detail: "Rest one fingertip over the back camera lens and the light beside it. The circle should turn bright red.",
                               color: ink)
        }
        if camera.pressingTooHard {
            return Instruction(title: "Press a little lighter",
                               detail: "Rest your finger gently. Pressing hard hides your pulse.",
                               color: Tokens.Colors.statusWatch)
        }
        if camera.isExtending {
            return Instruction(title: "Almost there, keep holding",
                               detail: "A few more seconds for a clean reading.",
                               color: ink)
        }
        if !camera.isMeasuring {
            return Instruction(title: "Good, hold still",
                               detail: "Starting in a moment.",
                               color: Tokens.Colors.statusGood)
        }
        if camera.signalQuality == .good {
            return Instruction(title: "Reading your pulse",
                               detail: "Keep still and breathe normally.",
                               color: Tokens.Colors.statusGood)
        }
        return Instruction(title: "Hold still",
                           detail: "Finding a clearer pulse. Keep your finger relaxed.",
                           color: ink)
    }
}
