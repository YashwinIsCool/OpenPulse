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
    /// True after the first 30 s if the signal wasn't clean enough yet — the reading
    /// keeps going (up to `maxDuration`) instead of failing straight away.
    @Published var isExtending = false
    /// The finger is pressing hard enough to wash out the pulse (red channel near max).
    @Published var pressingTooHard = false
    /// Average color the camera sees right now (0–1), shown as a live swatch so people
    /// can tell when their fingertip covers the lens and flash properly.
    @Published var liveColor: (red: Double, green: Double, blue: Double) = (0, 0, 0)

    /// Called once when the 30-second window completes. `bpm` is nil if a clear signal couldn't be extracted.
    var onFinished: ((_ bpm: Int?, _ hrvMs: Double?) -> Void)?

    private let duration: Double = 30
    /// Longest a reading may run while waiting for a clean enough signal.
    private let maxDuration: Double = 60
    /// How long the finger must stay in place (with exposure locked) before measuring starts.
    private let lockConfirmSeconds: Double = 1.5
    private var lastExtendAttemptT: Double = 0
    private var fingerSince: Double?
    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.stethoai.ppg.session")
    private var samples: [(t: Double, green: Double, red: Double)] = []       // rolling window for waveform + quality
    private var measurementSamples: [(t: Double, green: Double, red: Double)] = [] // clean samples accumulated while measuring
    #if DEBUG
    /// Every frame of a session, kept only in debug builds so real readings can be
    /// pulled off a test phone and analyzed (see PPGDebugLog).
    private var debugLog: [String] = []
    #endif
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
        fingerSince = nil
        lastExtendAttemptT = 0
        isExtending = false
        pressingTooHard = false
        lastQualityEvalT = 0
        accumulatedActive = 0
        activeSegmentStart = nil
        samples.removeAll()
        measurementSamples.removeAll()
        #if DEBUG
        debugLog.removeAll()
        #endif
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
        // A retry reuses this session. Without clearing it, every retry stacked
        // another input/output, so each frame arrived 2-3x and readings came out wrong.
        for input in session.inputs { session.removeInput(input) }
        for output in session.outputs { session.removeOutput(output) }
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
            // A retry may still hold the previous attempt's exposure lock; start
            // from automatic exposure so it can adjust to the new fingertip.
            unlockExposure(on: device)
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

            // Exposure is locked once a fingertip is actually on the lens (see
            // updateSignalQuality) — locking on an uncovered lens left the camera
            // tuned for the wrong scene and gave a dim or washed-out pulse.
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
            DispatchQueue.main.async { [weak self] in self?.exposureLocked = true }
        } catch {
            // If locking fails, we still get a (noisier) signal from auto-exposure.
        }
    }

    /// Back to automatic exposure when the finger comes off before measuring, so the
    /// next placement gets a fresh lock tuned to the fingertip.
    private func unlockExposure(on device: AVCaptureDevice) {
        do {
            try device.lockForConfiguration()
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                device.whiteBalanceMode = .continuousAutoWhiteBalance
            }
            device.unlockForConfiguration()
        } catch {}
    }

    private func tick() {
        // The countdown only runs once a finger is in place and measuring has started.
        guard isMeasuringInternal, !finished else {
            if !isMeasuringInternal { secondsRemaining = Int(duration) }
            return
        }
        // Paused segments (finger off) don't count toward active measurement time.
        var elapsed = accumulatedActive
        if !isPaused, let segStart = activeSegmentStart {
            elapsed += nowT() - segStart
        }

        if elapsed < duration {
            secondsRemaining = max(0, Int(ceil(duration - elapsed)))
            return
        }

        // 30 s reached: report as soon as the most recent stretch is clean enough.
        // If it isn't yet, keep measuring (up to maxDuration) rather than failing —
        // a few more seconds of steady signal usually gets there.
        secondsRemaining = 0
        guard elapsed - lastExtendAttemptT >= 2 || lastExtendAttemptT == 0 else { return }
        lastExtendAttemptT = elapsed
        let source = measurementSamples.count > 60 ? measurementSamples : samples
        if let result = HeartRateSignalProcessor.computeBPM(from: source) {
            finish(with: result)
        } else if elapsed >= maxDuration {
            finish(with: nil)
        } else {
            isExtending = true
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

        var blueTotal: Double = 0
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
                blueTotal += Double(buffer[pixelIndex])
                greenTotal += Double(buffer[pixelIndex + 1])
                redTotal += Double(buffer[pixelIndex + 2])
                count += 1
                x += xStride
            }
            y += yStride
        }
        guard count > 0 else { return }
        let avgBlue = blueTotal / count
        let avgGreen = greenTotal / count
        let avgRed = redTotal / count
        let t = CFAbsoluteTimeGetCurrent() - startTime

        DispatchQueue.main.async { [weak self] in
            self?.appendSample(t: t, green: avgGreen, red: avgRed, blue: avgBlue)
        }
    }

    private func appendSample(t: Double, green: Double, red: Double, blue: Double? = nil) {
        guard !finished else { return }
        #if DEBUG
        debugLog.append(String(format: "%.4f,%.3f,%.3f,%d,%d,%@", t, red, green,
                               isMeasuringInternal ? 1 : 0, isPaused ? 1 : 0, "\(signalQuality)"))
        #endif
        samples.append((t, green, red))
        // Rolling ~7 s buffer for the waveform and the live quality window; the final
        // computation uses measurementSamples.
        if samples.count > 210 { samples.removeFirst(samples.count - 210) }

        // Only actively-measured samples (finger on) feed the final BPM.
        if isMeasuringInternal && !isPaused {
            measurementSamples.append((t, green, red))
        }

        liveColor = (red / 255, green / 255, (blue ?? green) / 255)

        // Visualize the red channel (strongest pulsatile signal through a fingertip).
        let recent = samples.suffix(60).map { $0.red }
        if let minV = recent.min(), let maxV = recent.max(), maxV > minV {
            waveform = recent.map { ($0 - minV) / (maxV - minV) }
        } else {
            waveform = recent.map { _ in 0.5 }
        }

        updateSignalQuality(currentT: t)
    }

    /// Drives the state machine from the last few seconds of signal:
    /// - no fingertip → "searching" (and pauses an active measurement)
    /// - fingertip on → lock exposure, then start measuring after it holds briefly
    /// - pulse strength (same measure the final reading uses) → "weak" or "good"
    private func updateSignalQuality(currentT: Double) {
        // The simulator path has no real finger to assess; it stays "good" and never pauses.
        guard cameraAvailable else { return }
        // Throttle the analysis to a few times per second.
        guard currentT - lastQualityEvalT >= 0.25 else { return }
        lastQualityEvalT = currentT

        let recent = samples.filter { $0.t >= currentT - 1.0 }
        guard recent.count >= 10 else { return }
        let redMean = recent.map(\.red).reduce(0, +) / Double(recent.count)
        let greenMean = recent.map(\.green).reduce(0, +) / Double(recent.count)

        // A fingertip over the lit torch makes the image bright and strongly red.
        let fingerPresent = redMean > 55 && redMean > greenMean * 1.4
        // Pressing hard squeezes blood out and pushes red to the sensor's ceiling,
        // flattening the pulse.
        pressingTooHard = fingerPresent && redMean > 245

        var quality: PPGSignalQuality = .searching
        if fingerPresent {
            let window = samples.filter { $0.t >= currentT - 6.0 }
            let span = (window.last?.t ?? 0) - (window.first?.t ?? 0)
            if exposureLocked && span >= 4 {
                let snr = HeartRateSignalProcessor.liveSNR(t: window.map(\.t), red: window.map(\.red))
                quality = snr >= HeartRateSignalProcessor.liveGoodSNR ? .good : .weak
            } else {
                quality = .weak
            }
        }
        signalQuality = quality

        if !isMeasuringInternal {
            if fingerPresent {
                if fingerSince == nil {
                    fingerSince = currentT
                    // Give auto-exposure a moment to settle on the fingertip, then lock.
                    exposureLockWorkItem?.cancel()
                    let work = DispatchWorkItem { [weak self] in
                        guard let self, let device = self.captureDevice else { return }
                        self.sessionQueue.async { self.lockExposureAndWhiteBalance(on: device) }
                    }
                    exposureLockWorkItem = work
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: work)
                }
                // Start once the finger has stayed put and exposure is locked. The
                // final reading decides whether the signal was clean enough.
                if exposureLocked, let since = fingerSince, currentT - since >= lockConfirmSeconds {
                    beginMeasuring(at: currentT)
                }
            } else if fingerSince != nil {
                fingerSince = nil
                exposureLockWorkItem?.cancel()
                if exposureLocked, let device = captureDevice {
                    exposureLocked = false
                    sessionQueue.async { self.unlockExposure(on: device) }
                }
            }
        } else {
            // Finger off pauses the clock; putting it back resumes.
            if !fingerPresent, !isPaused {
                pauseMeasuring(at: currentT)
            } else if fingerPresent, isPaused {
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
        lastExtendAttemptT = 0
        isExtending = false
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

    private func finish(with result: (bpm: Int, hrvMs: Double?)?) {
        guard !finished else { return }
        finished = true
        displayTimer?.invalidate()
        simulatorTimer?.invalidate()
        torchTimer?.invalidate()
        exposureLockWorkItem?.cancel()
        isRunning = false
        isMeasuring = false
        isExtending = false
        stopSessionAndTorch()

        // Demo mode returns believable values so marketing screenshots look real.
        if AppSettings.shared.isDemoMode {
            onFinished?(Int.random(in: 66...80), Double.random(in: 40...56))
            return
        }

        #if DEBUG
        PPGDebugLog.save(rows: debugLog, result: result?.bpm)
        #endif
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

#if DEBUG
/// Saves a reading's raw signal as CSV in Documents/ppg-logs so it can be copied off
/// a test phone (xcrun devicectl ... copy from) and analyzed on a Mac.
enum PPGDebugLog {
    static func save(rows: [String], result: Int?) {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let dir = docs.appendingPathComponent("ppg-logs", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let stamp = ISO8601DateFormatter().string(from: .now).replacingOccurrences(of: ":", with: "-")
        let name = "\(stamp)_result-\(result.map(String.init) ?? "none").csv"
        let csv = "t,red,green,measuring,paused,quality\n" + rows.joined(separator: "\n")
        try? csv.write(to: dir.appendingPathComponent(name), atomically: true, encoding: .utf8)
    }
}
#endif
