import SwiftUI
import Combine

/// Light, dark, or follow the iPhone's setting.
enum Appearance: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "Match iPhone"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// Lightweight UserDefaults-backed settings: onboarding state and notification
/// preferences. Profile data itself lives in the SwiftData `User` model.
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private let defaults: UserDefaults

    @Published var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding) }
    }

    @Published var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: Keys.notificationsEnabled) }
    }

    @Published var morningCheckEnabled: Bool {
        didSet { defaults.set(morningCheckEnabled, forKey: Keys.morningCheckEnabled) }
    }

    @Published var eveningBreathingEnabled: Bool {
        didSet { defaults.set(eveningBreathingEnabled, forKey: Keys.eveningBreathingEnabled) }
    }

    @Published var weeklyInsightEnabled: Bool {
        didSet { defaults.set(weeklyInsightEnabled, forKey: Keys.weeklyInsightEnabled) }
    }

    @Published var morningTime: Date {
        didSet { defaults.set(morningTime, forKey: Keys.morningTime) }
    }

    @Published var eveningTime: Date {
        didSet { defaults.set(eveningTime, forKey: Keys.eveningTime) }
    }

    /// When on, the app fills with realistic sample data and heart-rate readings
    /// return believable values — used for demo screenshots and video.
    @Published var isDemoMode: Bool {
        didSet { defaults.set(isDemoMode, forKey: Keys.isDemoMode) }
    }

    @Published var appearance: Appearance {
        didSet { defaults.set(appearance.rawValue, forKey: Keys.appearance) }
    }

    private enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let notificationsEnabled = "notificationsEnabled"
        static let morningCheckEnabled = "morningCheckEnabled"
        static let eveningBreathingEnabled = "eveningBreathingEnabled"
        static let weeklyInsightEnabled = "weeklyInsightEnabled"
        static let morningTime = "morningTime"
        static let eveningTime = "eveningTime"
        static let isDemoMode = "isDemoMode"
        static let appearance = "appearance"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.hasCompletedOnboarding = defaults.bool(forKey: Keys.hasCompletedOnboarding)
        self.notificationsEnabled = defaults.object(forKey: Keys.notificationsEnabled) as? Bool ?? true
        self.morningCheckEnabled = defaults.object(forKey: Keys.morningCheckEnabled) as? Bool ?? true
        self.eveningBreathingEnabled = defaults.object(forKey: Keys.eveningBreathingEnabled) as? Bool ?? true
        self.weeklyInsightEnabled = defaults.object(forKey: Keys.weeklyInsightEnabled) as? Bool ?? true
        self.isDemoMode = defaults.bool(forKey: Keys.isDemoMode)
        self.appearance = Appearance(rawValue: defaults.string(forKey: Keys.appearance) ?? "") ?? .system

        let calendar = Calendar.current
        self.morningTime = defaults.object(forKey: Keys.morningTime) as? Date
            ?? calendar.date(bySettingHour: 8, minute: 0, second: 0, of: .now) ?? .now
        self.eveningTime = defaults.object(forKey: Keys.eveningTime) as? Date
            ?? calendar.date(bySettingHour: 21, minute: 0, second: 0, of: .now) ?? .now
    }
}
