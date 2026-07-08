import SwiftUI

struct HeartSoundResultView: View {
    let result: HeartSoundResult
    let audioURL: URL?
    let onSave: () -> Void
    let onNewScan: () -> Void
    let onDismiss: () -> Void

    @State private var isSharePresented = false

    var body: some View {
        ScrollView {
            VStack(spacing: Tokens.Spacing.lg) {
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                            .padding(Tokens.Spacing.sm)
                            .background(Tokens.Colors.adaptiveCard)
                            .clipShape(Circle())
                    }
                }

                VStack(spacing: Tokens.Spacing.md) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 32))
                        .foregroundStyle(Tokens.Colors.primaryRed)

                    Text("Heart sound recorded")
                        .font(Tokens.Fonts.pageTitle)
                        .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)

                    Text("Listen back, keep it in your history, or share it with your doctor.")
                        .font(Tokens.Fonts.body)
                        .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(Tokens.Spacing.lg)
                .frame(maxWidth: .infinity)
                .background(Tokens.Colors.lightRedTint)
                .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.card, style: .continuous))

                HeartSoundPlayerView(url: audioURL)

                Card {
                    VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
                        Label("AI analysis coming soon", systemImage: "sparkles")
                            .font(Tokens.Fonts.cardTitle)
                            .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                        Text("StethoAI does not analyze or diagnose your heart sound. It helps you record, keep, and share it. Automatic analysis is in development and will arrive in a future update.")
                            .font(Tokens.Fonts.body)
                            .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                VStack(spacing: Tokens.Spacing.sm) {
                    PrimaryButton(title: "Save Recording", icon: "tray.and.arrow.down.fill", action: onSave)
                    SecondaryButton(title: "Share with Doctor", icon: "square.and.arrow.up", action: { isSharePresented = true })
                    SecondaryButton(title: "New Scan", icon: "arrow.clockwise", action: onNewScan)
                }

                DisclaimerFooter(text: "Educational use only · Not medical advice. If you have any concerns about your heart, talk to a healthcare provider.")
            }
            .padding(Tokens.Spacing.lg)
        }
        .sheet(isPresented: $isSharePresented) {
            ShareSheet(items: shareItems)
        }
    }

    private var shareItems: [Any] {
        var items: [Any] = ["My heart sound recording from StethoAI. Educational use only, not medical advice."]
        if let audioURL, FileManager.default.fileExists(atPath: audioURL.path) {
            items.append(audioURL)
        }
        return items
    }
}
