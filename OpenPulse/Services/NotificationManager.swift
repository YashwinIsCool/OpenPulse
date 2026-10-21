import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    private enum Identifiers {
        static let morningCheck = "morningCheck"
        static let eveningBreathing = "eveningBreathing"
        static let streakProtection = "streakProtection"
        static let weeklyInsight = "weeklyInsight"
    }

    func scheduleAllNotifications(settings: AppSettings) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [
            Identifiers.morningCheck, Identifiers.eveningBreathing, Identifiers.weeklyInsight
        ])

        guard settings.notificationsEnabled else { return }

        if settings.morningCheckEnabled {
            schedule(
                identifier: Identifiers.morningCheck,
                title: "Good morning",
                body: "Ready for your 30-second heart check?",
                at: settings.morningTime,
                repeatsDaily: true
            )
        }

        if settings.eveningBreathingEnabled {
            schedule(
                identifier: Identifiers.eveningBreathing,
                title: "Wind down",
                body: "Take a minute for a breathing exercise.",
                at: settings.eveningTime,
                repeatsDaily: true
            )
        }

        if settings.weeklyInsightEnabled {
            var components = Calendar.current.dateComponents([.hour, .minute], from: settings.morningTime)
            components.weekday = 2 // Monday
            let content = UNMutableNotificationContent()
            content.title = "Your weekly insight is ready"
            content.body = "See how your heart health trended this week."
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            center.add(UNNotificationRequest(identifier: Identifiers.weeklyInsight, content: content, trigger: trigger))
        }
    }

    private func schedule(identifier: String, title: String, body: String, at time: Date, repeatsDaily: Bool) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: repeatsDaily)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    /// Fires once at 8pm if the user hasn't checked in yet today. Call when the app backgrounds.
    func scheduleStreakProtectionIfNeeded(user: User, settings: AppSettings) {
        guard settings.notificationsEnabled, !StreakManager.hasCheckedInToday(for: user) else { return }
        let calendar = Calendar.current
        guard let eightPM = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: .now), eightPM > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = "Don't break your streak"
        content.body = user.streakCount > 0
            ? "You haven't done today's heart check yet. Keep your \(user.streakCount)-day streak alive."
            : "You haven't done today's heart check yet."
        content.sound = .default

        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: eightPM)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: Identifiers.streakProtection, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelStreakProtection() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Identifiers.streakProtection])
    }
}
