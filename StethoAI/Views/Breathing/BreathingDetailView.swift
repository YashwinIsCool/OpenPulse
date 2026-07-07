import SwiftUI
import SwiftData

struct BreathingDetailView: View {
    let user: User
    let exerciseType: BreathingExerciseType

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var elapsed: Int = 0
    @State private var scale: CGFloat = 0.6
    @State private var currentLabel: String = ""
    @State private var isFinished = false
    @State private var isPresentingHeartRateCheck = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var cycleLength: Int {
        exerciseType.phases.reduce(0) { $0 + $1.seconds }
    }

    private var secondsRemainingTotal: Int {
        max(0, exerciseType.durationSeconds - elapsed)
    }

    var body: some View {
        Group {
            if isFinished {
                completionView
            } else {
                exerciseView
            }
        }
        .background(Tokens.Colors.adaptiveBackground.ignoresSafeArea())
        .navigationBarHidden(true)
        .onReceive(timer) { _ in tick() }
        .onAppear { updatePhase(force: true) }
    }

    private var exerciseView: some View {
        VStack(spacing: Tokens.Spacing.xxl) {
            HStack {
                Spacer()
                Button("Skip") { finish() }
                    .font(Tokens.Fonts.body)
                    .foregroundStyle(Tokens.Colors.primaryRed)
            }
            .padding(.horizontal, Tokens.Spacing.lg)
            .padding(.top, Tokens.Spacing.sm)

            Spacer()

            ZStack {
                Circle()
                    .fill(Tokens.Colors.lightRedTint)
                    .frame(width: 220, height: 220)
                    .scaleEffect(scale)
                Circle()
                    .fill(Tokens.Colors.primaryRed)
                    .frame(width: 220, height: 220)
                    .scaleEffect(scale * 0.7)
                Text(currentLabel)
                    .font(Tokens.Fonts.sectionHeading)
                    .foregroundStyle(.white)
            }

            Text(timeString(secondsRemainingTotal))
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                .monospacedDigit()

            Spacer()
            Spacer()

            Button("End") { finish() }
                .font(Tokens.Fonts.cardTitle)
                .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                .padding(.bottom, Tokens.Spacing.xl)
        }
    }

    private var completionView: some View {
        VStack(spacing: Tokens.Spacing.xl) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48))
                .foregroundStyle(Tokens.Colors.successGreen)
            Text("Nice work")
                .font(Tokens.Fonts.pageTitle)
                .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
            Text("Want to see the effect on your heart rate?")
                .font(Tokens.Fonts.body)
                .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                .multilineTextAlignment(.center)
            Spacer()
            VStack(spacing: Tokens.Spacing.sm) {
                PrimaryButton(title: "Take a Heart Rate Reading", icon: "heart.fill") {
                    isPresentingHeartRateCheck = true
                }
                SecondaryButton(title: "Done", action: { dismiss() })
            }
            .padding(.horizontal, Tokens.Spacing.xl)
            .padding(.bottom, Tokens.Spacing.xl)
        }
        .fullScreenCover(isPresented: $isPresentingHeartRateCheck) {
            HeartRateFlowView(user: user)
        }
    }

    private func tick() {
        guard !isFinished else { return }
        elapsed += 1
        updatePhase(force: false)
        if elapsed >= exerciseType.durationSeconds {
            finish()
        }
    }

    private func updatePhase(force: Bool) {
        let t = elapsed % cycleLength
        var acc = 0
        var label = exerciseType.phases[0].label
        var phaseDuration = exerciseType.phases[0].seconds
        for phase in exerciseType.phases {
            if t < acc + phase.seconds {
                label = phase.label
                phaseDuration = phase.seconds
                break
            }
            acc += phase.seconds
        }

        guard force || label != currentLabel else { return }
        currentLabel = label
        let lowered = label.lowercased()
        let target: CGFloat = lowered.contains("in") ? 1.0 : (lowered.contains("out") ? 0.6 : scale)
        withAnimation(.easeInOut(duration: Double(phaseDuration))) {
            scale = target
        }
    }

    private func finish() {
        guard !isFinished else { return }
        isFinished = true
        modelContext.insert(BreathingSession(exerciseType: exerciseType, duration: elapsed))
        StreakManager.updateStreakIfDayComplete(context: modelContext, user: user)
    }

    private func timeString(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
