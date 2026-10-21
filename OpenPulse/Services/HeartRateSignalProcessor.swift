import Foundation

/// Extracts heart rate from raw PPG samples.
///
/// Designed and checked against real recordings from an iPhone 15:
/// 1. Remove duplicate frames, resample evenly at 30 fps.
/// 2. Band-pass filter to the heart-rate band (0.7–3.5 Hz, i.e. 42–210 bpm) with a
///    zero-phase Butterworth-style filter, so slow pressure drift and fast noise drop out.
/// 3. Estimate the rate two independent ways — the strongest frequency in the
///    spectrum, and the median time between detected beats — and only report a
///    reading when they agree within 4 bpm. If they don't, the signal isn't clean
///    enough to trust, and it's better to say so than to show a wrong number.
/// The red channel carries the cleanest pulse through a fingertip; green is only a
/// fallback with a stricter bar.
enum HeartRateSignalProcessor {
    static let sampleRate = 30.0
    private static let minBPM = 40.0
    private static let maxBPM = 180.0
    /// The two estimates must agree within this many bpm.
    private static let maxDisagreement = 4.0
    /// Spectral peak-to-median power needed for a final reading.
    private static let minSNRRed = 15.0
    private static let minSNRGreen = 40.0
    /// Live (6-second window) strength that counts as a clear pulse.
    static let liveGoodSNR = 10.0

    struct Analysis {
        let spectralBPM: Double
        let snr: Double
        let beatBPM: Double?
        let beatIntervals: [Double]   // seconds
    }

    /// Final reading from a full measurement. Uses up to the most recent 30 s.
    static func computeBPM(from samples: [(t: Double, green: Double, red: Double)]) -> (bpm: Int, hrvMs: Double?)? {
        var clean = dedupe(samples)
        guard let lastT = clean.last?.t else { return nil }
        clean = clean.filter { $0.t >= lastT - 30 }
        guard clean.count > Int(sampleRate * 10) else { return nil }

        let t = clean.map(\.t)
        if let r = reading(t: t, x: clean.map(\.red), minSNR: minSNRRed) { return r }
        return reading(t: t, x: clean.map(\.green), minSNR: minSNRGreen)
    }

    /// Live strength of the pulse in a short window, for on-screen feedback.
    static func liveSNR(t: [Double], red: [Double]) -> Double {
        analyze(t: t, x: red, needBeats: false)?.snr ?? 0
    }

    // MARK: - Pipeline

    private static func reading(t: [Double], x: [Double], minSNR: Double) -> (bpm: Int, hrvMs: Double?)? {
        guard let a = analyze(t: t, x: x, needBeats: true),
              a.snr >= minSNR,
              let beat = a.beatBPM,
              abs(beat - a.spectralBPM) <= maxDisagreement else { return nil }
        let bpm = Int(((a.spectralBPM + beat) / 2).rounded())
        return (bpm, sdnn(a.beatIntervals))
    }

    private static func analyze(t: [Double], x: [Double], needBeats: Bool) -> Analysis? {
        guard t.count == x.count, t.count > 30, let t0 = t.first, let t1 = t.last, t1 - t0 > 3 else { return nil }
        let uniform = resample(t: t, x: x, from: t0, to: t1)
        var y = bandPass(uniform)
        // Trim 1 s from each end, where the filter is still settling.
        let edge = Int(sampleRate)
        if y.count > edge * 4 { y = Array(y[edge..<(y.count - edge)]) }
        guard y.count > 60 else { return nil }

        let (spectral, snr) = dominantFrequency(y)
        guard needBeats else { return Analysis(spectralBPM: spectral, snr: snr, beatBPM: nil, beatIntervals: []) }

        let intervals = beatIntervals(y, expectedBPM: spectral)
        var beat: Double?
        if intervals.count >= 5 {
            let sorted = intervals.sorted()
            beat = 60 / sorted[sorted.count / 2]
        }
        return Analysis(spectralBPM: spectral, snr: snr, beatBPM: beat, beatIntervals: intervals)
    }

    /// Drops frames that arrive within 5 ms of the previous one (duplicates).
    private static func dedupe(_ samples: [(t: Double, green: Double, red: Double)]) -> [(t: Double, green: Double, red: Double)] {
        var out: [(t: Double, green: Double, red: Double)] = []
        out.reserveCapacity(samples.count)
        for s in samples where out.last.map({ s.t - $0.t > 0.005 }) ?? true {
            out.append(s)
        }
        return out
    }

    private static func resample(t: [Double], x: [Double], from t0: Double, to t1: Double) -> [Double] {
        let n = Int((t1 - t0) * sampleRate)
        var out = [Double](repeating: 0, count: max(0, n))
        var j = 0
        for i in 0..<out.count {
            let ti = t0 + Double(i) / sampleRate
            while j < t.count - 2 && t[j + 1] < ti { j += 1 }
            let span = t[j + 1] - t[j]
            let w = span > 0 ? min(1, max(0, (ti - t[j]) / span)) : 0
            out[i] = x[j] + (x[j + 1] - x[j]) * w
        }
        return out
    }

