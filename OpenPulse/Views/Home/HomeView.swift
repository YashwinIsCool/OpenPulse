import SwiftUI
import SwiftData

private enum HomeSheet: Identifiable {
    case heartRate, breathing, insights, dailyPlan, care
    var id: Int { hashValue }
}

/// Home is deliberately simple: one obvious action (the daily routine, then a plain
/// heart rate check once it's done), where you stand from the last check, and a
/// short plain list of everything else.
struct HomeView: View {
    let user: User

    @Query(sort: \HeartRateReading.timestamp, order: .reverse) private var readings: [HeartRateReading]
    @Query private var dailyLogs: [DailyLog]

    @State private var activeSheet: HomeSheet?
    @State private var showStreakInfo = false

    private var lastReading: HeartRateReading? { readings.first }

    private var routineDoneToday: Bool {
        dailyLogs.contains { Calendar.current.isDateInToday($0.date) && $0.routineCompleted }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Tokens.Spacing.xxl) {
                    header
                    checkBlock
                    moreList
                }
                .padding(.horizontal, Tokens.Spacing.xl)
                // Lines the title up with the Help tab's large title.
                .padding(.top, 40)
                .padding(.bottom, Tokens.Spacing.xxl)
            }
            .background(Tokens.Colors.adaptiveBackground)
            .navigationBarHidden(true)
            .fullScreenCover(item: $activeSheet) { sheet in
                switch sheet {
                case .heartRate:
                    HeartRateFlowView(user: user)
                case .breathing:
                    NavigationStack { BreathingLibraryView(user: user) }
                case .insights:
                    InsightView(user: user)
                case .dailyPlan:
                    DailyPlanFlowView(user: user)
                case .care:
                    FindCareView()
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Date.now, format: .dateTime.weekday(.wide).month(.wide).day())
                    .font(Tokens.Fonts.secondaryText)
                    .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                Text(user.name.isEmpty ? "Hello" : "Hi, \(user.name)")
                    .font(Tokens.Fonts.screenTitle)
                    .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
            }
            Spacer()
            streakBadge
        }
    }

    /// Days in a row the routine was finished. Grey until the first one. Tap for
    /// what it means and how close the app is to learning your patterns.
    private var streakBadge: some View {
        let count = user.streakCount
        return Button {
            showStreakInfo = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(count > 0 ? Tokens.Colors.streak : Tokens.Colors.adaptiveTextQuaternary)
                Text("\(count)")
                    .monospacedDigit()
                    .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
            }
            .font(Tokens.Fonts.bodyText.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Tokens.Colors.adaptiveCard)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Tokens.Colors.adaptiveBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .padding(.top, Tokens.Spacing.xs)
        .accessibilityLabel(count == 1 ? "1 day streak" : "\(count) day streak")
        .accessibilityHint("Shows what your streak means")
        .popover(isPresented: $showStreakInfo, arrowEdge: .top) {
            StreakInfoView(streak: count, lastActive: user.lastActiveDate, readingCount: readings.count)
                .presentationCompactAdaptation(.popover)
        }
    }

    // MARK: - The one main action

    private var checkBlock: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.lg) {
            VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
                Text(routineDoneToday ? "Routine done for today" : "Your daily routine")
                    .font(Tokens.Fonts.headline)
                    .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                Text(routineDoneToday
                     ? "Nice work. You can still check your heart rate any time."
                     : "Check your heart rate, log how you're doing, and breathe if you need to.")
                    .font(Tokens.Fonts.secondaryText)
                    .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
            }

            if routineDoneToday {
                PrimaryButton(title: "Check heart rate", icon: "heart.fill") {
                    activeSheet = .heartRate
                }
            } else {
                PrimaryButton(title: "Start daily routine", icon: "heart.fill") {
                    activeSheet = .dailyPlan
                }
                Button("Just check heart rate") {
                    activeSheet = .heartRate
                }
                .font(Tokens.Fonts.secondaryText.weight(.semibold))
                .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                .frame(maxWidth: .infinity)
            }

            if let lastReading {
                lastCheckLine(lastReading)
            }
        }
        .padding(Tokens.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Tokens.Colors.adaptiveCard)
        .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.hero, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Tokens.Radius.hero, style: .continuous)
                .stroke(Tokens.Colors.adaptiveBorder, lineWidth: 1)
        )
    }

    private func lastCheckLine(_ reading: HeartRateReading) -> some View {
        let category = HeartRateCategory.categorize(bpm: reading.bpm, activity: user.activityLevel)
        return (
            Text("Last check: ")
                .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
            + Text("\(reading.bpm) bpm")
                .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
            + Text(" · \(dayLabel(reading.timestamp)) · ")
                .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
            + Text(category.shortName)
                .foregroundStyle(category.statusColor)
        )
        .font(Tokens.Fonts.secondaryText)
    }

    private func dayLabel(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "today" }
        if cal.isDateInYesterday(date) { return "yesterday" }
        return date.formatted(.dateTime.month(.abbreviated).day())
    }

    // MARK: - Everything else, as a plain list

    private var moreList: some View {
        VStack(spacing: 0) {
            listRow(icon: "wind", title: "Breathing exercise", subtitle: nil) {
                activeSheet = .breathing
            }
            divider
            listRow(icon: "lightbulb", title: "Your insights", subtitle: nil) {
                activeSheet = .insights
            }
            divider
            listRow(icon: "cross.case", title: "Where to get care", subtitle: nil) {
                activeSheet = .care
            }
        }
        .background(Tokens.Colors.adaptiveCard)
        .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Tokens.Radius.card, style: .continuous)
                .stroke(Tokens.Colors.adaptiveBorder, lineWidth: 1)
        )
    }

    private var divider: some View {
        Rectangle()
            .fill(Tokens.Colors.adaptiveBorder)
            .frame(height: 1)
            .padding(.leading, 52)
    }

    private func listRow(icon: String, title: String, subtitle: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Tokens.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 17))
                    .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Tokens.Fonts.bodyText)
                        .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .font(Tokens.Fonts.secondaryText)
                            .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Tokens.Colors.adaptiveTextQuaternary)
            }
            .padding(.horizontal, Tokens.Spacing.lg)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Streak popup

