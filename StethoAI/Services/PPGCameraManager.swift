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
    private var samples: [(t: Double, v: Double)] = []
    private var startTime: CFAbsoluteTime = 0
    private var displayTimer: Timer?
    private var simulatorTimer: Timer?
    private var finished = false

    func start() {
        finished = false
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

            session.commitConfiguration()

            try device.lockForConfiguration()
            if device.hasTorch {
                try? device.setTorchModeOn(level: 1.0)
            }
            if device.isExposureModeSupported(.locked) {
                device.exposureMode = .continuousAutoExposure
            }
            device.unlockForConfiguration()

            session.startRunning()
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
        displayTimer?.invalidate()
        displayTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.tick()
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
            self.appendSample(t: t, value: value)
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

        var total: Double = 0
        var count: Double = 0
        let xStride = 6
        let yStride = 6
        var y = 0
        while y < height {
            let rowStart = y * bytesPerRow
            var x = 0
            while x < width {
                let pixelIndex = rowStart + x * 4 // BGRA
                total += Double(buffer[pixelIndex + 1]) // green channel
                count += 1
                x += xStride
            }
            y += yStride
        }
        guard count > 0 else { return }
        let avgGreen = total / count
        let t = CFAbsoluteTimeGetCurrent() - startTime

        DispatchQueue.main.async { [weak self] in
            self?.appendSample(t: t, value: avgGreen)
        }
    }

    private func appendSample(t: Double, value: Double) {
        guard !finished else { return }
        samples.append((t, value))
        let recent = samples.suffix(60).map { $0.v }
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
        isRunning = false
        stopSessionAndTorch()

        let result = HeartRateSignalProcessor.computeBPM(from: samples)
        onFinished?(result?.bpm, result?.hrvMs)
    }

    private func stopSessionAndTorch() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning { self.session.stopRunning() }
            if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back), device.hasTorch {
                try? device.lockForConfiguration()
                device.torchMode = .off
                device.unlockForConfiguration()
            }
        }
    }
}

/// Bandpass-ish detrend + peak-detection over the raw PPG samples. Isolated from
/// the capture manager so it can run identically on real camera data or the
/// simulator's synthetic signal.
enum HeartRateSignalProcessor {
    static func computeBPM(from samples: [(t: Double, v: Double)]) -> (bpm: Int, hrvMs: Double?)? {
        guard samples.count > 30 else { return nil }
        let values = samples.map { $0.v }
        let times = samples.map { $0.t }

        // Detrend: subtract a local moving average to remove baseline wander (~0.5Hz high-pass).
        let windowSize = max(3, samples.count / 20)
        var detrended = [Double](repeating: 0, count: values.count)
        for i in 0..<values.count {
            let lo = max(0, i - windowSize)
            let hi = min(values.count - 1, i + windowSize)
            let slice = values[lo...hi]
            let avg = slice.reduce(0, +) / Double(slice.count)
            detrended[i] = values[i] - avg
        }

        // Light smoothing to suppress high-frequency noise above ~4Hz (240bpm equivalent).
        var smoothed = detrended
        if smoothed.count > 5 {
            for i in 2..<(smoothed.count - 2) {
                smoothed[i] = (detrended[i - 2] + detrended[i - 1] + detrended[i] + detrended[i + 1] + detrended[i + 2]) / 5
            }
        }

        let mean = smoothed.reduce(0, +) / Double(smoothed.count)
        let variance = smoothed.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(smoothed.count)
        let stdDev = variance.squareRoot()
        guard stdDev > 0 else { return nil }
        let threshold = mean + stdDev * 0.3
        let minPeakDistance = 60.0 / 220.0 // cap at 220bpm

        var peakTimes: [Double] = []
        var lastPeakTime = -Double.infinity
        for i in 1..<(smoothed.count - 1) {
            if smoothed[i] > threshold, smoothed[i] > smoothed[i - 1], smoothed[i] >= smoothed[i + 1] {
                let t = times[i]
                if t - lastPeakTime >= minPeakDistance {
                    peakTimes.append(t)
                    lastPeakTime = t
                }
            }
        }

        guard peakTimes.count >= 4 else { return nil }
        var intervals: [Double] = []
        for i in 1..<peakTimes.count {
            intervals.append(peakTimes[i] - peakTimes[i - 1])
        }
        let avgInterval = intervals.reduce(0, +) / Double(intervals.count)
        guard avgInterval > 0 else { return nil }

        let rawBPM = 60.0 / avgInterval
        let bpm = Int(rawBPM.rounded())
        guard bpm >= 35, bpm <= 220 else { return nil }

        let intervalsMs = intervals.map { $0 * 1000 }
        let meanMs = intervalsMs.reduce(0, +) / Double(intervalsMs.count)
        let varMs = intervalsMs.reduce(0) { $0 + ($1 - meanMs) * ($1 - meanMs) } / Double(intervalsMs.count)
        let sdnn = varMs.squareRoot()

        return (bpm, intervals.count >= 6 ? sdnn : nil)
    }
}
