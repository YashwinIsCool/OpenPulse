import SwiftUI
import SwiftData

struct InsightView: View {
    let user: User

    @Environment(\.dismiss) private var dismiss
    @Query(sort: \HeartRateReading.timestamp, order: .reverse) private var readings: [HeartRateReading]
    @Query(sort: \DailyLog.date, order: .reverse) private var dailyLogs: [DailyLog]

    @State private var isSharePresented = false

    private var result: InsightResult {
        HeartInsightEngine.analyze(readings: readings, logs: dailyLogs)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Tokens.Spacing.lg) {
                    let result = result

                    if result.hasEnoughData {
                        ForEach(result.insights) { insight in
                            insightCard(insight)
                        }

                        Text("Based on \(result.daysAnalyzed) days of your check-ins · Wellness insights, not medical advice.")
                            .font(Tokens.Fonts.caption)
                            .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, Tokens.Spacing.sm)
                    } else {
                        coldStart(result)
                    }
                }
                .padding(Tokens.Spacing.lg)
            }
            .background(Tokens.Colors.adaptiveBackground)
            .navigationTitle("Your heart insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarLeading) {
                    if result.hasEnoughData {
                        Button {
                            isSharePresented = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .sheet(isPresented: $isSharePresented) {
                ShareSheet(items: [shareText])
            }
        }
    }

    private func insightCard(_ insight: PersonalInsight) -> some View {
        Card {
            HStack(alignment: .top, spacing: Tokens.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Tokens.Colors.adaptiveSoftRedSurface)
                        .frame(width: 44, height: 44)
                    Image(systemName: insight.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(Tokens.Colors.primaryRed)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(insight.title)
                        .font(Tokens.Fonts.cardTitle)
                        .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                    Text(insight.body)
                        .font(Tokens.Fonts.body)
                        .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func coldStart(_ result: InsightResult) -> some View {
        VStack(spacing: Tokens.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(Tokens.Colors.adaptiveSoftRedSurface)
                    .frame(width: 90, height: 90)
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 40))
                    .foregroundStyle(Tokens.Colors.primaryRed)
            }
            .padding(.top, Tokens.Spacing.xxl)

            Text("Learning your heart")
                .font(Tokens.Fonts.pageTitle)
                .tracking(Tokens.Tracking.pageTitle)
                .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)

            Text(result.daysRemaining == 0
                 ? "Keep logging on different kinds of days and your first patterns will appear here."
                 : "Check in and take a heart rate reading on \(result.daysRemaining) more day\(result.daysRemaining == 1 ? "" : "s") to unlock your personal patterns.")
                .font(Tokens.Fonts.body)
                .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Tokens.Spacing.lg)

            // Progress toward the unlock.
            VStack(spacing: Tokens.Spacing.sm) {
                ProgressView(value: Double(result.daysAnalyzed), total: Double(result.daysNeeded))
                    .tint(Tokens.Colors.primaryRed)
                Text("\(result.daysAnalyzed) of \(result.daysNeeded) days")
                    .font(Tokens.Fonts.caption)
                    .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
            }
            .padding(Tokens.Spacing.lg)
            .background(Tokens.Colors.adaptiveCard)
            .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Tokens.Radius.card, style: .continuous)
                    .stroke(Tokens.Colors.adaptiveBorder, lineWidth: 1)
            )

            Text("The more you check in — sleep, caffeine, stress, mood — the sharper your insights get.")
                .font(Tokens.Fonts.caption)
                .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Tokens.Spacing.lg)
        }
        .frame(maxWidth: .infinity)
    }

    private var shareText: String {
        let lines = result.insights.map { "• \($0.title): \($0.body)" }.joined(separator: "\n")
        return "My StethoAI heart insights:\n\(lines)\n\nWellness insights, not medical advice."
    }
}
