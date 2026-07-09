import AVFoundation
import SwiftUI
import Combine

/// Drives the 30-second PPG heart-rate measurement: turns on the rear camera
/// torch, samples the green-channel intensity of each frame (the PPG signal),
/// and runs a lightweight detrend + peak-detection pipeline to estimate BPM.
///
/// On the simulator (no camera device available) it falls back to a synthetic
/// ~72bpm signal fed through the exact same processing pipeline, so the full
/// recording → analysis → result flow can still be exercised and screenshotted.
/// Live guidance state shown to the user while they position their finger.
enum PPGSignalQuality {
    case searching   // no finger detected on the lens yet
    case weak        // finger present, but the pulse isn't clean enough
    case good        // clean pulse detected — safe to hold and measure
}

final class PPGCameraManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var waveform: [Double] = []
    @Published var isRunning = false
    @Published var secondsRemaining: Int = 30
    @Published var cameraAvailable = true
    /// Live signal-quality feedback used before the timed measurement begins.
    @Published var signalQuality: PPGSignalQuality = .searching
    /// True once a good signal has locked and the 30-second countdown is running.
    @Published var isMeasuring = false
    /// True when measuring is temporarily paused because the finger slipped off.
    @Published var isPaused = false

    /// Called once when the 30-second window completes. `bpm` is nil if a clear signal couldn't be extracted.
    var onFinished: ((_ bpm: Int?, _ hrvMs: Double?) -> Void)?

    private let duration: Double = 30
    /// How long a good signal must persist before we lock and start measuring.
    private let lockConfirmSeconds: Double = 1.2
    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.stethoai.ppg.session")
    private var samples: [(t: Double, green: Double, red: Double)] = []       // rolling window for waveform + quality
    private var measurementSamples: [(t: Double, green: Double, red: Double)] = [] // clean samples accumulated while measuring
    private var startTime: CFAbsoluteTime = 0
    private var goodSince: Double?          // sample-time the signal first became good
    private var lastQualityEvalT: Double = 0
    // Active-time accounting so pauses (finger off) don't count toward the 30s.
    private var isMeasuringInternal = false
    private var accumulatedActive: Double = 0
    private var activeSegmentStart: Double?
    private var displayTimer: Timer?
    private var simulatorTimer: Timer?
    private var torchTimer: Timer?
    private var exposureLockWorkItem: DispatchWorkItem?
    private var captureDevice: AVCaptureDevice?
    private var exposureLocked = false
    private var finished = false

    private func nowT() -> Double { CFAbsoluteTimeGetCurrent() - startTime }

    func start() {
        finished = false
        exposureLocked = false
        isMeasuring = false
        isMeasuringInternal = false
        isPaused = false
        signalQuality = .searching
        goodSince = nil
        lastQualityEvalT = 0
        accumulatedActive = 0
        activeSegmentStart = nil
        samples.removeAll()
        measurementSamples.removeAll()
        waveform.removeAll()
        secondsRemaining = Int(duration)
        startTime = CFAbsoluteTimeGetCurrent()

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            cameraAvailable = false
            beginTiming()
            startSimulatorFallback()
            return
        }

        sessionQueue.async { [weak self] in
            self?.configureSession(device: device)
        }
    }

    func cancel() {
        finished = true
        displayTimer?.invalidate()
        simulatorTimer?.invalidate()
        torchTimer?.invalidate()
        exposureLockWorkItem?.cancel()
        stopSessionAndTorch()
        isRunning = false
    }

    private func configureSession(device: AVCaptureDevice) {
        session.beginConfiguration()
        session.sessionPreset = .low

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) { session.addInput(input) }

            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
            output.alwaysDiscardsLateVideoFrames = true
            output.setSampleBufferDelegate(self, queue: sessionQueue)
            if session.canAddOutput(output) { session.addOutput(output) }

            // Pin the capture frame rate to ~30fps so sample spacing is uniform,
            // which keeps the frequency analysis accurate.
            if let format = device.activeFormat.videoSupportedFrameRateRanges.first {
                let target = min(30.0, format.maxFrameRate)
                try? device.lockForConfiguration()
                device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: Int32(target))
                device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: Int32(target))
                device.unlockForConfiguration()
            }

            session.commitConfiguration()

            // Start the session FIRST — starting a session resets the torch, so the
            // torch must be enabled only after the session is running, otherwise it
            // flicks on during configuration and immediately turns back off.
            session.startRunning()

            self.captureDevice = device
            enableTorch(on: device)

            DispatchQueue.main.async { [weak self] in
                self?.beginTiming()
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.cameraAvailable = false
                self?.beginTiming()
                self?.startSimulatorFallback()
            }
        }
    }

    private func beginTiming() {
        isRunning = true
        // Reset the clock now that the camera is actually live — configuring and
        // starting the session can take a second or two, which shouldn't eat into
        // the 30-second measurement window.
        startTime = CFAbsoluteTimeGetCurrent()
        secondsRemaining = Int(duration)
        displayTimer?.invalidate()
        displayTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        // iOS occasionally drops the torch when exposure re-adjusts; re-assert it
        // periodically so the fingertip stays illuminated for the whole reading.
        if cameraAvailable {
            torchTimer?.invalidate()
            torchTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self, let device = self.captureDevice else { return }
                self.sessionQueue.async { self.enableTorch(on: device) }
            }

            // Let auto-exposure/white-balance settle on the bright fingertip image
            // for ~1.5s, THEN lock them. This is critical: with continuous
            // auto-exposure the camera's gain control cancels out the tiny
            // brightness pulses from blood flow — the exact PPG signal we need.
            let work = DispatchWorkItem { [weak self] in
                guard let self, let device = self.captureDevice else { return }
                self.sessionQueue.async { self.lockExposureAndWhiteBalance(on: device) }
            }
            exposureLockWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: work)
        }
    }

    /// Turns the torch on at a stable level. Must be called only while the session
    /// is running. Runs on the session queue. Deliberately does NOT touch exposure
    /// so it can be called repeatedly by the keep-alive without unlocking exposure.
    private func enableTorch(on device: AVCaptureDevice) {
        guard device.hasTorch, device.isTorchAvailable else { return }
        do {
            try device.lockForConfiguration()
            if device.torchMode != .on {
                // A moderate level is more thermally stable than full 1.0, which can
                // trigger an overload shutoff on some devices.
                try? device.setTorchModeOn(level: 0.8)
            }
            device.unlockForConfiguration()
        } catch {
            // If the torch can't be locked this tick, the keep-alive timer retries next second.
        }
    }

    /// Locks exposure and white balance so the sensor stops compensating for the
    /// pulsatile brightness changes we're trying to measure. Runs on the session queue.
    private func lockExposureAndWhiteBalance(on device: AVCaptureDevice) {
        guard !finished else { return }
        do {
            try device.lockForConfiguration()
            if device.isExposureModeSupported(.locked) {
                device.exposureMode = .locked
            }
            if device.isWhiteBalanceModeSupported(.locked) {
                device.whiteBalanceMode = .locked
            }
            device.unlockForConfiguration()
            exposureLocked = true
        } catch {
            // If locking fails, we still get a (noisier) signal from auto-exposure.
        }
    }

    private func tick() {
        // The countdown only runs once we've locked a good signal and started measuring.
        guard isMeasuringInternal else {
            secondsRemaining = Int(duration)
            return
        }
        // Paused segments (finger off) don't count toward the 30s of active measurement.
        var elapsed = accumulatedActive
        if !isPaused, let segStart = activeSegmentStart {
            elapsed += nowT() - segStart
        }
        secondsRemaining = max(0, Int(duration) - Int(elapsed))
        if elapsed >= duration {
            finish()
        }
    }

    private func startSimulatorFallback() {
        // No real finger/pulse to lock onto, so bypass the quality gate and measure
        // immediately with a synthetic ~72bpm signal.
        signalQuality = .good
        isMeasuring = true
        isMeasuringInternal = true
        activeSegmentStart = 0
        let simulatedBPM = 72.0
        let freq = simulatedBPM / 60.0
        simulatorTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            let t = CFAbsoluteTimeGetCurrent() - self.startTime
            let value = sin(2 * .pi * freq * t) * 6 + Double.random(in: -0.6...0.6) + 100
            self.appendSample(t: t, green: value, red: value)
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return }
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)

        var greenTotal: Double = 0
        var redTotal: Double = 0
        var count: Double = 0
        let xStride = 6
        let yStride = 6
        var y = 0
        while y < height {
            let rowStart = y * bytesPerRow
            var x = 0
            while x < width {
                let pixelIndex = rowStart + x * 4 // BGRA
                greenTotal += Double(buffer[pixelIndex + 1]) // green channel
                redTotal += Double(buffer[pixelIndex + 2]) // red channel
                count += 1
                x += xStride
            }
            y += yStride
        }
        guard count > 0 else { return }
        let avgGreen = greenTotal / count
        let avgRed = redTotal / count
        let t = CFAbsoluteTimeGetCurrent() - startTime

        DispatchQueue.main.async { [weak self] in
            self?.appendSample(t: t, green: avgGreen, red: avgRed)
        }
    }

    private func appendSample(t: Double, green: Double, red: Double) {
        guard !finished else { return }
        samples.append((t, green, red))
        // Keep the rolling buffer bounded (~5s) — it only feeds the waveform and the
        // live quality window; the final computation uses measurementSamples.
        if samples.count > 160 { samples.removeFirst(samples.count - 160) }

        // Only the clean, actively-measured samples feed the final BPM.
        if isMeasuringInternal && !isPaused {
            measurementSamples.append((t, green, red))
        }

        // Visualize the red channel (strongest pulsatile signal through a fingertip).
        let recent = samples.suffix(60).map { $0.red }
        if let minV = recent.min(), let maxV = recent.max(), maxV > minV {
            waveform = recent.map { ($0 - minV) / (maxV - minV) }
        } else {
            waveform = recent.map { _ in 0.5 }
        }

        updateSignalQuality(currentT: t)
    }

    /// Evaluates the last few seconds of signal and drives the state machine:
    /// before measuring it locks once a good pulse holds; during measuring it
    /// pauses when the finger slips off and resumes when it returns.
    private func updateSignalQuality(currentT: Double) {
        // The simulator path has no real finger to assess; it stays "good" and never pauses.
        guard cameraAvailable else { return }
        // Throttle the (relatively heavy) analysis to a few times per second.
        guard currentT - lastQualityEvalT >= 0.25 else { return }
        lastQualityEvalT = currentT

        let windowStart = currentT - 4.0
        let window = samples.filter { $0.t >= windowStart }
        guard window.count >= 30 else { if !isMeasuringInternal { signalQuality = .searching }; return }

        let span = window.last!.t - window.first!.t
        guard span > 1.5 else { return }
        let fs = Double(window.count - 1) / span

        let quality = HeartRateSignalProcessor.assessQuality(
            red: window.map { $0.red },
            green: window.map { $0.green },
            fs: fs
        )
        signalQuality = quality

        if !isMeasuringInternal {
            // Locking phase: start measuring once a good pulse has held steadily.
            if quality == .good {
                if goodSince == nil { goodSince = currentT }
                if let since = goodSince, currentT - since >= lockConfirmSeconds {
                    beginMeasuring(at: currentT)
                }
            } else {
                goodSince = nil
            }
        } else {
            // Measuring phase: a clear finger-off (searching) pauses the countdown;
            // a returning good signal resumes it. Brief "weak" noise is tolerated.
            if quality == .searching, !isPaused {
                pauseMeasuring(at: currentT)
            } else if quality == .good, isPaused {
                resumeMeasuring(at: currentT)
            }
        }
    }

    private func beginMeasuring(at t: Double) {
        isMeasuring = true
        isMeasuringInternal = true
        isPaused = false
        accumulatedActive = 0
        activeSegmentStart = t
        measurementSamples.removeAll()
        secondsRemaining = Int(duration)
    }

    private func pauseMeasuring(at t: Double) {
        if let segStart = activeSegmentStart {
            accumulatedActive += t - segStart
        }
        activeSegmentStart = nil
        isPaused = true
    }

    private func resumeMeasuring(at t: Double) {
        activeSegmentStart = t
        isPaused = false
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        displayTimer?.invalidate()
        simulatorTimer?.invalidate()
        torchTimer?.invalidate()
        exposureLockWorkItem?.cancel()
        isRunning = false
        isMeasuring = false
        stopSessionAndTorch()

        // Demo mode returns believable values so marketing screenshots look real.
        if AppSettings.shared.isDemoMode {
            onFinished?(Int.random(in: 66...80), Double.random(in: 40...56))
            return
        }

        // Prefer the accumulated clean measurement samples; fall back to the rolling
        // buffer for the simulator path (which streams straight into samples).
        let source = measurementSamples.count > 60 ? measurementSamples : samples
        let result = HeartRateSignalProcessor.computeBPM(from: source)
        onFinished?(result?.bpm, result?.hrvMs)
    }

    private func stopSessionAndTorch() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if let device = self.captureDevice ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
               device.hasTorch {
                try? device.lockForConfiguration()
                device.torchMode = .off
                device.unlockForConfiguration()
            }
            if self.session.isRunning { self.session.stopRunning() }
        }
    }
}

