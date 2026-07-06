import SwiftUI
import SwiftData

struct RootView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query private var users: [User]

    var body: some View {
        Group {
            if settings.hasCompletedOnboarding, let user = users.first {
                MainTabView(user: user)
            } else {
                OnboardingContainerView(onComplete: { settings.hasCompletedOnboarding = true })
            }
        }
        .onAppear(perform: ensureUserExists)
        .onAppear(perform: reconcileStreak)
        .onChange(of: scenePhase) { _, newPhase in
            guard let user = users.first else { return }
            switch newPhase {
            case .active:
                StreakManager.reconcileMissedDays(for: user)
                NotificationManager.shared.cancelStreakProtection()
            case .background:
                NotificationManager.shared.scheduleStreakProtectionIfNeeded(user: user, settings: settings)
            default:
                break
            }
        }
    }

    private func ensureUserExists() {
        guard users.isEmpty else { return }
        modelContext.insert(User())
    }

    private func reconcileStreak() {
        guard let user = users.first else { return }
        StreakManager.reconcileMissedDays(for: user)
    }
}
