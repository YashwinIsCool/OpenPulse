import SwiftUI

struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var isDisabled: Bool = false
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
            .foregroundStyle(.white)
            .background(isDisabled ? Tokens.Colors.primaryRed.opacity(0.4) : Tokens.Colors.primaryRed)
            .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.button, style: .continuous))
        }
        .disabled(isDisabled)
    }
}
