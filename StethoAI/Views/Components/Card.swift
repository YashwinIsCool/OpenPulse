import SwiftUI

/// White card, 1pt border, 14pt corner radius, 14pt padding.
struct Card<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(Tokens.Padding.card)
            .background(Tokens.Colors.adaptiveCard)
            .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Tokens.Radius.card, style: .continuous)
                    .stroke(Tokens.Colors.adaptiveBorder, lineWidth: 1)
            )
    }
}
