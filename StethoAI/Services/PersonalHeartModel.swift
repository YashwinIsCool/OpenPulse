import Foundation

/// A small machine-learning model that learns what *your* heart rate usually is,
/// trained on this phone from your own readings and check-ins. Nothing leaves the
/// device.
///
/// How it works: ridge regression (linear regression with a penalty that keeps the
/// learned effects small until the data supports them). It predicts a reading from
/// that day's sleep, caffeine, exercise, stress, mood, and the time of day. Before
/// there's much data, it starts from a rough estimate based on the quiz answers
/// (age band, sex, exercise), and leans more on your own data as readings come in.
///
/// It describes patterns ("usual for you"); it never diagnoses anything.
struct PersonalHeartModel {

    /// One thing the model has learned moves your heart rate.
    struct Effect: Identifiable {
        let id: String
        let icon: String
        let label: String      // e.g. "Each caffeinated drink"
        let bpm: Double        // signed change in bpm for that label
    }

    /// The factors the model looks at. Each turns a reading (plus that day's
    /// check-in) into a number; nil means "not logged" and is treated as typical.
    private struct Feature {
        let id: String
        let icon: String
        let label: String
        /// Multiplier to express the coefficient in the label's terms
        /// (e.g. sleep is learned per hour more, but shown per hour less).
        let displayScale: Double
        let value: (_ date: Date, _ log: DailyLog?) -> Double?
    }

    private static let features: [Feature] = [
        Feature(id: "sleep", icon: "bed.double", label: "Each hour less sleep", displayScale: -1) { _, log in
            log?.sleepHours
        },
        Feature(id: "caffeine", icon: "cup.and.saucer", label: "Each caffeinated drink", displayScale: 1) { _, log in
            log?.caffeineCups.map(Double.init)
        },
        Feature(id: "exercise", icon: "figure.walk", label: "Days you exercise", displayScale: 1) { _, log in
            log?.exerciseMinutes.map { $0 >= 20 ? 1 : 0 }
        },
        Feature(id: "stress", icon: "bolt.heart", label: "Each step up in stress", displayScale: 1) { _, log in
            log?.stressLevel.map(Double.init)
        },
        Feature(id: "mood", icon: "face.smiling", label: "Each step up in mood", displayScale: 1) { _, log in
            log?.mood.map(Double.init)
        },
        Feature(id: "evening", icon: "sunset", label: "Afternoon and evening checks", displayScale: 1) { date, _ in
            Calendar.current.component(.hour, from: date) >= 14 ? 1 : 0
        }
    ]

    /// Readings needed before the model is called "personal" rather than a
    /// starting estimate.
    static let readingsForPersonal = 7
    /// Readings needed before individual effects are shown.
    static let readingsForEffects = 10
    /// Smallest effect worth mentioning, in bpm.
    private static let minEffectBPM = 1.5

    // Learned state
    let starting: Double           // estimate from the profile alone
    private let intercept: Double  // learned shift from the starting estimate
    private let weights: [Double]
    private let means: [Double]
    let readingsUsed: Int
    /// How far off the model's predictions usually are on your own past readings.
    let typicalError: Double?

    var isPersonal: Bool { readingsUsed >= Self.readingsForPersonal }

    // MARK: - Training