/// Extracts heart rate from raw PPG samples. Uses autocorrelation to find the
/// dominant beat period — far more robust than counting individual peaks, which
/// tends to miss weak beats and report half the true rate. Tries both the red and
/// green channels and keeps whichever gives the cleaner (higher-correlation) signal.
/// Isolated from the capture manager so it runs identically on real camera data or
/// the simulator's synthetic signal.
enum HeartRateSignalProcessor {
    // Physiological search range.
    private static let minBPM = 40.0
    private static let maxBPM = 200.0
    // Minimum autocorrelation quality to trust a reading (0...1).
    private static let qualityThreshold = 0.35

    static func computeBPM(from samples: [(t: Double, green: Double, red: Double)]) -> (bpm: Int, hrvMs: Double?)? {
        guard samples.count > 60 else { return nil }

        // Drop the first ~2s: exposure/white-balance lock settles around 1.5s and the
        // transient before that swamps the pulse signal.
        let settled = samples.filter { $0.t >= 2.0 }
        let working = settled.count > 60 ? settled : samples
        let times = working.map { $0.t }

        // Estimate the sample rate from the MEDIAN frame interval rather than the
        // total span, so a pause gap (finger briefly off) doesn't skew fs downward.
        var deltas: [Double] = []
        for i in 1..<times.count {
            let d = times[i] - times[i - 1]
            if d > 0 && d < 0.4 { deltas.append(d) } // ignore pause gaps
        }
        guard deltas.count > 30 else { return nil }
        deltas.sort()
        let medianDt = deltas[deltas.count / 2]
        guard medianDt > 0 else { return nil }
        let fs = 1.0 / medianDt
        guard fs > 5 else { return nil }

        let red = analyzeChannel(values: working.map { $0.red }, fs: fs)
        let green = analyzeChannel(values: working.map { $0.green }, fs: fs)

        // Prefer whichever channel produced the higher-confidence result.
        let best: (bpm: Int, quality: Double, hrvMs: Double?)?
        switch (red, green) {
        case let (r?, g?): best = r.quality >= g.quality ? r : g
        case let (r?, nil): best = r
        case let (nil, g?): best = g
        default: best = nil
        }

        guard let best, best.quality >= qualityThreshold else { return nil }
        return (best.bpm, best.hrvMs)
    }

