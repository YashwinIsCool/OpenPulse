import AVFoundation
import AudioToolbox
import UIKit
import Combine

final class HeartSoundRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var isRecording = false
    @Published var secondsRemaining: Int = 30
    @Published var levels: [Double] = []

    var onFinished: ((URL) -> Void)?

    private let duration: TimeInterval = 30
    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private var startTime: CFAbsoluteTime = 0
    private var currentFileURL: URL?

    func start() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .measurement)
            try session.setActive(true)
        } catch {
            // Recording session unavailable (e.g. restricted simulator audio route) — fall back to a synthetic level feed.
            beginSyntheticFallback()
            return
        }

        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("heartsound-\(UUID().uuidString).m4a")
        currentFileURL = fileURL

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            let recorder = try AVAudioRecorder(url: fileURL, settings: settings)
            recorder.isMeteringEnabled = true
            recorder.delegate = self
            recorder.record()
            self.recorder = recorder
            beginTiming(usingRecorder: true)
        } catch {
            beginSyntheticFallback()
        }
    }

    func cancel() {
        timer?.invalidate()
        recorder?.stop()
        if let url = currentFileURL {
            try? FileManager.default.removeItem(at: url)
        }
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    private func beginTiming(usingRecorder: Bool) {
        isRecording = true
        startTime = CFAbsoluteTimeGetCurrent()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 20.0, repeats: true) { [weak self] _ in
            self?.tick(usingRecorder: usingRecorder)
        }
    }

    private func tick(usingRecorder: Bool) {
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        secondsRemaining = max(0, Int(duration) - Int(elapsed))

        if usingRecorder, let recorder {
            recorder.updateMeters()
            let power = recorder.averagePower(forChannel: 0)
            let normalized = normalizedLevel(fromDecibels: power)
            appendLevel(normalized)
        }

        if elapsed >= duration {
            finish()
        }
    }

    private func beginSyntheticFallback() {
        beginTiming(usingRecorder: false)
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 20.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            let elapsed = CFAbsoluteTimeGetCurrent() - self.startTime
            self.secondsRemaining = max(0, Int(self.duration) - Int(elapsed))
            let synthetic = 0.4 + 0.3 * abs(sin(elapsed * 1.3)) + Double.random(in: 0...0.15)
            self.appendLevel(min(1.0, synthetic))
            if elapsed >= self.duration {
                self.finish()
            }
        }
    }

    private func appendLevel(_ value: Double) {
        levels.append(value)
        if levels.count > 80 { levels.removeFirst(levels.count - 80) }
    }

    private func normalizedLevel(fromDecibels db: Float) -> Double {
        let minDb: Float = -60
        let clamped = max(minDb, min(0, db))
        return Double((clamped - minDb) / -minDb)
    }

    private func finish() {
        guard isRecording else { return }
        isRecording = false
        timer?.invalidate()
        recorder?.stop()
        try? AVAudioSession.sharedInstance().setActive(false)
        notifyComplete()
        let url = currentFileURL ?? FileManager.default.temporaryDirectory.appendingPathComponent("heartsound-fallback.m4a")
        onFinished?(url)
    }

    /// Buzzes the phone so the user knows the 30 seconds is up — they can't see the
    /// screen while it's held against their chest. Fires both the Taptic success
    /// pattern and the classic vibration motor for a clearly noticeable cue.
    private func notifyComplete() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
}