    init(user: User, readings: [HeartRateReading], logs: [DailyLog]) {
        let calendar = Calendar.current
        var logByDay: [Date: DailyLog] = [:]
        for log in logs { logByDay[calendar.startOfDay(for: log.date)] = log }

        let starting = Self.startingEstimate(for: user)
        let rows: [(raw: [Double?], y: Double)] = readings.map { reading in
            let log = logByDay[calendar.startOfDay(for: reading.timestamp)]
            return (Self.features.map { $0.value(reading.timestamp, log) }, Double(reading.bpm))
        }

        // Center each feature on its own average; missing values become 0 (= typical).
        let means: [Double] = Self.features.indices.map { j in
            let present = rows.compactMap { $0.raw[j] }
            return present.isEmpty ? 0 : present.reduce(0, +) / Double(present.count)
        }
        let x: [[Double]] = rows.map { row in
            let centered: [Double] = Self.features.indices.map { j -> Double in
                guard let value = row.raw[j] else { return 0 }
                return value - means[j]
            }
            return [1.0] + centered
        }
        let target = rows.map { $0.y - starting }

        // Ridge penalties: a light one on the intercept (so a few readings move it
        // only partway from the starting estimate) and a firmer one on effects.
        let penalties = [2.0] + Array(repeating: 4.0, count: Self.features.count)
        let solution = Self.ridge(x: x, y: target, penalties: penalties)
            ?? Array(repeating: 0, count: penalties.count)

        self.starting = starting
        self.intercept = solution[0]
        self.weights = Array(solution.dropFirst())
        self.means = means
        self.readingsUsed = rows.count

        if rows.count >= Self.readingsForPersonal {
            let squaredErrors = zip(x, target).map { xi, yi -> Double in
                let predicted = zip(xi, solution).map(*).reduce(0, +)
                return (yi - predicted) * (yi - predicted)
            }
            self.typicalError = (squaredErrors.reduce(0, +) / Double(rows.count)).squareRoot()
        } else {
            self.typicalError = nil
        }
    }

    // MARK: - Using the model

    /// The heart rate the model expects for a reading taken now, given today's
    /// check-in (if any).
    func expectedBPM(at date: Date = .now, log: DailyLog?) -> Double {
        var value = starting + intercept
        for (j, feature) in Self.features.enumerated() {
            if let raw = feature.value(date, log) {
                value += weights[j] * (raw - means[j])
            }
        }
        return value
    }

    /// The effects the model is confident enough to show, biggest first.
    var effects: [Effect] {
        guard readingsUsed >= Self.readingsForEffects else { return [] }
        return Self.features.enumerated()
            .map { j, f in Effect(id: f.id, icon: f.icon, label: f.label, bpm: weights[j] * f.displayScale) }
            .filter { abs($0.bpm) >= Self.minEffectBPM }
            .sorted { abs($0.bpm) > abs($1.bpm) }
    }

    /// How a new reading compares with what the model expected.
    enum Comparison { case inLine, higher, lower }

    func compare(bpm: Int, log: DailyLog?, at date: Date = .now) -> (expected: Int, comparison: Comparison) {
        let expected = expectedBPM(at: date, log: log)
        let band = max(5, (typicalError ?? 6) * 1.5)
        let diff = Double(bpm) - expected
        let comparison: Comparison = diff > band ? .higher : (diff < -band ? .lower : .inLine)
        return (Int(expected.rounded()), comparison)
    }

    // MARK: - Starting estimate

    /// A rough typical resting heart rate for someone with these quiz answers,
    /// used only until the model has learned from the person's own readings.
    static func startingEstimate(for user: User) -> Double {
        var estimate = 72.0
        switch user.activityLevel {
        case .rarely: estimate += 4
        case .sometimes: estimate += 1
        case .often: estimate -= 3
        case .veryActive: estimate -= 9
        case .notSet: break
        }
        switch user.sex {
        case .female: estimate += 2
        case .male: estimate -= 1
        case .preferNotToSay: break
        }
        if let age = user.age, age < 18 { estimate += 4 }
        return estimate
    }

    // MARK: - Math

    /// Solves (XᵀX + diag(penalties)) w = Xᵀy with Gaussian elimination.
    private static func ridge(x: [[Double]], y: [Double], penalties: [Double]) -> [Double]? {
        let k = penalties.count
        var a = Array(repeating: Array(repeating: 0.0, count: k + 1), count: k)
        for i in 0..<k {
            for j in 0..<k {
                a[i][j] = zip(x, x).reduce(0) { $0 + $1.0[i] * $1.1[j] }
            }
            a[i][i] += penalties[i]
            a[i][k] = zip(x, y).reduce(0) { $0 + $1.0[i] * $1.1 }
        }
        for col in 0..<k {
            guard let pivot = (col..<k).max(by: { abs(a[$0][col]) < abs(a[$1][col]) }),
                  abs(a[pivot][col]) > 1e-9 else { return nil }
            a.swapAt(col, pivot)
            for row in 0..<k where row != col {
                let factor = a[row][col] / a[col][col]
                for c in col...k { a[row][c] -= factor * a[col][c] }
            }
        }
        return (0..<k).map { a[$0][k] / a[$0][$0] }
    }
}
