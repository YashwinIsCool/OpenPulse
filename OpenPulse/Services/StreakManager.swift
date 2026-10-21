import Foundation
import SwiftData

/// Owns the streak increment/reset rules. A streak increments once per calendar
/// day — only when every task in the day's plan is complete — and resets to zero
/// once a full day is skipped (checked both reactively and passively on launch).
enum StreakManager {
    /// The day's plan is complete when the heart rate check, stress log, and
    /// breathing session are all done — plus the heart sound scan on its weekly day.
    static func allDailyTasksComplete(context: ModelContext, user: User, asOf date: Date = .now) -> Bool {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return false }

        func hasAny<T: PersistentModel>(_ type: T.Type, _ predicate: Predicate<T>) -> Bool {
            var descriptor = FetchDescriptor<T>(predicate: predicate)
            descriptor.fetchLimit = 1
            return ((try? context.fetchCount(descriptor)) ?? 0) > 0
        }

        let hasHeartRate = hasAny(HeartRateReading.self, #Predicate { $0.timestamp >= start && $0.timestamp < end })
        let hasBreathing = hasAny(BreathingSession.self, #Predicate { $0.timestamp >= start && $0.timestamp < end })

        // Evaluate the check-in in Swift — the combined optional check is too complex
        // for SwiftData's predicate type-checker.
        let todaysLogs = (try? context.fetch(FetchDescriptor<DailyLog>(
            predicate: #Predicate { $0.date >= start && $0.date < end }
        ))) ?? []
        let hasCheckIn = todaysLogs.contains { $0.hasCheckIn }

        let isHeartSoundDay = calendar.component(.weekday, from: date) == user.heartSoundWeekday
        let hasHeartSound = !isHeartSoundDay || hasAny(HeartSoundRecording.self, #Predicate { $0.timestamp >= start && $0.timestamp < end })

        return hasHeartRate && hasCheckIn && hasBreathing && hasHeartSound
    }

    /// Call after any daily task completes: bumps the streak only once the full
    /// plan is done for the day. Returns true if this call completed the day.
    @discardableResult
    static func updateStreakIfDayComplete(context: ModelContext, user: User, asOf date: Date = .now) -> Bool {
        guard !hasCheckedInToday(for: user, asOf: date) else { return false }
        guard allDailyTasksComplete(context: context, user: user, asOf: date) else { return false }
        recordCheckIn(for: user, at: date)
        return true
    }

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
