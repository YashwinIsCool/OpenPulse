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
final class PPGCameraManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var waveform: [Double] = []
    @Published var isRunning = false
    @Published var secondsRemaining: Int = 30
    @Published var cameraAvailable = true

    /// Called once when the 30-second window completes. `bpm` is nil if a clear signal couldn't be extracted.
    var onFinished: ((_ bpm: Int?, _ hrvMs: Double?) -> Void)?

    private let duration: Double = 30
    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.stethoai.ppg.session")
    private var samples: [(t: Double, green: Double, red: Double)] = []
    private var startTime: CFAbsoluteTime = 0
    private var displayTimer: Timer?
    private var simulatorTimer: Timer?
    private var torchTimer: Timer?
    private var exposureLockWorkItem: DispatchWorkItem?
    private var captureDevice: AVCaptureDevice?
    private var exposureLocked = false
    private var finished = false

    func start() {
        finished = false
        exposureLocked = false
        samples.removeAll()
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
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        secondsRemaining = max(0, Int(duration) - Int(elapsed))
        if elapsed >= duration {
            finish()
        }
    }

    private func startSimulatorFallback() {
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
        // Visualize the red channel (strongest pulsatile signal through a fingertip).
        let recent = samples.suffix(60).map { $0.red }
        if let minV = recent.min(), let maxV = recent.max(), maxV > minV {
            waveform = recent.map { ($0 - minV) / (maxV - minV) }
        } else {
            waveform = recent.map { _ in 0.5 }
        }
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        displayTimer?.invalidate()
        simulatorTimer?.invalidate()
        torchTimer?.invalidate()
        exposureLockWorkItem?.cancel()
        isRunning = false
        stopSessionAndTorch()

        let result = HeartRateSignalProcessor.computeBPM(from: samples)
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

        // Estimate sample rate from timestamps (frame duration is pinned to ~30fps).
        let span = times.last! - times.first!
        guard span > 5 else { return nil }
        let fs = Double(working.count - 1) / span
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

    private static func analyzeChannel(values rawValues: [Double], fs: Double) -> (bpm: Int, quality: Double, hrvMs: Double?)? {
        let n = rawValues.count
        guard n > 60 else { return nil }

        // High-pass by subtracting a ~0.75s moving average to remove baseline wander,
        // then zero-mean the result.
        let window = max(3, Int(fs * 0.75))
        var detrended = [Double](repeating: 0, count: n)
        // Centered moving-average high-pass filter.
        for i in 0..<n {
            let lo = max(0, i - window)
            let hi = min(n - 1, i + window)
            var s = 0.0
            for j in lo...hi { s += rawValues[j] }
            let avg = s / Double(hi - lo + 1)
            detrended[i] = rawValues[i] - avg
        }

        let mean = detrended.reduce(0, +) / Double(n)
        var x = detrended.map { $0 - mean }
        let energy = x.reduce(0) { $0 + $1 * $1 }
        guard energy > 0 else { return nil }

        // Autocorrelation search over lags in the physiological range.
        let minLag = max(1, Int((60.0 / maxBPM) * fs))
        let maxLag = min(n - 1, Int((60.0 / minBPM) * fs))
        guard maxLag > minLag else { return nil }

        var bestLag = minLag
        var bestCorr = -1.0
        for lag in minLag...maxLag {
            var num = 0.0
            var normA = 0.0
            var normB = 0.0
            var i = 0
            while i + lag < n {
                let a = x[i]
                let b = x[i + lag]
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

        guard bestCorr > 0 else { return nil }

        // Parabolic interpolation around the best lag for sub-sample precision.
        let refinedLag = interpolatedLag(x: x, n: n, bestLag: bestLag, minLag: minLag, maxLag: maxLag)
        let period = refinedLag / fs
        let bpm = Int((60.0 / period).rounded())
        guard bpm >= Int(minBPM), bpm <= Int(maxBPM) else { return nil }

        let hrv = estimateHRV(signal: x, fs: fs, expectedPeriod: period)
        return (bpm, bestCorr, hrv)
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
        return varMs.squareRoot()
    }
}
