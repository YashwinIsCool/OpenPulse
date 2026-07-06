import SwiftUI
import SwiftData

private enum ScanSheet: Identifiable {
    case heartRate, heartSound
    var id: Int { hashValue }
}

struct ScanHomeView: View {
    let user: User

    @Query(sort: \HeartRateReading.timestamp, order: .reverse) private var readings: [HeartRateReading]
    @Query(sort: \HeartSoundRecording.timestamp, order: .reverse) private var recordings: [HeartSoundRecording]
    @State private var activeSheet: ScanSheet?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Tokens.Spacing.lg) {
                    Text("Scan")
                        .font(Tokens.Fonts.pageTitle)
                        .tracking(Tokens.Tracking.pageTitle)
                        .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, Tokens.Spacing.sm)

                    Button(action: { activeSheet = .heartRate }) {
                        Card {
                            HStack(spacing: Tokens.Spacing.md) {
                                iconBadge("heart.fill")
                                VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
                                    Text("Heart Rate Check")
                                        .font(Tokens.Fonts.cardTitle)
                                        .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                                    Text(lastReadingSubtitle)
                                        .font(Tokens.Fonts.caption)
                                        .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(Tokens.Colors.adaptiveTextQuaternary)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    Button(action: { activeSheet = .heartSound }) {
                        Card {
                            HStack(spacing: Tokens.Spacing.md) {
                                iconBadge("waveform")
                                VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
                                    Text("Heart Sound Scan")
                                        .font(Tokens.Fonts.cardTitle)
                                        .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                                    Text(lastRecordingSubtitle)
                                        .font(Tokens.Fonts.caption)
                                        .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(Tokens.Colors.adaptiveTextQuaternary)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    Spacer(minLength: 0)
                }
                .padding(Tokens.Spacing.lg)
            }
            .background(Tokens.Colors.adaptiveBackground)
            .fullScreenCover(item: $activeSheet) { sheet in
                switch sheet {
                case .heartRate: HeartRateFlowView(user: user)
                case .heartSound: HeartSoundFlowView(user: user)
                }
            }
        }
    }

    private func iconBadge(_ icon: String) -> some View {
        Image(systemName: icon)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(Tokens.Colors.primaryRed)
            .frame(width: 40, height: 40)
            .background(Tokens.Colors.adaptiveSoftRedSurface)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var lastReadingSubtitle: String {
        guard let last = readings.first else { return "No readings yet — 30-second check" }
        return "Last: \(last.bpm) bpm · \(last.timestamp.formatted(.relative(presentation: .named)))"
    }

    private var lastRecordingSubtitle: String {
        guard let last = recordings.first else { return "Weekly deep check — 30 seconds" }
        return "Last: \(last.classification.rawValue) · \(last.timestamp.formatted(.relative(presentation: .named)))"
    }
}
