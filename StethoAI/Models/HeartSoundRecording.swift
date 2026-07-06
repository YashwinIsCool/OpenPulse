import Foundation
import SwiftData

enum HeartSoundClassification: String, Codable {
    case normal = "Normal"
    case possibleMurmur = "Possible murmur"
    case abnormal = "Abnormal"
}

@Model
final class HeartSoundRecording {
    var timestamp: Date
    var fileURLString: String
    var classificationRaw: String
    var confidence: Double
    var notes: String
    var s1Clarity: Double
    var s2Clarity: Double
    var s3Detected: Double
    var s4Detected: Double
    var murmurLikelihood: Double

    var fileURL: URL? { URL(string: fileURLString) }

    var classification: HeartSoundClassification {
        get { HeartSoundClassification(rawValue: classificationRaw) ?? .normal }
        set { classificationRaw = newValue.rawValue }
    }

    init(
        timestamp: Date = .now,
        fileURLString: String,
        classification: HeartSoundClassification,
        confidence: Double,
        notes: String = "",
        s1Clarity: Double,
        s2Clarity: Double,
        s3Detected: Double,
        s4Detected: Double,
        murmurLikelihood: Double
    ) {
        self.timestamp = timestamp
        self.fileURLString = fileURLString
        self.classificationRaw = classification.rawValue
        self.confidence = confidence
        self.notes = notes
        self.s1Clarity = s1Clarity
        self.s2Clarity = s2Clarity
        self.s3Detected = s3Detected
        self.s4Detected = s4Detected
        self.murmurLikelihood = murmurLikelihood
    }
}
