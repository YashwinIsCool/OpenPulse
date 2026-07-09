import SwiftUI
import SwiftData

/// A guided, one-tap run through the day's plan: baseline heart rate → daily
/// check-in → breathing → a second heart rate reading → a results screen showing
/// how the reading changed and how the user feels. Replaces tapping each task by hand.
struct DailyPlanFlowView: View {
    let user: User

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var dailyLogs: [DailyLog]

    @StateObject private var camera = PPGCameraManager()

    enum Stage { case baseline, after }
    enum Phase: Equatable {
        case hrInstructions(Stage)
        case hrRecording(Stage)
        case hrResult(Stage)
        case hrFailed(Stage)
        case checkIn
        case breathing
        case results
    }

    @State private var phase: Phase = .hrInstructions(.baseline)
    @State private var baselineBPM: Int?
    @State private var afterBPM: Int?
    @State private var pendingBPM: Int = 0
    @State private var pendingHRV: Double?
    @State private var breathingType: BreathingExerciseType = .fourSevenEight
    @State private var feeling: Int?

    var body: some View {
        ZStack {
            Tokens.Colors.adaptiveBackground.ignoresSafeArea()

            switch phase {
            case .hrInstructions(let stage):
                HeartRateInstructionsView(
                    onStart: { enterRecording(stage) },
                    onCancel: { exitPlan() }
                )
                .overlay(alignment: .top) {
                    stepBadge(step: stage == .baseline ? 1 : 4)
                }
            case .hrRecording:
                HeartRateRecordingView(camera: camera, onCancel: {
                    camera.cancel()
                    exitPlan()
                })
            case .hrResult(let stage):
                HeartRateResultView(user: user, bpm: pendingBPM, hrvMs: pendingHRV) {
                    saveReading(bpm: pendingBPM, hrv: pendingHRV)
                    if stage == .baseline {
                        baselineBPM = pendingBPM
                        phase = .checkIn
                    } else {
                        // In demo mode, show a clean downward change for screenshots.
                        if AppSettings.shared.isDemoMode, let b = baselineBPM {
                            afterBPM = max(58, b - Int.random(in: 6...12))
                        } else {
                            afterBPM = pendingBPM
                        }
                        phase = .results
                    }
                }
            case .hrFailed(let stage):
                failedView(stage)
            case .checkIn:
                stepChrome(step: 2) {
                    DailyCheckInForm(initial: todayCheckIn, saveTitle: "Save & continue") { data in
                        saveCheckIn(data)
                        phase = .breathing
                    }
                }
            case .breathing:
                BreathingDetailView(user: user, exerciseType: breathingType, onComplete: {
                    phase = .hrInstructions(.after)
                })
            case .results:
                resultsView
            }
        }
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }

    // MARK: - Results

