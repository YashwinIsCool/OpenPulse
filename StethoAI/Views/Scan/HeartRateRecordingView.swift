import SwiftUI

struct HeartRateRecordingView: View {
    @ObservedObject var camera: PPGCameraManager
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: Tokens.Spacing.xl) {
            HStack {
                Spacer()
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(Tokens.Fonts.body)
                        .foregroundStyle(Tokens.Colors.primaryRed)
                }
            }
            .padding(.horizontal, Tokens.Spacing.lg)
            .padding(.top, Tokens.Spacing.sm)

            Spacer()

            Text("\(camera.secondsRemaining)")
                .font(.system(size: 72, weight: .bold))
                .foregroundStyle(Tokens.Colors.primaryRed)
                .monospacedDigit()

            Text("seconds remaining")
                .font(Tokens.Fonts.body)
                .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)

            WaveformView(samples: camera.waveform)
                .frame(height: 120)
                .padding(.horizontal, Tokens.Spacing.xxl)

            if !camera.cameraAvailable {
                Text("No camera detected — showing a simulated reading.")
                    .font(Tokens.Fonts.caption)
                    .foregroundStyle(Tokens.Colors.adaptiveTextQuaternary)
            } else {
                Text("Keep your finger still and covering the lens.")
                    .font(Tokens.Fonts.caption)
                    .foregroundStyle(Tokens.Colors.adaptiveTextQuaternary)
            }

            Spacer()
            Spacer()
        }
    }
}
