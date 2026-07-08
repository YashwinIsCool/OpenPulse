import Foundation

/// A single personal finding surfaced to the user.
struct PersonalInsight: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let body: String
    let strength: Double   // used only for ranking (bigger = more notable)
}

/// The result of an analysis pass, including cold-start progress info.
struct InsightResult {
    let insights: [PersonalInsight]
    let daysAnalyzed: Int   // days that have BOTH a heart-rate reading and a check-in
    let daysNeeded: Int

    var hasEnoughData: Bool { daysAnalyzed >= daysNeeded }
    var daysRemaining: Int { max(0, daysNeeded - daysAnalyzed) }
}

/// Finds honest, personal patterns by correlating daily heart-rate averages against
/// the factors the user logs (sleep, caffeine, exercise, stress, mood, weekday).
///
/// Deliberately rule-based and conservative: it only reports a pattern when each
/// side of a comparison has enough days and the difference is meaningful, so it
/// never fabricates a finding. These are wellness observations, not diagnoses.
enum HeartInsightEngine {
    static let daysNeeded = 5
    private static let minPerGroup = 3
    private static let minDiffBPM = 3.0

    static func analyze(readings: [HeartRateReading], logs: [DailyLog], asOf date: Date = .now) -> InsightResult {
        let calendar = Calendar.current

        // Average heart rate per calendar day.
        var hrByDay: [Date: [Int]] = [:]
        for r in readings {
            let day = calendar.startOfDay(for: r.timestamp)
            hrByDay[day, default: []].append(r.bpm)
        }
        var dayHR: [Date: Double] = [:]
        for (day, bpms) in hrByDay where !bpms.isEmpty {
            dayHR[day] = Double(bpms.reduce(0, +)) / Double(bpms.count)
        }

        // Latest check-in per day.
        var logByDay: [Date: DailyLog] = [:]
        for log in logs {
            let day = calendar.startOfDay(for: log.date)
            logByDay[day] = log
        }

        // Days with both a heart-rate average and a check-in.
        let joinedDays = dayHR.keys.filter { logByDay[$0] != nil }
        let daysAnalyzed = joinedDays.count

        guard daysAnalyzed >= daysNeeded else {
            return InsightResult(insights: [], daysAnalyzed: daysAnalyzed, daysNeeded: daysNeeded)
        }

        // Build (hr, log) data points.
        let points: [(hr: Double, log: DailyLog, day: Date)] = joinedDays.compactMap { day in
            guard let hr = dayHR[day], let log = logByDay[day] else { return nil }
            return (hr, log, day)
        }

        var found: [PersonalInsight] = []

        // Sleep: short (<7h) vs adequate (>=7h).
        found += compareBinary(
            points, icon: "bed.double.fill",
            highLabel: nil,
            predicate: { $0.sleepHours.map { $0 < 7 } },
            makeInsight: { diff in
                diff > 0
                    ? PersonalInsight(icon: "bed.double.fill", title: "Sleep affects your heart",
                        body: "Your heart rate averages \(bpm(diff)) bpm higher on days after less than 7 hours of sleep.", strength: diff)
                    : PersonalInsight(icon: "bed.double.fill", title: "Sleep affects your heart",
                        body: "Your heart rate tends to be steadier when you sleep less than 7 hours — keep watching this pattern.", strength: abs(diff))
            }
        )

        // Caffeine: 2+ cups vs fewer.
        found += compareBinary(
            points, icon: "cup.and.saucer.fill",
            highLabel: nil,
            predicate: { $0.caffeineCups.map { $0 >= 2 } },
            makeInsight: { diff in
                guard diff > 0 else { return nil }
                return PersonalInsight(icon: "cup.and.saucer.fill", title: "Caffeine shows up",
                    body: "On days you have 2+ caffeinated drinks, your heart rate runs about \(bpm(diff)) bpm higher.", strength: diff)
            }
        )

        // Exercise: active (>=20 min) vs not.
        found += compareBinary(
            points, icon: "figure.run",
            highLabel: nil,
            predicate: { $0.exerciseMinutes.map { $0 >= 20 } },
            makeInsight: { diff in
                // "high" group = exercised. Lower HR on active days is the good story.
                diff < 0
                    ? PersonalInsight(icon: "figure.run", title: "Exercise is paying off",
                        body: "Your heart rate averages \(bpm(-diff)) bpm lower on days you're active. Nice.", strength: abs(diff))
                    : PersonalInsight(icon: "figure.run", title: "Exercise pattern",
                        body: "Your heart rate is a bit higher on active days — often normal right after a workout.", strength: diff)
            }
        )

        // Stress: high (4-5) vs low (1-2).
        found += compareBinary(
            points, icon: "bolt.heart.fill",
            highLabel: nil,
            predicate: { $0.stressLevel.map { $0 >= 4 } },
            makeInsight: { diff in
                guard diff > 0 else { return nil }
                return PersonalInsight(icon: "bolt.heart.fill", title: "Stress moves your heart",
                    body: "On high-stress days, your heart rate averages \(bpm(diff)) bpm higher than on calm days.", strength: diff)
            }
        )

        // Mood: low (1-2) vs good (4-5).
        found += compareBinary(
            points, icon: "face.smiling",
            highLabel: nil,
            predicate: { $0.mood.map { $0 <= 2 } },
            makeInsight: { diff in
                guard diff > 0 else { return nil }
                return PersonalInsight(icon: "face.smiling", title: "Mood and heart, linked",
                    body: "Your heart rate tends to be \(bpm(diff)) bpm higher on days you log a lower mood.", strength: diff)
            }
        )

        // Weekday pattern.
        if let weekdayInsight = weekdayPattern(points, calendar: calendar) {
            found.append(weekdayInsight)
        }

        // Rank strongest first, cap the feed.
        found.sort { $0.strength > $1.strength }
        var top = Array(found.prefix(4))

        // If nothing crossed the threshold yet, give an honest baseline observation.
        if top.isEmpty {
            let avg = points.map { $0.hr }.reduce(0, +) / Double(points.count)
            top = [PersonalInsight(
                icon: "waveform.path.ecg",
                title: "Building your baseline",
                body: "Your heart rate has averaged \(Int(avg.rounded())) bpm across \(daysAnalyzed) days. Keep checking in on different kinds of days and clearer patterns will surface.",
                strength: 0
            )]
        }

        return InsightResult(insights: top, daysAnalyzed: daysAnalyzed, daysNeeded: daysNeeded)
    }