    /// Live quality gate used before measurement starts. Returns `.searching` when
    /// no finger covers the lens, `.weak` when the pulse is too noisy, `.good` when
    /// a clean periodic signal is locked.
    static func assessQuality(red: [Double], green: [Double], fs: Double) -> PPGSignalQuality {
        guard !red.isEmpty, !green.isEmpty else { return .searching }
        let redMean = red.reduce(0, +) / Double(red.count)
        let greenMean = green.reduce(0, +) / Double(green.count)

        // A fingertip over the torch makes the red channel bright and dominant; an
        // uncovered lens does not. This reliably distinguishes "no finger" from a
        // present-but-noisy contact.
        let fingerPresent = redMean > 55 && redMean > greenMean * 1.4
        guard fingerPresent else { return .searching }

        let qRed = bestAutocorrelation(detrendZeroMean(red, fs: fs), fs: fs)?.corr ?? 0
        let qGreen = bestAutocorrelation(detrendZeroMean(green, fs: fs), fs: fs)?.corr ?? 0
        let quality = max(qRed, qGreen)

        if quality >= 0.55 { return .good }
        return .weak
    }

    private static func analyzeChannel(values rawValues: [Double], fs: Double) -> (bpm: Int, quality: Double, hrvMs: Double?)? {
        guard rawValues.count > 60 else { return nil }
        let x = detrendZeroMean(rawValues, fs: fs)
        guard let best = bestAutocorrelation(x, fs: fs), best.corr > 0 else { return nil }

        let minLag = max(1, Int((60.0 / maxBPM) * fs))
        let maxLag = min(x.count - 1, Int((60.0 / minBPM) * fs))

        // Parabolic interpolation around the best lag for sub-sample precision.
        let refinedLag = interpolatedLag(x: x, n: x.count, bestLag: best.lag, minLag: minLag, maxLag: maxLag)
        let period = refinedLag / fs
        let bpm = Int((60.0 / period).rounded())
        guard bpm >= Int(minBPM), bpm <= Int(maxBPM) else { return nil }

        let hrv = estimateHRV(signal: x, fs: fs, expectedPeriod: period)
        return (bpm, best.corr, hrv)
    }

