import SwiftUI

struct StreakBadge: View {
    let dayCount: Int

    var body: some View {
        HStack(spacing: Tokens.Spacing.xs) {
            Image(systemName: "flame.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Tokens.Colors.warningAmber)
            Text("\(dayCount)")
                .font(Tokens.Fonts.cardTitle)
                .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
        }
        .padding(.horizontal, Tokens.Spacing.md)
        .padding(.vertical, Tokens.Spacing.sm)
        .background(Tokens.Colors.adaptiveSoftRedSurface)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Tokens.Colors.adaptiveLightRedTint, lineWidth: 1))
    }
}
