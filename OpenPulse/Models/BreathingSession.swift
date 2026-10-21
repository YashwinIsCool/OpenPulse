import Foundation
import SwiftData

enum BreathingExerciseType: String, Codable, CaseIterable {
    case fourSevenEight = "4-7-8 Breathing"
    case box = "Box Breathing"
    case coherent = "Coherent Breathing"

    var subtitle: String {
        switch self {
        case .fourSevenEight: return "Calming"
        case .box: return "Focus"
        case .coherent: return "Slow and steady"
        }
    }

    var durationSeconds: Int {
        switch self {
        case .fourSevenEight: return 120
        case .box: return 180
        case .coherent: return 300
        }
    }

    /// Phase durations in seconds: (label, seconds). Empty "hold" phases are skipped.
    var phases: [(label: String, seconds: Int)] {
        switch self {
        case .fourSevenEight:
            return [("Breathe in", 4), ("Hold", 7), ("Breathe out", 8)]
        case .box:
            return [("Breathe in", 4), ("Hold", 4), ("Breathe out", 4), ("Hold", 4)]
        case .coherent:
            return [("Breathe in", 5), ("Breathe out", 5)]
        }
    }
}

@Model
final class BreathingSession {
    var timestamp: Date
    var exerciseTypeRaw: String
    var duration: Int

    var exerciseType: BreathingExerciseType {
        get { BreathingExerciseType(rawValue: exerciseTypeRaw) ?? .box }
        set { exerciseTypeRaw = newValue.rawValue }
    }

    init(timestamp: Date = .now, exerciseType: BreathingExerciseType, duration: Int) {
        self.timestamp = timestamp
        self.exerciseTypeRaw = exerciseType.rawValue
        self.duration = duration
    }
}
