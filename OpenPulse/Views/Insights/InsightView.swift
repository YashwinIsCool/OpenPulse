import SwiftUI
import SwiftData

/// Insights: the personal heart model (what's usual for you and what moves your
/// heart rate), then plain-language patterns from your check-ins.
struct InsightView: View {
    let user: User

    @Environment(\.dismiss) private var dismiss
    @Query(sort: \HeartRateReading.timestamp, order: .reverse) private var readings: [HeartRateReading]
    @Query(sort: \DailyLog.date, order: .reverse) private var dailyLogs: [DailyLog]
    @ObservedObject private var loc = Localizer.shared

    @State private var isSharePresented = false

    private var result: InsightResult {
        HeartInsightEngine.analyze(readings: readings, logs: dailyLogs)
    }

    private var model: PersonalHeartModel {
        PersonalHeartModel(user: user, readings: readings, logs: dailyLogs)
    }

    private var todayLog: DailyLog? {
        dailyLogs.first { Calendar.current.isDateInToday($0.date) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Tokens.Spacing.xxl) {
                    modelSection(model)
                    patternsSection(result)
                    Text(loc.t("Wellness patterns from your own data, not medical advice."))
                        .font(Tokens.Fonts.secondaryText)
                        .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, Tokens.Spacing.xl)
                .padding(.vertical, Tokens.Spacing.lg)
            }
            .background(Tokens.Colors.adaptiveBackground)
            .navigationTitle(loc.t("Your insights"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(loc.t("Done")) { dismiss() }
                }
                ToolbarItem(placement: .topBarLeading) {
                    if result.hasEnoughData || !model.effects.isEmpty {
                        Button { isSharePresented = true } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .accessibilityLabel("Share")
                    }
                }
            }
            .sheet(isPresented: $isSharePresented) {
                ShareSheet(items: [shareText])
            }
        }
    }

    // MARK: - Personal heart model

    private func modelSection(_ model: PersonalHeartModel) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
            sectionHeader("Your heart model", subtitle: "Learns what's usual for you, on this phone")

            ListCard {
                HStack {
                    Text(loc.t("Usual for you right now"))
                        .font(Tokens.Fonts.bodyText)
                        .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                    Spacer()
                    Text("~\(Int(model.expectedBPM(log: todayLog).rounded())) bpm")
                        .font(Tokens.Fonts.bodyText.weight(.semibold))
                        .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                }
                .padding(.vertical, 14)

                ListDivider()

                HStack {
                    Text(loc.t("Learned from"))
                        .font(Tokens.Fonts.bodyText)
                        .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                    Spacer()
                    Text("\(model.readingsUsed) \(loc.t(model.readingsUsed == 1 ? "reading" : "readings"))")
                        .font(Tokens.Fonts.bodyText)
                        .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                }
                .padding(.vertical, 14)

                if let error = model.typicalError {
                    ListDivider()
                    HStack {
                        Text(loc.t("Usually accurate to within"))
                            .font(Tokens.Fonts.bodyText)
                            .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                        Spacer()
                        Text("±\(max(1, Int(error.rounded()))) bpm")
                            .font(Tokens.Fonts.bodyText)
                            .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                    }
                    .padding(.vertical, 14)
                }
            }

            if !model.isPersonal {
                Text(loc.t("For now this is a starting estimate from your profile. It becomes personal after 7 readings."))
                    .font(Tokens.Fonts.secondaryText)
                    .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            effects(model)
        }
    }

    @ViewBuilder
    private func effects(_ model: PersonalHeartModel) -> some View {
        let effects = model.effects
        VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
            Text(loc.t("What moves your heart rate"))
                .font(.headline)
                .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                .padding(.top, Tokens.Spacing.sm)

            if effects.isEmpty {
                let remaining = max(0, PersonalHeartModel.readingsForEffects - model.readingsUsed)
                Text(remaining > 0
                     ? loc.t("After %d more readings with check-ins, you'll see what raises and lowers your heart rate.")
                        .replacingOccurrences(of: "%d", with: "\(remaining)")
                     : loc.t("Nothing stands out yet. Keep checking in on different kinds of days."))
                    .font(Tokens.Fonts.secondaryText)
                    .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ListCard {
                    ForEach(Array(effects.enumerated()), id: \.element.id) { index, effect in
                        if index > 0 { ListDivider() }
                        HStack(spacing: Tokens.Spacing.md) {
                            Image(systemName: effect.icon)
                                .font(.system(size: 17))
                                .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                                .frame(width: 24)
                            Text(loc.t(effect.label))
                                .font(Tokens.Fonts.bodyText)
                                .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                            Spacer()
                            Text(String(format: "%+.0f bpm", effect.bpm.rounded()))
                                .font(Tokens.Fonts.bodyText.weight(.semibold))
                                .monospacedDigit()
                                .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                        }
                        .padding(.vertical, 14)
                    }
                }
                Text(loc.t("Estimated by a small machine-learning model trained only on your readings and check-ins. Nothing leaves your phone."))
                    .font(Tokens.Fonts.secondaryText)
                    .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Patterns

    @ViewBuilder
    private func patternsSection(_ result: InsightResult) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
            sectionHeader("Patterns", subtitle: nil)

            if result.hasEnoughData {
                ListCard {
                    ForEach(Array(result.insights.enumerated()), id: \.element.id) { index, insight in
                        if index > 0 { ListDivider() }
                        HStack(alignment: .top, spacing: Tokens.Spacing.md) {
                            Image(systemName: insight.icon)
                                .font(.system(size: 17))
                                .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                                .frame(width: 24)
                                .padding(.top, 2)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(insight.title)
                                    .font(Tokens.Fonts.bodyText.weight(.semibold))
                                    .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                                Text(insight.body)
                                    .font(Tokens.Fonts.secondaryText)
                                    .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.vertical, 14)
                    }
                }
                Text("\(loc.t("Days analyzed")): \(result.daysAnalyzed)")
                    .font(Tokens.Fonts.secondaryText)
                    .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
            } else {
                VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
                    ProgressView(value: Double(result.daysAnalyzed), total: Double(result.daysNeeded))
                        .tint(Tokens.Colors.ink)
                    Text(loc.t("Check your heart and do a check-in on %d more days to see your patterns.")
                        .replacingOccurrences(of: "%d", with: "\(result.daysRemaining)"))
                        .font(Tokens.Fonts.secondaryText)
                        .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func sectionHeader(_ title: String, subtitle: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(loc.t(title))
                .font(Tokens.Fonts.headline)
                .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
            if let subtitle {
                Text(loc.t(subtitle))
                    .font(Tokens.Fonts.secondaryText)
                    .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
            }
        }
    }

    private var shareText: String {
        var lines: [String] = []
        let effects = model.effects
        if !effects.isEmpty {
            lines.append("What moves my heart rate:")
            lines += effects.map { "• \($0.label): \(String(format: "%+.0f", $0.bpm.rounded())) bpm" }
        }
        if result.hasEnoughData {
            lines += result.insights.map { "• \($0.title): \($0.body)" }
        }
        return "My OpenPulse heart insights\n\(lines.joined(separator: "\n"))\n\nWellness patterns, not medical advice."
    }
}
