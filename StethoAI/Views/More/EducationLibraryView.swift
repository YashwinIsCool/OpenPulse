import SwiftUI

private struct Article: Identifiable {
    let id = UUID()
    let title: String
    let summary: String
    let body: String
}

private let articles: [Article] = [
    Article(
        title: "What is a resting heart rate?",
        summary: "Why it matters and what's typical for adults.",
        body: "Resting heart rate is how many times your heart beats per minute while you're at rest. For most adults, a normal resting heart rate falls between 60 and 100 bpm, though well-conditioned athletes often sit lower. Tracking it over time — rather than any single reading — is what reveals meaningful trends in your fitness and recovery."
    ),
    Article(
        title: "Understanding heart rate variability",
        summary: "What HRV measures and why more isn't always simple.",
        body: "Heart rate variability (HRV) measures the tiny fluctuations in time between heartbeats. Higher HRV is generally associated with better recovery and lower stress, while lower HRV can reflect fatigue, illness, or stress. HRV is highly individual, so it's most useful when you compare it to your own baseline over weeks, not to anyone else's number."
    ),
    Article(
        title: "Heart murmurs, explained simply",
        summary: "Most murmurs are harmless — here's the difference.",
        body: "A heart murmur is an extra whooshing sound during your heartbeat, caused by turbulent blood flow. Many murmurs are 'innocent' — harmless variations that need no treatment. Others can point to a structural issue worth evaluating. Only a clinician with a stethoscope and, if needed, an echocardiogram can tell the difference — an app can flag something worth checking, not diagnose it."
    ),
    Article(
        title: "Why breathing exercises affect your heart",
        summary: "The heart-lung-nervous system connection.",
        body: "Slow, controlled breathing activates your parasympathetic nervous system — your body's 'rest and digest' mode — which can lower heart rate and increase HRV within minutes. This is why a few minutes of paced breathing before a stressful moment, or before bed, can measurably calm your body, not just your mind."
    ),
    Article(
        title: "How PPG heart rate sensing works",
        summary: "The same principle behind your phone camera and a smartwatch.",
        body: "Photoplethysmography (PPG) shines light into your skin and measures how much is absorbed, which changes slightly with each heartbeat as blood volume shifts in your capillaries. Your phone's camera and flash can pick up this signal from a fingertip, the same underlying principle used in smartwatches and clinical pulse oximeters."
    ),
    Article(
        title: "Building a heart-healthy daily habit",
        summary: "Small, consistent checks beat occasional deep dives.",
        body: "Consistency matters more than intensity when it comes to tracking your health. A 30-second daily check builds a real baseline over weeks, making it far easier to notice a meaningful change than a single one-off measurement ever could. Streaks aren't just gamification — they're what makes the data useful."
    )
]

struct EducationLibraryView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Tokens.Spacing.md) {
                ForEach(articles) { article in
                    NavigationLink(destination: ArticleDetailView(article: article)) {
                        Card {
                            VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
                                Text(article.title)
                                    .font(Tokens.Fonts.cardTitle)
                                    .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                                Text(article.summary)
                                    .font(Tokens.Fonts.caption)
                                    .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Tokens.Spacing.lg)
        }
        .background(Tokens.Colors.adaptiveBackground)
        .navigationTitle("Heart health basics")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ArticleDetailView: View {
    let article: Article

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
                Text(article.title)
                    .font(Tokens.Fonts.pageTitle)
                    .tracking(Tokens.Tracking.pageTitle)
                    .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                Text(article.body)
                    .font(Tokens.Fonts.body)
                    .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                    .lineSpacing(4)
            }
            .padding(Tokens.Spacing.lg)
        }
        .background(Tokens.Colors.adaptiveBackground)
        .navigationBarTitleDisplayMode(.inline)
    }
}
