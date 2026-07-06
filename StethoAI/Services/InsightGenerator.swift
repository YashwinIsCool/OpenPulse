import Foundation

/// v1 insight generation is rule-based: compare this week's averages against last
/// week's and surface a canned template. A future version can swap this for an
/// LLM call without changing how insights are stored or displayed.
enum InsightGenerator {
    static func generateWeeklyInsight(user: User, readings: [HeartRateReading]) -> Insight {
        let calendar = Calendar.current
        let now = Date.now
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: now) ?? now

        let thisWeek = readings.filter { $0.timestamp >= weekAgo }
        let lastWeek = readings.filter { $0.timestamp >= twoWeeksAgo && $0.timestamp < weekAgo }

        let milestones = [7, 14, 30, 60, 100, 180, 365]
        if milestones.contains(user.streakCount) {
            return Insight(
                type: .streakMilestone,
                title: "Streak milestone",
                body: "You've kept a \(user.streakCount)-day streak. Your consistency is paying off."
            )
        }

        if !thisWeek.isEmpty, !lastWeek.isEmpty {
            let diff = average(thisWeek) - average(lastWeek)
            if diff <= -2 {
                return Insight(
                    type: .heartRateTrend,
                    title: "Trending down",
                    body: "Your resting heart rate dropped \(abs(diff)) bpm this week — a good sign of improved fitness."
                )
            } else if diff >= 2 {
                return Insight(
                    type: .heartRateTrend,
                    title: "Trending up",
                    body: "Your resting heart rate rose \(diff) bpm this week. Keep an eye on stress and sleep."
                )
            } else {
                return Insight(
                    type: .heartRateTrend,
                    title: "Steady as it goes",
                    body: "Your resting heart rate has been stable this week. Keep up your daily checks."
                )
            }
        }

        if let weekday = lowestHRVWeekday(in: thisWeek) {
            return Insight(
                type: .hrvPattern,
                title: "HRV pattern",
                body: "Your HRV tends to be lowest on \(weekday)s. Might be worth watching stress on those days."
            )
        }

        return Insight(
            type: .general,
            title: "Get started",
            body: "Complete a few heart checks this week to unlock personalized insights."
        )
    }

    private static func average(_ readings: [HeartRateReading]) -> Int {
        guard !readings.isEmpty else { return 0 }
        let sum = readings.reduce(0) { $0 + $1.bpm }
        return Int((Double(sum) / Double(readings.count)).rounded())
    }

    private static func lowestHRVWeekday(in readings: [HeartRateReading]) -> String? {
        let withHRV = readings.compactMap { reading -> (Int, Double)? in
            guard let hrv = reading.hrvMs else { return nil }
            return (Calendar.current.component(.weekday, from: reading.timestamp), hrv)
        }
        guard withHRV.count >= 3 else { return nil }

        var sums: [Int: (total: Double, count: Int)] = [:]
        for (weekday, hrv) in withHRV {
            sums[weekday, default: (0, 0)].total += hrv
            sums[weekday, default: (0, 0)].count += 1
        }
        guard sums.count >= 2, let lowest = sums.min(by: { $0.value.total / Double($0.value.count) < $1.value.total / Double($1.value.count) }) else {
            return nil
        }

        let symbols = DateFormatter().weekdaySymbols ?? []
        let index = lowest.key - 1
        guard symbols.indices.contains(index) else { return nil }
        return symbols[index]
    }
}
