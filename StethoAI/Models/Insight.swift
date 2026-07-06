import Foundation
import SwiftData

enum InsightType: String, Codable {
    case heartRateTrend = "Heart rate trend"
    case hrvPattern = "HRV pattern"
    case streakMilestone = "Streak milestone"
    case general = "General"
}

@Model
final class Insight {
    var timestamp: Date
    var typeRaw: String
    var title: String
    var body: String
    var isRead: Bool

    var type: InsightType {
        get { InsightType(rawValue: typeRaw) ?? .general }
        set { typeRaw = newValue.rawValue }
    }

    init(timestamp: Date = .now, type: InsightType, title: String, body: String, isRead: Bool = false) {
        self.timestamp = timestamp
        self.typeRaw = type.rawValue
        self.title = title
        self.body = body
        self.isRead = isRead
    }
}
