import Foundation

/// Owns the streak increment/reset rules. A streak increments once per calendar
/// day on the first qualifying check-in, and resets to zero once a full day is
/// skipped (checked both reactively on check-in and passively on launch).
enum StreakManager {
    static func recordCheckIn(for user: User, at date: Date = .now) {
        let calendar = Calendar.current
        if let last = user.lastActiveDate {
            if calendar.isDate(last, inSameDayAs: date) {
                return
            }
            let daysBetween = calendar.dateComponents(
                [.day],
                from: calendar.startOfDay(for: last),
                to: calendar.startOfDay(for: date)
            ).day ?? 0
            user.streakCount = daysBetween == 1 ? user.streakCount + 1 : 1
        } else {
            user.streakCount = 1
        }
        user.lastActiveDate = date
    }

    /// Call on launch / foreground to zero out a streak that was broken while the app was closed.
    static func reconcileMissedDays(for user: User, asOf date: Date = .now) {
        guard let last = user.lastActiveDate, user.streakCount > 0 else { return }
        let calendar = Calendar.current
        let daysBetween = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: last),
            to: calendar.startOfDay(for: date)
        ).day ?? 0
        if daysBetween > 1 {
            user.streakCount = 0
        }
    }

    static func hasCheckedInToday(for user: User, asOf date: Date = .now) -> Bool {
        guard let last = user.lastActiveDate else { return false }
        return Calendar.current.isDate(last, inSameDayAs: date)
    }
}
