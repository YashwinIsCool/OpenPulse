import Foundation

struct HeartSoundResult {
    let classification: HeartSoundClassification
    let confidence: Double
    let s1Clarity: Double
    let s2Clarity: Double
    let s3Detected: Double
    let s4Detected: Double
    let murmurLikelihood: Double
}

/// v1 placeholder — no real ML runs here. Returns a plausible, weighted-random
/// result (mostly "Normal") so the full result UI, including the murmur/abnormal
/// states, can be exercised end to end. Will be swapped for a Core ML model
/// trained on the CirCor dataset in v2.
enum HeartSoundAnalyzer {
    static func analyzeHeartSound(_ audio: URL) -> HeartSoundResult {
        let roll = Double.random(in: 0...1)
        switch roll {
        case 0..<0.75:
            return HeartSoundResult(
                classification: .normal,
                confidence: .random(in: 0.88...0.98),
                s1Clarity: .random(in: 0.80...0.98),
                s2Clarity: .random(in: 0.80...0.98),
                s3Detected: .random(in: 0.0...0.15),
                s4Detected: .random(in: 0.0...0.15),
                murmurLikelihood: .random(in: 0.02...0.15)
            )
        case 0.75..<0.93:
            return HeartSoundResult(
                classification: .possibleMurmur,
                confidence: .random(in: 0.60...0.85),
                s1Clarity: .random(in: 0.60...0.85),
                s2Clarity: .random(in: 0.60...0.85),
                s3Detected: .random(in: 0.10...0.40),
                s4Detected: .random(in: 0.10...0.30),
                murmurLikelihood: .random(in: 0.40...0.70)
            )
        default:
            return HeartSoundResult(
                classification: .abnormal,
                confidence: .random(in: 0.65...0.90),
                s1Clarity: .random(in: 0.40...0.70),
                s2Clarity: .random(in: 0.40...0.70),
                s3Detected: .random(in: 0.30...0.60),
                s4Detected: .random(in: 0.20...0.50),
                murmurLikelihood: .random(in: 0.65...0.90)
            )
        }
    }
}
