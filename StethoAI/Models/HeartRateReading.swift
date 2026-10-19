import Foundation
import SwiftData

enum HeartRateCategory: String, Codable {
    case low = "LOW"
    case restingNormal = "RESTING NORMAL"
    case elevated = "ELEVATED"
    case high = "HIGH"

    /// Very active people commonly rest in the 40s, so for them the "low" line
    /// moves down to 40 instead of 50.
    static func lowThreshold(for activity: ActivityLevel) -> Int {
        activity == .veryActive ? 40 : 50
    }

    static func categorize(bpm: Int, activity: ActivityLevel = .notSet) -> HeartRateCategory {
        if bpm < lowThreshold(for: activity) { return .low }
        if bpm < 90 { return .restingNormal }
        if bpm < 120 { return .elevated }
        return .high
    }

    /// A resting reading outside the normal range that warrants pointing the person
    /// toward care. Deliberately conservative — awareness, never a diagnosis.
    var isConcerning: Bool {
        self == .low || self == .high
    }

    /// Plain-language, non-alarming context for the reading.
    var plainGuidance: String {
        switch self {
        case .restingNormal:
            return "This resting heart rate is in a typical range. Keep checking in over time."
        case .elevated:
            return "This is a little higher than a typical resting rate — often from activity, caffeine, or stress. If it stays high at rest, it's worth showing to a health worker."
        case .high:
            return "This resting reading is high. It can be harmless, but it's worth having a health worker or doctor take a look."
        case .low:
            return "This resting reading is low. That's normal for some fit people, but if you feel dizzy or unwell, it's worth having someone check."
        }
    }
}

enum ReadingSource: String, Codable {
    case auto
    case manual
}

@Model
final class HeartRateReading {
    var timestamp: Date
    var bpm: Int
    var hrvMs: Double?
    var categoryRaw: String
    var sourceRaw: String

    var category: HeartRateCategory {
        get { HeartRateCategory(rawValue: categoryRaw) ?? .restingNormal }
        set { categoryRaw = newValue.rawValue }
    }

    var source: ReadingSource {
        get { ReadingSource(rawValue: sourceRaw) ?? .auto }
        set { sourceRaw = newValue.rawValue }
    }

    init(timestamp: Date = .now, bpm: Int, hrvMs: Double? = nil, category: HeartRateCategory, source: ReadingSource = .auto) {
        self.timestamp = timestamp
        self.bpm = bpm
        self.hrvMs = hrvMs
        self.categoryRaw = category.rawValue
        self.sourceRaw = source.rawValue
    }
}