    /// Two high-pass (0.7 Hz) and two low-pass (3.5 Hz) biquads, each run forward
    /// and backward so the filter adds no delay.
    private static func bandPass(_ input: [Double]) -> [Double] {
        guard !input.isEmpty else { return [] }
        let mean = input.reduce(0, +) / Double(input.count)
        var y = input.map { $0 - mean }
        for (lowPass, f0) in [(false, 0.7), (false, 0.7), (true, 3.5), (true, 3.5)] {
            let c = biquad(lowPass: lowPass, f0: f0)
            y = runFilter(y, c)
            y = Array(runFilter(Array(y.reversed()), c).reversed())
        }
        return y
    }

    private static func biquad(lowPass: Bool, f0: Double) -> [Double] {
        let w = 2 * Double.pi * f0 / sampleRate
        let cosw = cos(w), alpha = sin(w) / (2 * 0.7071)
        let b: [Double] = lowPass
            ? [(1 - cosw) / 2, 1 - cosw, (1 - cosw) / 2]
            : [(1 + cosw) / 2, -(1 + cosw), (1 + cosw) / 2]
        let a0 = 1 + alpha
        return [b[0] / a0, b[1] / a0, b[2] / a0, (-2 * cosw) / a0, (1 - alpha) / a0]
    }

    private static func runFilter(_ x: [Double], _ c: [Double]) -> [Double] {
        var y = [Double](repeating: 0, count: x.count)
        var x1 = 0.0, x2 = 0.0, y1 = 0.0, y2 = 0.0
        for i in 0..<x.count {
            let out = c[0] * x[i] + c[1] * x1 + c[2] * x2 - c[3] * y1 - c[4] * y2
            x2 = x1; x1 = x[i]; y2 = y1; y1 = out
            y[i] = out
        }
        return y
    }

    /// Strongest frequency between 40 and 180 bpm (0.5 bpm steps, Hann window),
    /// and how far it stands above the typical level (peak / median power).
    private static func dominantFrequency(_ y: [Double]) -> (bpm: Double, snr: Double) {
        let n = y.count
        let windowed: [Double] = (0..<n).map { i in
            y[i] * (0.5 - 0.5 * cos(2 * Double.pi * Double(i) / Double(n - 1)))
        }
        var powers: [Double] = []
        var bestBPM = minBPM, bestPower = -1.0
        var bpm = minBPM
        while bpm <= maxBPM {
            let w = 2 * Double.pi * (bpm / 60) / sampleRate
            var re = 0.0, im = 0.0
            for i in 0..<n {
                re += windowed[i] * cos(w * Double(i))
                im -= windowed[i] * sin(w * Double(i))
            }
            let p = re * re + im * im
            powers.append(p)
            if p > bestPower { bestPower = p; bestBPM = bpm }
            bpm += 0.5
        }
        let sorted = powers.sorted()
        let median = sorted[sorted.count / 2]
        return (bestBPM, median > 0 ? bestPower / median : 0)
    }

    /// Times between detected beats (local maxima at least 60% of a period apart).
    private static func beatIntervals(_ y: [Double], expectedBPM: Double) -> [Double] {
        let minGap = Int((60 / expectedBPM) * 0.6 * sampleRate)
        var peaks: [Int] = []
        for i in 1..<(y.count - 1) where y[i] > 0 && y[i] > y[i - 1] && y[i] >= y[i + 1] {
            if let last = peaks.last, i - last < minGap { continue }
            peaks.append(i)
        }
        guard peaks.count > 1 else { return [] }
        return zip(peaks, peaks.dropFirst())
            .map { Double($1 - $0) / sampleRate }
            .filter { $0 > 60 / maxBPM && $0 < 60 / minBPM }
    }

    /// SDNN in ms; only physiologically plausible values are reported. Intervals
    /// more than 20% off the median are dropped first — they're almost always a
    /// missed or doubled beat, which would wildly inflate variability.
    private static func sdnn(_ intervals: [Double]) -> Double? {
        let sorted = intervals.sorted()
        guard !sorted.isEmpty else { return nil }
        let median = sorted[sorted.count / 2]
        let kept = intervals.filter { abs($0 - median) <= median * 0.2 }
        guard kept.count >= 6 else { return nil }
        let ms = kept.map { $0 * 1000 }
        let mean = ms.reduce(0, +) / Double(ms.count)
        let sd = (ms.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(ms.count)).squareRoot()
        return (8...180).contains(sd) ? sd : nil
    }
}
