import AVFoundation
import SwiftUI
import Combine

/// Permanent on-device storage for heart-sound recordings. The recorder writes to
/// the temporary directory (which iOS purges), so on save we copy the file here so
/// it can be played back and shared later.
enum HeartSoundStore {
    static var directory: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("HeartSounds", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// Copies a freshly-recorded temp file into permanent storage. Returns the bare
    /// filename to persist (resolved back to a URL at read time, since the app's
    /// container path can change between launches).
    static func persist(tempURL: URL) -> String? {
        let filename = tempURL.lastPathComponent
        let dest = directory.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: dest)
        do {
            try FileManager.default.copyItem(at: tempURL, to: dest)
            return filename
        } catch {
            return nil
        }
    }

    static func url(for filename: String) -> URL {
        directory.appendingPathComponent(filename)
    }
}

/// Plays a saved heart-sound recording with play/pause and progress.
final class HeartSoundPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    @Published var progress: Double = 0
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var available = true

    private var player: AVAudioPlayer?
    private var timer: Timer?

    func load(url: URL?) {
        guard let url, FileManager.default.fileExists(atPath: url.path) else {
            available = false
            return
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            let p = try AVAudioPlayer(contentsOf: url)
            p.delegate = self
            p.prepareToPlay()
            player = p
            duration = p.duration
            available = true
        } catch {
            available = false
        }
    }

    func toggle() {
        guard let player else { return }
        player.isPlaying ? pause() : play()
    }

    private func play() {
        guard let player else { return }
        player.play()
        isPlaying = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func pause() {
        player?.pause()
        isPlaying = false
        timer?.invalidate()
    }

    func stop() {
        player?.stop()
        player?.currentTime = 0
        isPlaying = false
        timer?.invalidate()
        progress = 0
        currentTime = 0
    }

    private func tick() {
        guard let player else { return }
        currentTime = player.currentTime
        duration = player.duration
        progress = duration > 0 ? currentTime / duration : 0
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        timer?.invalidate()
        progress = 0
        currentTime = 0
    }

    deinit { timer?.invalidate() }
}

/// Reusable "listen to your heartbeat" player card.
struct HeartSoundPlayerView: View {
    let url: URL?
    @StateObject private var player = HeartSoundPlayer()

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
                Text("LISTEN TO YOUR HEARTBEAT")
                    .font(Tokens.Fonts.microLabel)
                    .tracking(Tokens.Tracking.microLabel)
                    .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)

                if player.available {
                    HStack(spacing: Tokens.Spacing.md) {
                        Button(action: player.toggle) {
                            Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(Tokens.Colors.primaryRed)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            ProgressView(value: player.progress)
                                .tint(Tokens.Colors.primaryRed)
                            HStack {
                                Text(timeString(player.currentTime))
                                Spacer()
                                Text(timeString(player.duration))
                            }
                            .font(Tokens.Fonts.caption)
                            .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                        }
                    }

                    Label("For the clearest lub-dub, use headphones in a quiet room.", systemImage: "headphones")
                        .font(Tokens.Fonts.caption)
                        .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                } else {
                    Text("This recording is no longer available on your device.")
                        .font(Tokens.Fonts.body)
                        .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear { player.load(url: url) }
        .onDisappear { player.stop() }
    }

    private func timeString(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let total = Int(seconds.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
