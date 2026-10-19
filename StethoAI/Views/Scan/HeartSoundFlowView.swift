import SwiftUI
import SwiftData
import AVFoundation

private enum HeartSoundStep {
    case instructions, recording, analyzing, result
}

struct HeartSoundFlowView: View {
    let user: User

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var recorder = HeartSoundRecorder()

    @State private var step: HeartSoundStep = .instructions
    @State private var recordingURL: URL?
    @State private var result: HeartSoundResult?
    @State private var showMicDenied = false

    var body: some View {
        ZStack {
            Tokens.Colors.adaptiveBackground.ignoresSafeArea()

            switch step {
            case .instructions:
                HeartSoundInstructionsView(onStart: startRecording, onCancel: { dismiss() })
            case .recording:
                HeartSoundRecordingView(recorder: recorder, onCancel: cancelRecording)
            case .analyzing:
                HeartSoundAnalyzingView()
            case .result:
                if let result, let recordingURL {
                    HeartSoundResultView(
                        result: result,
                        audioURL: recordingURL,
                        onSave: { saveAndFinish(result: result, url: recordingURL) },
                        onNewScan: { step = .instructions },
                        onDismiss: { dismiss() }
                    )
                }
            }
        }
        // Keep the screen awake for the whole scan — the phone is against the chest
        // and must not auto-lock mid-recording.
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        .alert("Microphone is off", isPresented: $showMicDenied) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("StethoAI needs the microphone to record your heart sound. You can turn it on in Settings.")
        }
    }

    /// Ask for the microphone first. Starting AVAudioRecorder while permission is
    /// still undetermined triggers the system prompt from inside `record()` on the
    /// main thread, which deadlocks the app (onboarding lets people skip "Grant").
    private func startRecording() {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            beginRecording()
        case .denied:
            showMicDenied = true
        default:
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if granted { beginRecording() } else { showMicDenied = true }
                }
            }
        }
    }

    private func beginRecording() {
        step = .recording
        recorder.onFinished = { url in
            recordingURL = url
            step = .analyzing
            runAnalysis(url: url)
        }
        recorder.start()
    }

    private func cancelRecording() {
        recorder.cancel()
        dismiss()
    }

    private func runAnalysis(url: URL) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            self.result = HeartSoundAnalyzer.analyzeHeartSound(url)
            self.step = .result
        }
    }

    private func saveAndFinish(result: HeartSoundResult, url: URL) {
        // Copy the temp recording into permanent storage so it survives and can be
        // played back later; store the bare filename.
        let storedName = HeartSoundStore.persist(tempURL: url) ?? url.lastPathComponent
        let recording = HeartSoundRecording(
            fileURLString: storedName,
            classification: result.classification,
            confidence: result.confidence,
            s1Clarity: result.s1Clarity,
            s2Clarity: result.s2Clarity,
            s3Detected: result.s3Detected,
            s4Detected: result.s4Detected,
            murmurLikelihood: result.murmurLikelihood
        )
        modelContext.insert(recording)
        StreakManager.updateStreakIfDayComplete(context: modelContext, user: user)
        dismiss()
    }
}
