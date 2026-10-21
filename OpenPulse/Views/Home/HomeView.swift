import SwiftUI
import SwiftData

private enum HomeSheet: Identifiable {
    case heartRate, heartSound, breathing, insights, dailyPlan, care
    var id: Int { hashValue }
}

/// Home is deliberately simple: one obvious action (check your heart), where you
/// stand from the last check, and a short plain list of everything else.
struct HomeView: View {
    let user: User

    @Query(sort: \HeartRateReading.timestamp, order: .reverse) private var readings: [HeartRateReading]
    @Query(sort: \HeartSoundRecording.timestamp, order: .reverse) private var heartSoundRecordings: [HeartSoundRecording]
    @ObservedObject private var loc = Localizer.shared

    @State private var activeSheet: HomeSheet?

    private var lastReading: HeartRateReading? { readings.first }

    private var checkedToday: Bool {
        lastReading.map { Calendar.current.isDateInToday($0.timestamp) } ?? false
    }

    private var heartSoundSuggestedToday: Bool {
        Calendar.current.component(.weekday, from: .now) == user.heartSoundWeekday
            && !heartSoundRecordings.contains { Calendar.current.isDateInToday($0.timestamp) }
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
                .padding(.top, Tokens.Spacing.lg)
                .padding(.bottom, Tokens.Spacing.xxl)
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
        VStack(alignment: .leading, spacing: 2) {
            Text(Date.now, format: .dateTime.weekday(.wide).month(.wide).day())
                .font(Tokens.Fonts.secondaryText)
                .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
            Text(user.name.isEmpty ? loc.t("Hello") : "\(loc.t("Hi")), \(user.name)")
                .font(Tokens.Fonts.screenTitle)
                .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
        }
    }

    // MARK: - The one main action

    private var checkBlock: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.lg) {
            VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
                Text(loc.t(checkedToday ? "You checked today" : "Check your heart"))
                    .font(Tokens.Fonts.headline)
                    .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                Text(loc.t("30 seconds. Rest a fingertip on the back camera."))
                    .font(Tokens.Fonts.secondaryText)
                    .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
            }

            PrimaryButton(
                title: loc.t(checkedToday ? "Check again" : "Start check"),
                icon: "heart.fill"
            ) {
                activeSheet = .heartRate
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
            Text("\(loc.t("Last check")): ")
                .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
            + Text("\(reading.bpm) bpm")
                .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
            + Text(" · \(dayLabel(reading.timestamp)) · ")
                .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
            + Text(loc.t(category.shortName))
                .foregroundStyle(category.statusColor)
        )
        .font(Tokens.Fonts.secondaryText)
    }

    private func dayLabel(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return loc.t("today") }
        if cal.isDateInYesterday(date) { return loc.t("yesterday") }
        return date.formatted(.dateTime.month(.abbreviated).day())
    }

    // MARK: - Everything else, as a plain list

    private var moreList: some View {
        VStack(spacing: 0) {
            listRow(icon: "list.bullet", title: "Guided check", subtitle: "Check, breathe, and check again") {
                activeSheet = .dailyPlan
            }
            divider
            listRow(icon: "wind", title: "Breathing exercise", subtitle: nil) {
                activeSheet = .breathing
            }
            divider
            listRow(
                icon: "waveform",
                title: "Record heart sound",
                subtitle: heartSoundSuggestedToday ? "Suggested today" : nil
            ) {
                activeSheet = .heartSound
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
                    Text(loc.t(title))
                        .font(Tokens.Fonts.bodyText)
                        .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                    if let subtitle {
                        Text(loc.t(subtitle))
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
