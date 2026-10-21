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
        body: "Resting heart rate is how many times your heart beats per minute while you're sitting still and relaxed. Many guidelines use 60 to 100 bpm as normal for adults, and recent research suggests most healthy adults rest between about 50 and 90, which is the range this app uses. Very active people often sit lower, in the 40s. Tracking it over time, rather than any single reading, is what reveals real changes."
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
        title: "How the camera measures your heart rate",
        summary: "The same principle behind smartwatches and pulse oximeters.",
        body: "It's called photoplethysmography (PPG): measuring blood volume changes with light. Each heartbeat pushes a little more blood into your fingertip, and blood absorbs light, so the fingertip gets very slightly darker with every beat. The camera records the red brightness of your fingertip 30 times a second, a filter removes everything that isn't heartbeat-speed, and the rate is measured two independent ways that must agree before a reading is shown."
    ),
    Article(
        title: "Building a heart-healthy daily habit",
        summary: "Small, consistent checks beat occasional deep dives.",
        body: "Consistency matters more than intensity when it comes to tracking your health. A 30-second check at about the same time each day, sitting and rested, builds a baseline over a few weeks. That makes it far easier to notice a real change than any single measurement could, and it's what lets your personal heart model learn what's usual for you."
    )
]

struct EducationLibraryView: View {
    @ObservedObject private var loc = Localizer.shared

    var body: some View {
        List {
            ForEach(articles) { article in
                NavigationLink(destination: ArticleDetailView(article: article)) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(article.title)
                            .font(Tokens.Fonts.bodyText)
                            .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                        Text(article.summary)
                            .font(Tokens.Fonts.secondaryText)
                            .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Tokens.Colors.adaptiveBackground)
        .navigationTitle(loc.t("Heart health basics"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ArticleDetailView: View {
    let article: Article

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Spacing.lg) {
                Text(article.title)
                    .font(Tokens.Fonts.screenTitle)
                    .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                Text(article.body)
                    .font(Tokens.Fonts.bodyText)
                    .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                    .lineSpacing(5)
            }
            .padding(Tokens.Spacing.xl)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Tokens.Colors.adaptiveBackground)
        .navigationBarTitleDisplayMode(.inline)
    }
}
