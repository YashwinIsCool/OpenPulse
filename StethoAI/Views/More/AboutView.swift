import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Tokens.Spacing.xl) {
                VStack(spacing: Tokens.Spacing.sm) {
                    Image(systemName: "waveform.path.ecg.rectangle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Tokens.Colors.primaryRed)
                    Text("StethoAI")
                        .font(Tokens.Fonts.display)
                        .tracking(Tokens.Tracking.display)
                        .foregroundStyle(Tokens.Colors.primaryRed)
                    Text("Version 1.0")
                        .font(Tokens.Fonts.caption)
                        .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                }
                .padding(.top, Tokens.Spacing.xl)

                Card {
                    Text("StethoAI is an AI-powered heart wellness companion. It helps you check your heart rate daily, track heart sounds over time, and build habits that support long-term heart health.")
                        .font(Tokens.Fonts.body)
                        .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                }

                Card {
                    VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
                        Text("Not a medical device")
                            .font(Tokens.Fonts.cardTitle)
                            .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                        Text("StethoAI is designed for wellness and education. It is not FDA-approved, does not diagnose medical conditions, and should never replace professional medical evaluation.")
                            .font(Tokens.Fonts.body)
                            .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(Tokens.Spacing.lg)
        }
        .background(Tokens.Colors.adaptiveBackground)
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
