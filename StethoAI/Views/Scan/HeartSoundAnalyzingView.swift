import SwiftUI

struct HeartSoundAnalyzingView: View {
    private let steps = ["Processing audio", "Reducing background noise", "Saving your recording", "Preparing playback"]
    @State private var completedCount = 0
    private let timer = Timer.publish(every: 0.6, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: Tokens.Spacing.xxl) {
            Spacer()

            ProgressView()
                .controlSize(.large)
                .tint(Tokens.Colors.primaryRed)

            VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, label in
                    HStack(spacing: Tokens.Spacing.md) {
                        Image(systemName: index < completedCount ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(index < completedCount ? Tokens.Colors.successGreen : Tokens.Colors.adaptiveTextQuaternary)
                        Text(label)
                            .font(Tokens.Fonts.body)
                            .foregroundStyle(index < completedCount ? Tokens.Colors.adaptiveTextPrimary : Tokens.Colors.adaptiveTextTertiary)
                    }
                }
            }
            .padding(Tokens.Spacing.lg)

            Spacer()
            Spacer()
        }
        .onReceive(timer) { _ in
            if completedCount < steps.count {
                withAnimation { completedCount += 1 }
            }
        }
    }
}
