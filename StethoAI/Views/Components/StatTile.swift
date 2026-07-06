import SwiftUI

/// Soft red surface tile for secondary metrics.
struct StatTile: View {
    var icon: String? = nil
    let label: String
    let value: String
    var valueColor: Color = Tokens.Colors.adaptiveTextPrimary

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
            HStack(spacing: Tokens.Spacing.xs) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Tokens.Colors.primaryRed)
                }
                Text(label.uppercased())
                    .font(Tokens.Fonts.microLabel)
                    .tracking(Tokens.Tracking.microLabel)
                    .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
            }
            Text(value)
                .font(Tokens.Fonts.cardTitle)
                .foregroundStyle(valueColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Tokens.Padding.statTile)
        .background(Tokens.Colors.adaptiveSoftRedSurface)
        .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.statTile, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Tokens.Radius.statTile, style: .continuous)
                .stroke(Tokens.Colors.adaptiveLightRedTint, lineWidth: 1)
        )
    }
}
