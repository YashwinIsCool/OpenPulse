import Foundation
import SwiftData

enum HeartRateCategory: String, Codable {
    case low = "LOW"
    case restingNormal = "RESTING NORMAL"
    case elevated = "ELEVATED"
    case high = "HIGH"

    static func categorize(bpm: Int) -> HeartRateCategory {
        switch bpm {
        case ..<50: return .low
        case 50..<90: return .restingNormal
        case 90..<120: return .elevated
        default: return .high
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
