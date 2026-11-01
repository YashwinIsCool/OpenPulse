import Foundation
import SwiftData

/// Seeds and clears realistic demo data so clean demo screenshots can be
/// captured on the real app (a populated streak, history, insights, etc.).
/// Not shipped-facing — toggled from the More tab's Developer section.
enum HeartSampleData {
    static func seed(context: ModelContext, user: User) {
        clear(context: context, user: user)

        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)

        for dayOffset in stride(from: 20, through: 0, by: -1) {
            guard let day = cal.date(byAdding: .day, value: -dayOffset, to: today) else { continue }

            // Resting heart rate trending gently down over the 3 weeks (improving fitness).
            let base = 78 - Int(Double(20 - dayOffset) * 0.45)

            // Daily context, with a couple of real correlations baked in.
            let sleep = Double([5, 6, 6, 7, 7, 8, 8].randomElement() ?? 7)
            let caffeine = [0, 1, 1, 2, 2].randomElement() ?? 1
            let exercise = [0, 15, 40, 75].randomElement() ?? 0
            let stress = Int.random(in: 1...5)
            let mood = Int.random(in: 2...5)

            var bpm = base
            if sleep < 7 { bpm += 6 }
            if caffeine >= 2 { bpm += 4 }
            if stress >= 4 { bpm += 5 }
            if exercise >= 20 { bpm -= 3 }
            bpm += Int.random(in: -2...2)
            bpm = max(58, min(88, bpm))

            let ts = cal.date(bySettingHour: 8, minute: Int.random(in: 0...59), second: 0, of: day) ?? day
            context.insert(HeartRateReading(
                timestamp: ts,
                bpm: bpm,
                hrvMs: Double.random(in: 42...58),
                category: .categorize(bpm: bpm),
                source: .auto
            ))

            let logDate = cal.date(bySettingHour: 9, minute: 0, second: 0, of: day) ?? day
            context.insert(DailyLog(
                date: logDate,
                stressLevel: stress,
                sleepHours: sleep,
                caffeineCups: caffeine,
                exerciseMinutes: exercise,
                mood: mood
            ))

            if Bool.random(), let bDate = cal.date(bySettingHour: 21, minute: 0, second: 0, of: day) {
                context.insert(BreathingSession(timestamp: bDate, exerciseType: .fourSevenEight, duration: 240))
            }
        }

        user.streakCount = 12
        user.lastActiveDate = .now
        if user.name.isEmpty { user.name = "Yashwin" }
    }

    static func clear(context: ModelContext, user: User) {
        deleteAll(HeartRateReading.self, context: context)
        deleteAll(DailyLog.self, context: context)
        deleteAll(BreathingSession.self, context: context)
        deleteAll(Insight.self, context: context)
        user.streakCount = 0
        user.lastActiveDate = nil
    }

    private static func deleteAll<T: PersistentModel>(_ type: T.Type, context: ModelContext) {
        for item in (try? context.fetch(FetchDescriptor<T>())) ?? [] {
            context.delete(item)
        }
    }
}