    /// High-pass via a ~0.75s centered moving average, then zero-mean.
    private static func detrendZeroMean(_ values: [Double], fs: Double) -> [Double] {
        let n = values.count
        guard n > 0 else { return [] }
        let window = max(3, Int(fs * 0.75))
        var detrended = [Double](repeating: 0, count: n)
        for i in 0..<n {
            let lo = max(0, i - window)
            let hi = min(n - 1, i + window)
            var s = 0.0
            for j in lo...hi { s += values[j] }
            let avg = s / Double(hi - lo + 1)
            detrended[i] = values[i] - avg
        }
        let mean = detrended.reduce(0, +) / Double(n)
        return detrended.map { $0 - mean }
    }

    /// Normalized autocorrelation search over the physiological lag range.
    private static func bestAutocorrelation(_ x: [Double], fs: Double) -> (lag: Int, corr: Double)? {
        let n = x.count
        guard n > 30 else { return nil }
        let energy = x.reduce(0) { $0 + $1 * $1 }
        guard energy > 0 else { return nil }

        let minLag = max(1, Int((60.0 / maxBPM) * fs))
        let maxLag = min(n - 1, Int((60.0 / minBPM) * fs))
        guard maxLag > minLag else { return nil }

        var bestLag = minLag
        var bestCorr = -1.0
        for lag in minLag...maxLag {
            var num = 0.0, normA = 0.0, normB = 0.0, i = 0
            while i + lag < n {
                let a = x[i], b = x[i + lag]
                num += a * b
                normA += a * a
                normB += b * b
                i += 1
            }
            let denom = (normA * normB).squareRoot()
            guard denom > 0 else { continue }
            let corr = num / denom
            if corr > bestCorr {
                bestCorr = corr
                bestLag = lag
            }
        }
        return bestCorr > 0 ? (bestLag, bestCorr) : nil
    }

