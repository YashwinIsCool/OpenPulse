import SwiftUI

/// Solid red hero container with two decorative low-opacity circles in the corners.
/// Used for the day's main metric on Home and the current-period metric on Trends.
struct HeroCard<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Tokens.Radius.hero, style: .continuous)
                .fill(Tokens.Colors.primaryRed)

            GeometryReader { proxy in
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 170, height: 170)
                    .position(x: proxy.size.width - 20, y: -20)
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 120, height: 120)
                    .position(x: 10, y: proxy.size.height + 10)
            }

            content()
                .padding(Tokens.Padding.hero)
        }
        .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.hero, style: .continuous))
    }
}
