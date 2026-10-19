import Foundation
import SwiftData

enum BiologicalSex: String, Codable, CaseIterable {
    case female = "Female"
    case male = "Male"
    case preferNotToSay = "Prefer not to say"
}

/// How often someone exercises, from the onboarding quiz. Gives the app context:
/// very active people often have a resting heart rate in the 40s, which is normal
/// for them, and it seeds the personal heart model before it has much data.
enum ActivityLevel: String, Codable, CaseIterable {
    case notSet
    case rarely
    case sometimes
    case often
    case veryActive

    static var answerable: [ActivityLevel] { [.rarely, .sometimes, .often, .veryActive] }

    var title: String {
        switch self {
        case .notSet: return "Not set"
        case .rarely: return "Rarely or never"
        case .sometimes: return "1–2 days a week"
        case .often: return "3–4 days a week"
        case .veryActive: return "Most days"
        }
    }

    var detail: String? {
        switch self {
        case .veryActive: return "Training, sports, or hard workouts"
        case .often: return "Regular walks, runs, or workouts"
        default: return nil
        }
    }
}

@Model
final class User {
    var name: String
    var age: Int?
    var sexRaw: String
    var createdAt: Date
    var streakCount: Int
    var lastActiveDate: Date?
    var heartSoundWeekday: Int // 1 = Sunday ... 7 = Saturday, matches Calendar.component(.weekday)
    // Default value keeps SwiftData's automatic migration working for existing installs.
    var activityLevelRaw: String = ActivityLevel.notSet.rawValue

    var activityLevel: ActivityLevel {
        get { ActivityLevel(rawValue: activityLevelRaw) ?? .notSet }
        set { activityLevelRaw = newValue.rawValue }
    }

    var sex: BiologicalSex {
        get { BiologicalSex(rawValue: sexRaw) ?? .preferNotToSay }
        set { sexRaw = newValue.rawValue }
    }

    init(
        name: String = "",
        age: Int? = nil,
        sex: BiologicalSex = .preferNotToSay,
        createdAt: Date = .now,
        streakCount: Int = 0,
        lastActiveDate: Date? = nil,
        heartSoundWeekday: Int = 2
    ) {
        self.name = name
        self.age = age
        self.sexRaw = sex.rawValue
        self.createdAt = createdAt
        self.streakCount = streakCount
        self.lastActiveDate = lastActiveDate
        self.heartSoundWeekday = heartSoundWeekday
    }
}
