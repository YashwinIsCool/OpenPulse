import SwiftUI

struct HeartSoundResultView: View {
    let audioURL: URL?
    let onSave: () -> Void
    let onNewScan: () -> Void
    let onDismiss: () -> Void

    @State private var isSharePresented = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Spacing.xxl) {
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                            .padding(10)
                            .background(Tokens.Colors.adaptiveCard)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Close")
                }

                VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
                    Text("Heart sound recorded")
                        .font(Tokens.Fonts.screenTitle)
                        .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                    Text("Listen back, keep it in your history, or share it with a doctor.")
                        .font(Tokens.Fonts.bodyText)
                        .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                }

                HeartSoundPlayerView(url: audioURL)

                Text("This app records your heart sound but doesn't analyze or diagnose it. A doctor can listen to it for you.")
                    .font(Tokens.Fonts.secondaryText)
                    .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: Tokens.Spacing.sm) {
                    PrimaryButton(title: "Save recording", action: onSave)
                    SecondaryButton(title: "Share with a doctor", icon: "square.and.arrow.up") { isSharePresented = true }
                    SecondaryButton(title: "Record again", action: onNewScan)
                }

                DisclaimerFooter(text: "Educational use only · Not medical advice. If you have any concerns about your heart, talk to a healthcare provider.")
            }
            .padding(.horizontal, Tokens.Spacing.xl)
            .padding(.vertical, Tokens.Spacing.sm)
        }
        .sheet(isPresented: $isSharePresented) {
            ShareSheet(items: shareItems)
        }
    }

    private var shareItems: [Any] {
        var items: [Any] = ["My heart sound recording from \(AppInfo.name). Educational use only, not medical advice."]
        if let audioURL, FileManager.default.fileExists(atPath: audioURL.path) {
            items.append(audioURL)
        }
        return items
    }
}