    // MARK: - Helpers

    /// Splits points by a predicate into "high" (true) and "low" (false) groups and,
    /// if both are large enough and differ meaningfully, builds an insight. `diff` is
    /// meanHigh - meanLow (positive = the "true" group has the higher heart rate).
    private static func compareBinary(
        _ points: [(hr: Double, log: DailyLog, day: Date)],
        icon: String,
        highLabel: String?,
        predicate: (DailyLog) -> Bool?,
        makeInsight: (Double) -> PersonalInsight?
    ) -> [PersonalInsight] {
        var high: [Double] = []
        var low: [Double] = []
        for p in points {
            guard let flag = predicate(p.log) else { continue }
            if flag { high.append(p.hr) } else { low.append(p.hr) }
        }
        guard high.count >= minPerGroup, low.count >= minPerGroup else { return [] }
        let diff = mean(high) - mean(low)
        guard abs(diff) >= minDiffBPM else { return [] }
        return makeInsight(diff).map { [$0] } ?? []
    }

    private static func weekdayPattern(_ points: [(hr: Double, log: DailyLog, day: Date)], calendar: Calendar) -> PersonalInsight? {
        var byWeekday: [Int: [Double]] = [:]
        for p in points {
            let wd = calendar.component(.weekday, from: p.day)
            byWeekday[wd, default: []].append(p.hr)
        }
        // Need at least two weekdays with 2+ readings each.
        let eligible = byWeekday.filter { $0.value.count >= 2 }
        guard eligible.count >= 2 else { return nil }
        let means = eligible.mapValues { mean($0) }
        guard let highest = means.max(by: { $0.value < $1.value }),
              let lowest = means.min(by: { $0.value < $1.value }),
              highest.value - lowest.value >= 4 else { return nil }

        let symbols = Calendar.current.weekdaySymbols
        let idx = highest.key - 1
        guard symbols.indices.contains(idx) else { return nil }
        return PersonalInsight(
            icon: "calendar",
            title: "Your week has a rhythm",
            body: "Your heart rate tends to run highest on \(symbols[idx])s. Worth noticing what those days have in common.",
            strength: highest.value - lowest.value
        )
    }

    private static func mean(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    private static func bpm(_ value: Double) -> Int { max(1, Int(value.rounded())) }
}