    private static func interpolatedLag(x: [Double], n: Int, bestLag: Int, minLag: Int, maxLag: Int) -> Double {
        guard bestLag > minLag, bestLag < maxLag else { return Double(bestLag) }
        func corr(_ lag: Int) -> Double {
            var num = 0.0, normA = 0.0, normB = 0.0, i = 0
            while i + lag < n {
                num += x[i] * x[i + lag]
                normA += x[i] * x[i]
                normB += x[i + lag] * x[i + lag]
                i += 1
            }
            let denom = (normA * normB).squareRoot()
            return denom > 0 ? num / denom : 0
        }
        let c0 = corr(bestLag - 1)
        let c1 = corr(bestLag)
        let c2 = corr(bestLag + 1)
        let denom = (c0 - 2 * c1 + c2)
        guard abs(denom) > 1e-9 else { return Double(bestLag) }
        let offset = 0.5 * (c0 - c2) / denom
        return Double(bestLag) + max(-1, min(1, offset))
    }

    /// SDNN from peak-to-peak intervals, using the autocorrelation period to set a
    /// sensible minimum spacing so we don't double-count.
    private static func estimateHRV(signal: [Double], fs: Double, expectedPeriod: Double) -> Double? {
        let stdDev = (signal.reduce(0) { $0 + $1 * $1 } / Double(signal.count)).squareRoot()
        guard stdDev > 0 else { return nil }
        let threshold = stdDev * 0.2
        let minDistance = expectedPeriod * 0.6

        var peakTimes: [Double] = []
        var lastPeak = -Double.infinity
        for i in 1..<(signal.count - 1) {
            if signal[i] > threshold, signal[i] > signal[i - 1], signal[i] >= signal[i + 1] {
                let t = Double(i) / fs
                if t - lastPeak >= minDistance {
                    peakTimes.append(t)
                    lastPeak = t
                }
            }
        }

        guard peakTimes.count >= 6 else { return nil }
        var intervalsMs: [Double] = []
        for i in 1..<peakTimes.count {
            intervalsMs.append((peakTimes[i] - peakTimes[i - 1]) * 1000)
        }
        let meanMs = intervalsMs.reduce(0, +) / Double(intervalsMs.count)
        let varMs = intervalsMs.reduce(0) { $0 + ($1 - meanMs) * ($1 - meanMs) } / Double(intervalsMs.count)
        let sdnn = varMs.squareRoot()
        // Only report physiologically plausible HRV; noisy reads produce absurd values.
        return (8...180).contains(sdnn) ? sdnn : nil
    }
}
