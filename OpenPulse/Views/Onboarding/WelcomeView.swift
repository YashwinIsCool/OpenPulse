import SwiftUI

struct WelcomeView: View {
    let onNext: () -> Void
    @ObservedObject private var loc = Localizer.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            VStack(alignment: .leading, spacing: Tokens.Spacing.lg) {
                Image(systemName: "waveform.path.ecg.rectangle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Tokens.Colors.primaryRed)

                Text(AppInfo.name)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)

                Text(loc.t("A free heart check with just your phone"))
                    .font(Tokens.Fonts.headline)
                    .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)

                VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
                    point("heart", "Measure your heart rate with your phone's camera.")
                    point("chart.line.uptrend.xyaxis", "Keep a heart record you can show a doctor.")
                    point("cross.case", "Find care when a reading looks unusual.")
                }
                .padding(.top, Tokens.Spacing.sm)
            }
            .padding(.horizontal, Tokens.Spacing.xl)

            Spacer()
            Spacer()

            VStack(spacing: Tokens.Spacing.sm) {
                PrimaryButton(title: loc.t("Get started"), action: onNext)
                Text(loc.t("Wellness and education only. Not a medical device."))
                    .font(Tokens.Fonts.secondaryText)
                    .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Tokens.Spacing.xl)
            .padding(.bottom, Tokens.Spacing.xl)
        }
    }

    private func point(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Tokens.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                .frame(width: 24)
            Text(loc.t(text))
                .font(Tokens.Fonts.bodyText)
                .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
