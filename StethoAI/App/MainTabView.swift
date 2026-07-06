import SwiftUI

struct MainTabView: View {
    let user: User

    init(user: User) {
        self.user = user
        configureTabBarAppearance()
    }

    var body: some View {
        TabView {
            HomeView(user: user)
                .tabItem { Label("Home", systemImage: "house.fill") }

            ScanHomeView(user: user)
                .tabItem { Label("Scan", systemImage: "waveform.path.ecg") }

            TrendsView(user: user)
                .tabItem { Label("Trends", systemImage: "chart.line.uptrend.xyaxis") }

            MoreView(user: user)
                .tabItem { Label("More", systemImage: "ellipsis.circle") }
        }
        .tint(Tokens.Colors.primaryRed)
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Tokens.Colors.adaptiveCard)
        appearance.shadowColor = UIColor(Tokens.Colors.adaptiveBorder)

        let normal = appearance.stackedLayoutAppearance.normal
        normal.iconColor = UIColor(Tokens.Colors.adaptiveTextQuaternary)
        normal.titleTextAttributes = [.foregroundColor: UIColor(Tokens.Colors.adaptiveTextQuaternary)]

        let selected = appearance.stackedLayoutAppearance.selected
        selected.iconColor = UIColor(Tokens.Colors.primaryRed)
        selected.titleTextAttributes = [.foregroundColor: UIColor(Tokens.Colors.primaryRed)]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