/// The small popup behind the streak badge: how long the streak is, what counts,
/// and how regular checks let the app learn what's usual for you.
struct StreakInfoView: View {
    let streak: Int
    let lastActive: Date?
    let readingCount: Int

    private let forUsual = PersonalHeartModel.readingsForPersonal
    private let forEffects = PersonalHeartModel.readingsForEffects

    private var title: String {
        switch streak {
        case 0: return "No streak yet"
        case 1: return "1-day streak"
        default: return "\(streak)-day streak"
        }
    }

    /// One short line under the title.
    private var subtitle: String {
        guard streak > 0, let lastActive,
              let start = Calendar.current.date(byAdding: .day, value: -(streak - 1), to: lastActive) else {
            return "Finish your daily routine to start one."
        }
        return "Daily routines in a row, since \(start.formatted(.dateTime.month(.abbreviated).day()))."
    }

    private var learningText: String {
        if readingCount < forUsual {
            let left = forUsual - readingCount
            return "\(left) more \(left == 1 ? "check" : "checks") until it learns your usual heart rate."
        }
        if readingCount < forEffects {
            let left = forEffects - readingCount
            return "\(left) more \(left == 1 ? "check" : "checks") until it shows what changes your heart rate."
        }
        return "It now shows what changes your heart rate, like sleep and stress."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(streak > 0 ? Tokens.Colors.streak : Tokens.Colors.adaptiveTextQuaternary)
                Text(title)
                    .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
            }
            .font(Tokens.Fonts.headline)
            Text(subtitle)
                .font(Tokens.Fonts.secondaryText)
                .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
            Divider().padding(.vertical, Tokens.Spacing.xs)
            Text("OpenPulse gets smarter each time you check. \(learningText)")
                .font(Tokens.Fonts.secondaryText)
                .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(Tokens.Spacing.lg)
        .frame(width: 300)
    }
}
