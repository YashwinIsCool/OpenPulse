import Foundation
import SwiftData

@Model
final class DailyLog {
    var date: Date
    var stressLevel: Int?
    var sleepQuality: Int?
    var notes: String

    init(date: Date = .now, stressLevel: Int? = nil, sleepQuality: Int? = nil, notes: String = "") {
        self.date = date
        self.stressLevel = stressLevel
        self.sleepQuality = sleepQuality
        self.notes = notes
    }
}
