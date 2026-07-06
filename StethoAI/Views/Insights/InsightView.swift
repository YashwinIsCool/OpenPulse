import SwiftUI
import SwiftData

struct InsightView: View {
    let user: User

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Insight.timestamp, order: .reverse) private var insights: [Insight]
    @Query(sort: \HeartRateReading.timestamp, order: .reverse) private var readings: [HeartRateReading]

    @State private var isSharePresented = false

    private var latestInsight: Insight? { insights.first }

    var body: some View {
        VStack(spacing: Tokens.Spacing.xl) {
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                        .padding(Tokens.Spacing.sm)
                        .background(Tokens.Colors.adaptiveCard)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, Tokens.Spacing.lg)
            .padding(.top, Tokens.Spacing.sm)

            Spacer()

            if let insight = latestInsight {
                VStack(spacing: Tokens.Spacing.lg) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Tokens.Colors.primaryRed)

                    Text(insight.title)
                        .font(Tokens.Fonts.pageTitle)
                        .tracking(Tokens.Tracking.pageTitle)
                        .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                        .multilineTextAlignment(.center)

                    Text(insight.body)
                        .font(Tokens.Fonts.body)
                        .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Tokens.Spacing.xxl)

                    Text(insight.timestamp.formatted(date: .abbreviated, time: .omitted))
                        .font(Tokens.Fonts.caption)
                        .foregroundStyle(Tokens.Colors.adaptiveTextQuaternary)
                }
            } else {
                ProgressView().tint(Tokens.Colors.primaryRed)
            }

            Spacer()
            Spacer()

            HStack(spacing: Tokens.Spacing.md) {
                SecondaryButton(title: "Share", icon: "square.and.arrow.up", action: { isSharePresented = true })
                PrimaryButton(title: "Save", icon: "checkmark", action: { dismiss() })
            }
            .padding(.horizontal, Tokens.Spacing.xl)
            .padding(.bottom, Tokens.Spacing.xl)
        }
        .background(Tokens.Colors.adaptiveBackground)
        .navigationBarHidden(true)
        .onAppear(perform: ensureFreshInsight)
        .sheet(isPresented: $isSharePresented) {
            if let insight = latestInsight {
                ShareSheet(items: ["\(insight.title): \(insight.body)"])
            }
        }
    }

    private func ensureFreshInsight() {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: .now) ?? .now
        if latestInsight == nil || (latestInsight?.timestamp ?? .distantPast) < weekAgo {
            let insight = InsightGenerator.generateWeeklyInsight(user: user, readings: readings)
            modelContext.insert(insight)
        } else if let latestInsight, !latestInsight.isRead {
            latestInsight.isRead = true
        }
    }
}
