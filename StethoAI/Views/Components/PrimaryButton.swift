import SwiftUI

struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Tokens.Spacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                }
                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .foregroundStyle(Tokens.Colors.onInk)
            .background(isDisabled ? Tokens.Colors.ink.opacity(0.3) : Tokens.Colors.ink)
            .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.button, style: .continuous))
        }
        .disabled(isDisabled)
    }
}