    private var resultsView: some View {
        ScrollView {
            VStack(spacing: Tokens.Spacing.xl) {
                HStack {
                    Spacer()
                    closeButton
                }

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Tokens.Colors.successGreen)

                Text("Plan complete!")
                    .font(Tokens.Fonts.pageTitle)
                    .tracking(Tokens.Tracking.pageTitle)
                    .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)

                heartRateChangeCard

                VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
                    Text("How do you feel now?")
                        .font(Tokens.Fonts.cardTitle)
                        .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                    ScaleRow(range: 1...5, lowLabel: "Rough", highLabel: "Great", selected: $feeling)
                }
                .padding(Tokens.Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Tokens.Colors.adaptiveCard)
                .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.card, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Tokens.Radius.card, style: .continuous).stroke(Tokens.Colors.adaptiveBorder, lineWidth: 1))

                DisclaimerFooter(text: "For informational use only. Not medical advice.")

                PrimaryButton(title: "Finish", icon: "checkmark") { finishPlan() }
                    .padding(.top, Tokens.Spacing.sm)
            }
            .padding(Tokens.Spacing.lg)
        }
    }

    private var heartRateChangeCard: some View {
        VStack(spacing: Tokens.Spacing.md) {
            Text("YOUR HEART RATE")
                .font(Tokens.Fonts.microLabel)
                .tracking(Tokens.Tracking.microLabel)
                .foregroundStyle(.white.opacity(0.9))

            HStack(alignment: .firstTextBaseline, spacing: Tokens.Spacing.lg) {
                bpmColumn(label: "Before", value: baselineBPM)
                Image(systemName: "arrow.right")
                    .foregroundStyle(.white.opacity(0.9))
                bpmColumn(label: "After", value: afterBPM)
            }

            if let change = changeText {
                Text(change)
                    .font(Tokens.Fonts.body)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(Tokens.Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(Tokens.Colors.primaryRed)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func bpmColumn(label: String, value: Int?) -> some View {
        VStack(spacing: 2) {
            Text(value.map(String.init) ?? "—")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(.white)
            Text(label)
                .font(Tokens.Fonts.caption)
                .foregroundStyle(.white.opacity(0.9))
        }
    }

    private var changeText: String? {
        guard let b = baselineBPM, let a = afterBPM else { return nil }
        let diff = a - b
        if diff < 0 { return "Your heart rate dropped \(abs(diff)) bpm — nice work calming down." }
        if diff > 0 { return "Your heart rate rose \(diff) bpm. That's normal some days — keep at it." }
        return "Your heart rate held steady."
    }

    // MARK: - Failed

    private func failedView(_ stage: Stage) -> some View {
        VStack(spacing: Tokens.Spacing.xl) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundStyle(Tokens.Colors.warningAmber)
            Text("Couldn't get a clear reading")
                .font(Tokens.Fonts.sectionHeading)
                .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
            Text("Make sure your fingertip fully covers the camera and flash, then try again.")
                .font(Tokens.Fonts.body)
                .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Tokens.Spacing.xxl)
            Spacer()
            VStack(spacing: Tokens.Spacing.sm) {
                PrimaryButton(title: "Try again", icon: "arrow.clockwise") { phase = .hrInstructions(stage) }
                SecondaryButton(title: "Skip this step", icon: "forward.fill") {
                    if stage == .baseline { phase = .checkIn } else { phase = .results }
                }
            }
            .padding(.horizontal, Tokens.Spacing.xl)
            .padding(.bottom, Tokens.Spacing.xl)
        }
    }

    // MARK: - Chrome

    private func stepBadge(step: Int) -> some View {
        Text("Step \(step) of 5")
            .font(Tokens.Fonts.caption)
            .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
            .padding(.top, Tokens.Spacing.md)
    }

    private func stepChrome<Content: View>(step: Int, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("Step \(step) of 5")
                    .font(Tokens.Fonts.caption)
                    .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                Spacer()
                closeButton
            }
            .padding(.horizontal, Tokens.Spacing.lg)
            .padding(.top, Tokens.Spacing.sm)
            content()
        }
    }

    private var closeButton: some View {
        Button(action: { exitPlan() }) {
            Image(systemName: "xmark")
                .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                .padding(Tokens.Spacing.sm)
                .background(Tokens.Colors.adaptiveCard)
                .clipShape(Circle())
        }
    }

    // MARK: - Logic

    private func enterRecording(_ stage: Stage) {
        phase = .hrRecording(stage)
        camera.onFinished = { bpm, hrv in
            if let bpm {
                pendingBPM = bpm
                pendingHRV = hrv
                phase = .hrResult(stage)
            } else {
                phase = .hrFailed(stage)
            }
        }
        camera.start()
    }

    private func saveReading(bpm: Int, hrv: Double?) {
        let reading = HeartRateReading(bpm: bpm, hrvMs: hrv, category: HeartRateCategory.categorize(bpm: bpm), source: .auto)
        modelContext.insert(reading)
    }

    private var todayLog: DailyLog? {
        dailyLogs.first { Calendar.current.isDateInToday($0.date) }
    }

    private var todayCheckIn: CheckInData {
        guard let log = todayLog else { return CheckInData() }
        return CheckInData(sleepHours: log.sleepHours, caffeineCups: log.caffeineCups, exerciseMinutes: log.exerciseMinutes, stressLevel: log.stressLevel, mood: log.mood)
    }

    private func saveCheckIn(_ data: CheckInData) {
        let log = todayLog ?? {
            let new = DailyLog()
            modelContext.insert(new)
            return new
        }()
        log.sleepHours = data.sleepHours
        log.caffeineCups = data.caffeineCups
        log.exerciseMinutes = data.exerciseMinutes
        log.stressLevel = data.stressLevel
        log.mood = data.mood
    }

    private func finishPlan() {
        if let feeling {
            let log = todayLog ?? {
                let new = DailyLog()
                modelContext.insert(new)
                return new
            }()
            log.postPlanFeeling = feeling
        }
        StreakManager.updateStreakIfDayComplete(context: modelContext, user: user)
        NotificationManager.shared.cancelStreakProtection()
        dismiss()
    }

    private func exitPlan() {
        camera.cancel()
        dismiss()
    }
}
