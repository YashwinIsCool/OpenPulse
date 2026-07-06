import SwiftUI
import SwiftData

private enum HeartRateStep {
    case instructions, recording, result, failed
}

struct HeartRateFlowView: View {
    let user: User

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var camera = PPGCameraManager()

    @State private var step: HeartRateStep = .instructions
    @State private var resultBPM: Int = 0
    @State private var resultHRV: Double?

    var body: some View {
        ZStack {
            Tokens.Colors.adaptiveBackground.ignoresSafeArea()

            switch step {
            case .instructions:
                HeartRateInstructionsView(
                    onStart: { startRecording() },
                    onCancel: { dismiss() }
                )
            case .recording:
                HeartRateRecordingView(camera: camera, onCancel: { cancelRecording() })
            case .result:
                HeartRateResultView(
                    user: user,
                    bpm: resultBPM,
                    hrvMs: resultHRV,
                    onSave: { saveAndFinish() }
                )
            case .failed:
                HeartRateFailedView(
                    onRetry: { step = .instructions },
                    onCancel: { dismiss() }
                )
            }
        }
    }

    private func startRecording() {
        step = .recording
        camera.onFinished = { bpm, hrv in
            if let bpm {
                resultBPM = bpm
                resultHRV = hrv
                step = .result
            } else {
                step = .failed
            }
        }
        camera.start()
    }

    private func cancelRecording() {
        camera.cancel()
        dismiss()
    }

    private func saveAndFinish() {
        let category = HeartRateCategory.categorize(bpm: resultBPM)
        let reading = HeartRateReading(bpm: resultBPM, hrvMs: resultHRV, category: category, source: .auto)
        modelContext.insert(reading)
        StreakManager.recordCheckIn(for: user)
        NotificationManager.shared.cancelStreakProtection()
        dismiss()
    }
}

private struct HeartRateFailedView: View {
    let onRetry: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: Tokens.Spacing.xl) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(Tokens.Colors.warningAmber)
            Text("Couldn't get a clear reading")
                .font(Tokens.Fonts.sectionHeading)
                .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
            Text("Make sure your finger fully covers the camera and flash, and hold still.")
                .font(Tokens.Fonts.body)
                .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Tokens.Spacing.xxl)
            Spacer()
            VStack(spacing: Tokens.Spacing.sm) {
                PrimaryButton(title: "Try Again", action: onRetry)
                SecondaryButton(title: "Cancel", action: onCancel)
            }
            .padding(.horizontal, Tokens.Spacing.xl)
            .padding(.bottom, Tokens.Spacing.xl)
        }
    }
}
