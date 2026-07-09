import Foundation
import SwiftData

@Model
final class DailyLog {
    var date: Date
    var stressLevel: Int?          // 1 (calm) ... 5 (stressed)
    var sleepQuality: Int?         // legacy, retained for compatibility
    var sleepHours: Double?        // hours slept last night
    var caffeineCups: Int?         // 0, 1, 2, 3 (3 = "3+")
    var exerciseMinutes: Int?      // 0, 15, 40, 75 (bucketed intensity)
    var mood: Int?                 // 1 (low) ... 5 (great)
    var postPlanFeeling: Int?      // 1 (rough) ... 5 (great) — logged after the guided plan
    var notes: String

    init(
        date: Date = .now,
        stressLevel: Int? = nil,
        sleepQuality: Int? = nil,
        sleepHours: Double? = nil,
        caffeineCups: Int? = nil,
        exerciseMinutes: Int? = nil,
        mood: Int? = nil,
        postPlanFeeling: Int? = nil,
        notes: String = ""
    ) {
        self.date = date
        self.stressLevel = stressLevel
        self.sleepQuality = sleepQuality
        self.sleepHours = sleepHours
        self.caffeineCups = caffeineCups
        self.exerciseMinutes = exerciseMinutes
        self.mood = mood
        self.postPlanFeeling = postPlanFeeling
        self.notes = notes
    }

    /// True once the user has logged anything in today's check-in.
    var hasCheckIn: Bool {
        stressLevel != nil || mood != nil || sleepHours != nil || caffeineCups != nil || exerciseMinutes != nil
    }
}
