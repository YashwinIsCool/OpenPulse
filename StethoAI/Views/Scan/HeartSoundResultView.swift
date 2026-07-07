import SwiftUI

struct HeartSoundResultView: View {
    let result: HeartSoundResult
    let audioURL: URL?
    let onSave: () -> Void
    let onNewScan: () -> Void
    let onDismiss: () -> Void

    @State private var isSharePresented = false

    private var color: Color {
        switch result.classification {
        case .normal: return Tokens.Colors.successGreen
        case .possibleMurmur: return Tokens.Colors.warningAmber
        case .abnormal: return Tokens.Colors.dangerDark
        }
    }

    private var backgroundTint: Color {
        switch result.classification {
        case .normal: return Tokens.Colors.successBg
        case .possibleMurmur: return Tokens.Colors.warningBg
        case .abnormal: return Tokens.Colors.lightRedTint
        }
    }

    private var headline: String {
        switch result.classification {
        case .normal: return "Your heart sounds normal. Great!"
        case .possibleMurmur: return "We detected a possible extra sound. This is often harmless — consider getting evaluated by a doctor."
        case .abnormal: return "This recording has features worth showing to a doctor."
        }
    }

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
                    Image(systemName: iconName)
                        .font(.system(size: 32))
                        .foregroundStyle(color)

                    Text(result.classification.rawValue)
                        .font(Tokens.Fonts.pageTitle)
                        .foregroundStyle(color)

                    Text(headline)
                        .font(Tokens.Fonts.body)
                        .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                        .multilineTextAlignment(.center)

                    Text("\(Int(result.confidence * 100))% confidence")
                        .font(Tokens.Fonts.caption)
                        .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                }
                .padding(Tokens.Spacing.lg)
                .frame(maxWidth: .infinity)
                .background(backgroundTint)
                .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.card, style: .continuous))

                HeartSoundPlayerView(url: audioURL)

                Card {
                    VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
                        Text("Detailed breakdown")
                            .font(Tokens.Fonts.cardTitle)
                            .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)

                        breakdownBar(label: "S1 clarity", value: result.s1Clarity)
                        breakdownBar(label: "S2 clarity", value: result.s2Clarity)
                        breakdownBar(label: "S3/S4 detection", value: max(result.s3Detected, result.s4Detected))
                        breakdownBar(label: "Murmur likelihood", value: result.murmurLikelihood)
                    }
                }

                if result.classification != .normal {
                    ConsultDoctorCTA()
                }

                VStack(spacing: Tokens.Spacing.sm) {
                    PrimaryButton(title: "Save Recording", icon: "tray.and.arrow.down.fill", action: onSave)
                    SecondaryButton(title: "Share with Doctor", icon: "square.and.arrow.up", action: { isSharePresented = true })
                    SecondaryButton(title: "New Scan", icon: "arrow.clockwise", action: onNewScan)
                }

                DisclaimerFooter(text: "Educational use only · Not medical advice.")
            }
            .padding(Tokens.Spacing.lg)
        }
        .sheet(isPresented: $isSharePresented) {
            ShareSheet(items: shareItems)
        }
    }

    private var shareItems: [Any] {
        var items: [Any] = ["StethoAI heart sound recording (\(Int(result.confidence * 100))% signal confidence). Educational use only, not medical advice."]
        if let audioURL, FileManager.default.fileExists(atPath: audioURL.path) {
            items.append(audioURL)
        }
        return items
    }

    private var iconName: String {
        switch result.classification {
        case .normal: return "checkmark.seal.fill"
        case .possibleMurmur: return "exclamationmark.triangle.fill"
        case .abnormal: return "exclamationmark.octagon.fill"
        }
    }

    private func breakdownBar(label: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
            HStack {
                Text(label)
                    .font(Tokens.Fonts.body)
                    .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                Spacer()
                Text("\(Int(value * 100))%")
                    .font(Tokens.Fonts.caption)
                    .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Tokens.Colors.adaptiveLightRedTint)
                    Capsule().fill(Tokens.Colors.primaryRed)
                        .frame(width: proxy.size.width * value)
                }
            }
            .frame(height: 6)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
