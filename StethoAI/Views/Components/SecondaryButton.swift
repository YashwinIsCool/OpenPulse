import SwiftUI

struct SecondaryButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Tokens.Spacing.sm) {
                Text(title)
                    .font(Tokens.Fonts.cardTitle)
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Tokens.Padding.button)
            .foregroundStyle(Tokens.Colors.primaryRed)
            .background(Tokens.Colors.adaptiveCard)
            .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.button, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Tokens.Radius.button, style: .continuous)
                    .stroke(Tokens.Colors.lightRedTint, lineWidth: 1)
            )
        }
    }
}
