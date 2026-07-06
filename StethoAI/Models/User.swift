import Foundation
import SwiftData

enum BiologicalSex: String, Codable, CaseIterable {
    case female = "Female"
    case male = "Male"
    case preferNotToSay = "Prefer not to say"
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
