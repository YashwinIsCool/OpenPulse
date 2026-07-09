import SwiftUI
import SwiftData

private enum HomeSheet: Identifiable {
    case heartRate, heartSound, breathing, insights, stressLog, dailyPlan
    var id: Int { hashValue }
}

struct HomeView: View {
    let user: User

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HeartRateReading.timestamp, order: .reverse) private var readings: [HeartRateReading]
    @Query(sort: \BreathingSession.timestamp, order: .reverse) private var breathingSessions: [BreathingSession]
    @Query(sort: \HeartSoundRecording.timestamp, order: .reverse) private var heartSoundRecordings: [HeartSoundRecording]
    @Query(sort: \DailyLog.date, order: .reverse) private var dailyLogs: [DailyLog]

    @State private var activeSheet: HomeSheet?

    private var todayReading: HeartRateReading? {
        readings.first { Calendar.current.isDateInToday($0.timestamp) }
    }

    private var yesterdayReading: HeartRateReading? {
        readings.first { Calendar.current.isDateInYesterday($0.timestamp) }
    }

    private var didBreatheToday: Bool {
        breathingSessions.contains { Calendar.current.isDateInToday($0.timestamp) }
    }

    private var todayLog: DailyLog? {
        dailyLogs.first { Calendar.current.isDateInToday($0.date) }
    }

    private var didCheckInToday: Bool {
        todayLog?.hasCheckIn ?? false
    }

    private var todayCheckIn: CheckInData {
        guard let log = todayLog else { return CheckInData() }
        return CheckInData(
            sleepHours: log.sleepHours,
            caffeineCups: log.caffeineCups,
            exerciseMinutes: log.exerciseMinutes,
            stressLevel: log.stressLevel,
            mood: log.mood
        )
    }

    private var didHeartSoundToday: Bool {
        heartSoundRecordings.contains { Calendar.current.isDateInToday($0.timestamp) }
    }

    private var isHeartSoundDay: Bool {
        Calendar.current.component(.weekday, from: .now) == user.heartSoundWeekday
    }

    private var allTasksDone: Bool {
        todayReading != nil && didCheckInToday && didBreatheToday && (!isHeartSoundDay || didHeartSoundToday)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Tokens.Spacing.lg) {
                    header
                    heroSection
                    quickActionsGrid
                    todaysPlanSection
                    startPlanButton
                }
                .padding(Tokens.Spacing.lg)
            }
            .background(Tokens.Colors.adaptiveBackground)
            .navigationBarHidden(true)
            .fullScreenCover(item: $activeSheet) { sheet in
                switch sheet {
                case .heartRate:
                    HeartRateFlowView(user: user)
                case .heartSound:
                    HeartSoundFlowView(user: user)
                case .breathing:
                    NavigationStack { BreathingLibraryView(user: user) }
                case .insights:
                    InsightView(user: user)
                case .stressLog:
                    DailyCheckInSheet(initial: todayCheckIn, onSave: saveCheckIn)
                case .dailyPlan:
                    DailyPlanFlowView(user: user)
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.system(size: 28, weight: .bold))
                    .tracking(Tokens.Tracking.pageTitle)
                    .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                Text(user.name.isEmpty ? "Welcome" : user.name)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
            }
            Spacer()
            StreakBadge(dayCount: user.streakCount)
                .padding(.top, Tokens.Spacing.xs)
        }
        .padding(.top, Tokens.Spacing.sm)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case ..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private var heroSection: some View {
        HeroCard {
            VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
                Text("TODAY'S HEART CHECK")
                    .font(Tokens.Fonts.microLabel)
                    .tracking(Tokens.Tracking.microLabel)
                    .foregroundStyle(.white.opacity(0.92))

                if let reading = todayReading {
                    HStack(alignment: .lastTextBaseline, spacing: Tokens.Spacing.xs) {
                        Text("\(reading.bpm)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(.white)
                        Text("bpm")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    if let yesterday = yesterdayReading {
                        let diff = reading.bpm - yesterday.bpm
                        HStack(spacing: Tokens.Spacing.xs) {
                            Image(systemName: diff <= 0 ? "arrow.down" : "arrow.up")
                            Text("\(abs(diff)) from yesterday")
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                    }
                } else {
                    Text("Haven't checked yet")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)

                    Button(action: { activeSheet = .heartRate }) {
                        HStack(spacing: Tokens.Spacing.sm) {
                            Text("Start 30-second check")
                                .font(Tokens.Fonts.cardTitle)
                            Image(systemName: "arrow.right")
                        }
                        .foregroundStyle(Tokens.Colors.primaryRed)
                        .padding(.horizontal, Tokens.Spacing.lg)
                        .padding(.vertical, Tokens.Spacing.md)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.button, style: .continuous))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var quickActionsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Tokens.Spacing.md) {
            quickActionCard(icon: "heart.fill", title: "Heart Rate Check", subtitle: "30-second reading") {
                activeSheet = .heartRate
            }
            quickActionCard(icon: "waveform", title: "Heart Sound", subtitle: "Weekly deep check") {
                activeSheet = .heartSound
            }
            quickActionCard(icon: "wind", title: "Breathing", subtitle: "Calm your heart") {
                activeSheet = .breathing
            }
            quickActionCard(icon: "lightbulb.fill", title: "Insights", subtitle: "Your weekly report") {
                activeSheet = .insights
            }
        }
    }

    private func quickActionCard(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Card {
                VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Tokens.Colors.primaryRed)
                        .frame(width: 32, height: 32)
                        .background(Tokens.Colors.adaptiveSoftRedSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    Text(title)
                        .font(Tokens.Fonts.cardTitle)
                        .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                    Text(subtitle)
                        .font(Tokens.Fonts.caption)
                        .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }

    private var startPlanButton: some View {
        VStack(spacing: Tokens.Spacing.xs) {
            PrimaryButton(
                title: allTasksDone ? "Run today's plan again" : "Start today's plan",
                icon: allTasksDone ? "arrow.clockwise" : "play.fill"
            ) {
                activeSheet = .dailyPlan
            }
            Text("One guided flow — reading, check-in, breathing, and your results.")
                .font(Tokens.Fonts.caption)
                .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Tokens.Spacing.sm)
    }

    private var todaysPlanSection: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Today's plan")
                    .font(Tokens.Fonts.sectionHeading)
                    .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                Text(allTasksDone ? "All done — streak secured for today!" : "Finish everything to keep your streak going.")
                    .font(Tokens.Fonts.caption)
                    .foregroundStyle(allTasksDone ? Tokens.Colors.successGreen : Tokens.Colors.adaptiveTextTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            planRow(title: "Morning heart rate check", subtitle: "30 seconds", done: todayReading != nil) {
                activeSheet = .heartRate
            }
            planRow(title: "Daily check-in", subtitle: "Sleep, caffeine, stress & mood", done: didCheckInToday) {
                activeSheet = .stressLog
            }
            planRow(title: "Evening breathing exercise", subtitle: "2-5 minutes", done: didBreatheToday) {
                activeSheet = .breathing
            }
            if isHeartSoundDay {
                planRow(title: "Weekly heart sound", subtitle: "30 seconds", done: didHeartSoundToday) {
                    activeSheet = .heartSound
                }
            }
        }
    }

    private func planRow(title: String, subtitle: String, done: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Card {
                HStack {
                    VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
                        Text(title)
                            .font(Tokens.Fonts.cardTitle)
                            .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                        Text(subtitle)
                            .font(Tokens.Fonts.caption)
                            .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                    }
                    Spacer()
                    Image(systemName: done ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(done ? Tokens.Colors.successGreen : Tokens.Colors.adaptiveTextQuaternary)
                        .font(.system(size: 20))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func saveCheckIn(_ data: CheckInData) {
        let log = dailyLogs.first(where: { Calendar.current.isDateInToday($0.date) }) ?? {
            let new = DailyLog()
            modelContext.insert(new)
            return new
        }()
        log.sleepHours = data.sleepHours
        log.caffeineCups = data.caffeineCups
        log.exerciseMinutes = data.exerciseMinutes
        log.stressLevel = data.stressLevel
        log.mood = data.mood
        StreakManager.updateStreakIfDayComplete(context: modelContext, user: user)
        activeSheet = nil
    }
}
