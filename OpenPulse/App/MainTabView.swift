import SwiftUI

/// Three tabs, named for what people come to do: check their heart, look back at
/// their history, or get help (care, learning, and settings).
struct MainTabView: View {
    let user: User

    var body: some View {
        TabView {
            HomeView(user: user)
                .tabItem { Label("Check", systemImage: "heart") }

            TrendsView(user: user)
                .tabItem { Label("History", systemImage: "chart.line.uptrend.xyaxis") }

            MoreView(user: user)
                .tabItem { Label("Help", systemImage: "questionmark.circle") }
        }
        .tint(Tokens.Colors.ink)
    }
}
