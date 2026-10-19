import SwiftUI

/// Three tabs, named for what people come to do: check their heart, look back at
/// their history, or get help (care, learning, and settings).
struct MainTabView: View {
    let user: User
    @ObservedObject private var loc = Localizer.shared

    var body: some View {
        TabView {
            HomeView(user: user)
                .tabItem { Label(loc.t("Check"), systemImage: "heart") }

            TrendsView(user: user)
                .tabItem { Label(loc.t("History"), systemImage: "chart.line.uptrend.xyaxis") }

            MoreView(user: user)
                .tabItem { Label(loc.t("Help"), systemImage: "questionmark.circle") }
        }
        .tint(Tokens.Colors.ink)
    }
}
