import SwiftUI

struct HeartSoundRecordingView: View {
    @ObservedObject var recorder: HeartSoundRecorder
    let onCancel: () -> Void
    @ObservedObject private var loc = Localizer.shared

    var body: some View {
        VStack(spacing: Tokens.Spacing.xl) {
            HStack {
                Spacer()
                Button(action: onCancel) {
                    Text(loc.t("Cancel"))
                        .font(.body.weight(.medium))
                        .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                }
            }
            .padding(.horizontal, Tokens.Spacing.lg)
            .padding(.top, Tokens.Spacing.sm)

            Spacer()

            VStack(spacing: Tokens.Spacing.xs) {
                Text("\(recorder.secondsRemaining)")
                    .font(.system(size: 72, weight: .semibold))
                    .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                    .monospacedDigit()
                Text(loc.t("seconds remaining"))
                    .font(Tokens.Fonts.bodyText)
                    .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
            }

            HeartSoundBarsView(levels: recorder.levels)
                .frame(height: 100)
                .padding(.horizontal, Tokens.Spacing.xxl)

            Text(loc.t("Hold still and breathe normally."))
                .font(Tokens.Fonts.bodyText)
                .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)

            Spacer()
            Spacer()
        }
    }
}

private struct HeartSoundBarsView: View {
    let levels: [Double]

    var body: some View {
        Canvas { context, size in
            guard !levels.isEmpty else { return }
            let barSpacing: CGFloat = 3
            let barWidth = max(2, size.width / CGFloat(levels.count) - barSpacing)
            for (index, level) in levels.enumerated() {
                let x = CGFloat(index) * (barWidth + barSpacing)
                let height = max(4, CGFloat(level) * size.height)
                let rect = CGRect(x: x, y: (size.height - height) / 2, width: barWidth, height: height)
                context.fill(Path(roundedRect: rect, cornerRadius: barWidth / 2), with: .color(Tokens.Colors.ink.opacity(0.75)))
            }
        }
    }
}
