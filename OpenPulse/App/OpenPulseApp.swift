import SwiftUI
import SwiftData

@main
struct OpenPulseApp: App {
    @StateObject private var settings = AppSettings.shared

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            HeartRateReading.self,
            BreathingSession.self,
            DailyLog.self,
            Insight.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .tint(Tokens.Colors.primaryRed)
        }
        .modelContainer(sharedModelContainer)
    }
}
