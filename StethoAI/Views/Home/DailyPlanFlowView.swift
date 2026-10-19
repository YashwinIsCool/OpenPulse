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
        case breathingSetup
        case breathing
        case results
    }

    @State private var phase: Phase = .hrInstructions(.baseline)
    @State private var baselineBPM: Int?
    @State private var afterBPM: Int?
    @State private var pendingBPM: Int = 0
    @State private var pendingHRV: Double?
    @State private var breathingType: BreathingExerciseType = .fourSevenEight
    @State private var breathingSeconds: Int = 60
    @State private var feeling: Int?

    private let breathingOptions: [(label: String, seconds: Int)] = [
        ("30 sec", 30), ("1 min", 60), ("2 min", 120), ("3 min", 180)
    ]

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
                        phase = .breathingSetup
                    }
                }
            case .breathingSetup:
                stepChrome(step: 3) { breathingSetupView }
            case .breathing:
                BreathingDetailView(user: user, exerciseType: breathingType, onComplete: {
                    phase = .hrInstructions(.after)
                }, durationOverride: breathingSeconds)
            case .results:
                resultsView
            }
        }
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }

    // MARK: - Breathing setup

    private var breathingSetupView: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.xxl) {
            VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
                Text("Breathing exercise")
                    .font(Tokens.Fonts.screenTitle)
                    .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                Text("A slow, calm exercise to settle your heart. How long would you like?")
                    .font(Tokens.Fonts.bodyText)
                    .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
            }

            HStack(spacing: Tokens.Spacing.sm) {
                ForEach(breathingOptions, id: \.seconds) { option in
                    ChoiceChip(label: option.label, isSelected: breathingSeconds == option.seconds) {
                        withAnimation(.easeInOut(duration: 0.12)) { breathingSeconds = option.seconds }
                    }
                }
            }

            Spacer()

            PrimaryButton(title: "Start breathing") {
                phase = .breathing
            }
        }
        .padding(.horizontal, Tokens.Spacing.xl)
        .padding(.top, Tokens.Spacing.xxl)
        .padding(.bottom, Tokens.Spacing.xl)
    }

    // MARK: - Results

    private var resultsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Spacing.xxl) {
                HStack {
                    Spacer()
                    closeButton
                }

                VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
                    Text("All done")
                        .font(Tokens.Fonts.screenTitle)
                        .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                    if let change = changeText {
                        Text(change)
                            .font(Tokens.Fonts.bodyText)
                            .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                    }
                }

                heartRateChange

                VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
                    Text("How do you feel now?")
                        .font(.headline)
                        .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                    ScaleRow(range: 1...5, lowLabel: "Rough", highLabel: "Great", selected: $feeling)
                }
            }
            .padding(.horizontal, Tokens.Spacing.xl)
            .padding(.top, Tokens.Spacing.sm)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: Tokens.Spacing.sm) {
                PrimaryButton(title: "Finish") { finishPlan() }
                DisclaimerFooter(text: "For informational use only. Not medical advice.")
            }
            .padding(.horizontal, Tokens.Spacing.xl)
            .padding(.vertical, Tokens.Spacing.sm)
            .background(Tokens.Colors.adaptiveBackground)
        }
    }

    private var heartRateChange: some View {
        HStack(spacing: 0) {
            bpmColumn(label: "Before", value: baselineBPM)
            Rectangle()
                .fill(Tokens.Colors.adaptiveBorder)
                .frame(width: 1, height: 56)
            bpmColumn(label: "After breathing", value: afterBPM)
        }
        .padding(.vertical, Tokens.Spacing.lg)
        .background(Tokens.Colors.adaptiveCard)
        .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Tokens.Radius.card, style: .continuous)
                .stroke(Tokens.Colors.adaptiveBorder, lineWidth: 1)
        )
    }

    private func bpmColumn(label: String, value: Int?) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(Tokens.Fonts.secondaryText)
                .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value.map(String.init) ?? "—")
                    .font(.system(size: 40, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                Text("bpm")
                    .font(Tokens.Fonts.secondaryText)
                    .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var changeText: String? {
        guard let b = baselineBPM, let a = afterBPM else { return nil }
        let diff = a - b
        if diff < 0 { return "Your heart rate went down \(abs(diff)) bpm after breathing." }
        if diff > 0 { return "Your heart rate went up \(diff) bpm. That happens some days." }
        return "Your heart rate stayed the same."
    }

    // MARK: - Failed

    private func failedView(_ stage: Stage) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
            Spacer()
            Text("Couldn't get a clear reading")
                .font(Tokens.Fonts.screenTitle)
                .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
            Text("Make sure your fingertip fully covers the camera and flash, then try again.")
                .font(Tokens.Fonts.bodyText)
                .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
            Spacer()
            VStack(spacing: Tokens.Spacing.sm) {
                PrimaryButton(title: "Try again") { phase = .hrInstructions(stage) }
                SecondaryButton(title: "Skip this step") {
                    if stage == .baseline { phase = .checkIn } else { phase = .results }
                }
            }
        }
        .padding(.horizontal, Tokens.Spacing.xl)
        .padding(.bottom, Tokens.Spacing.xl)
    }

    // MARK: - Chrome

    /// Five short segments that fill in as the plan moves along.
    private func progressBar(step: Int) -> some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { i in
                Capsule()
                    .fill(i <= step ? Tokens.Colors.ink : Tokens.Colors.adaptiveBorder)
                    .frame(height: 4)
            }
        }
        .frame(maxWidth: 160)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(step) of 5")
    }

    private func stepBadge(step: Int) -> some View {
        progressBar(step: step)
            .padding(.top, Tokens.Spacing.lg)
    }

    private func stepChrome<Content: View>(step: Int, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            HStack {
                progressBar(step: step)
                Spacer()
                closeButton
            }
            .padding(.horizontal, Tokens.Spacing.xl)
            .padding(.top, Tokens.Spacing.sm)
            content()
        }
    }

    private var closeButton: some View {
        Button(action: { exitPlan() }) {
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                .padding(10)
                .background(Tokens.Colors.adaptiveCard)
                .clipShape(Circle())
        }
        .accessibilityLabel("Close")
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
