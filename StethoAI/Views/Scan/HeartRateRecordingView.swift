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

            if camera.isMeasuring {
                measuringContent
            } else {
                lockingContent
            }

            WaveformView(samples: camera.waveform)
                .frame(height: 120)
                .padding(.horizontal, Tokens.Spacing.xxl)
                .opacity(camera.signalQuality == .searching && !camera.isMeasuring ? 0.35 : 1)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Before lock: live guidance

    private var lockingContent: some View {
        VStack(spacing: Tokens.Spacing.md) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 120, height: 120)
                Image(systemName: statusIcon)
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(statusColor)
                    .symbolEffect(.pulse, options: .repeating, isActive: camera.signalQuality != .good)
            }

            Text(statusTitle)
                .font(Tokens.Fonts.sectionHeading)
                .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)

            Text(statusSubtitle)
                .font(Tokens.Fonts.body)
                .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Tokens.Spacing.xxl)
                .frame(minHeight: 40)
        }
    }

    private var statusColor: Color {
        switch camera.signalQuality {
        case .searching: return Tokens.Colors.textQuaternary
        case .weak: return Tokens.Colors.warningAmber
        case .good: return Tokens.Colors.successGreen
        }
    }

    private var statusIcon: String {
        switch camera.signalQuality {
        case .searching: return "magnifyingglass"
        case .weak: return "hand.point.up.left"
        case .good: return "checkmark.circle.fill"
        }
    }

    private var statusTitle: String {
        switch camera.signalQuality {
        case .searching: return "Searching for pulse…"
        case .weak: return "Almost — adjust your finger"
        case .good: return "Good signal! Hold still"
        }
    }

    private var statusSubtitle: String {
        switch camera.signalQuality {
        case .searching:
            return camera.cameraAvailable
                ? "Cover the camera and flash fully with your fingertip."
                : "Preparing a simulated reading…"
        case .weak:
            return "Rest your finger flat and gently — don't press hard."
        case .good:
            return "Keep holding — the timer is about to start."
        }
    }

    // MARK: - During measurement: countdown

    private var measuringContent: some View {
        VStack(spacing: Tokens.Spacing.sm) {
            Text("\(camera.secondsRemaining)")
                .font(.system(size: 72, weight: .bold))
                .foregroundStyle(camera.isPaused ? Tokens.Colors.warningAmber : Tokens.Colors.primaryRed)
                .monospacedDigit()

            Text("seconds remaining")
                .font(Tokens.Fonts.body)
                .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)

            if camera.isPaused {
                Label("Paused — put your finger back on the lens", systemImage: "pause.circle.fill")
                    .font(Tokens.Fonts.caption)
                    .foregroundStyle(Tokens.Colors.warningAmber)
                    .multilineTextAlignment(.center)
                    .padding(.top, Tokens.Spacing.xs)
            } else {
                Label("Reading your pulse — hold still", systemImage: "heart.fill")
                    .font(Tokens.Fonts.caption)
                    .foregroundStyle(Tokens.Colors.successGreen)
                    .padding(.top, Tokens.Spacing.xs)
            }
        }
    }
}
