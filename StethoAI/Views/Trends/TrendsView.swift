import SwiftUI
import SwiftData
import Charts

struct TrendsView: View {
    let user: User

    @Query(sort: \HeartRateReading.timestamp, order: .forward) private var allReadings: [HeartRateReading]
    @Query(sort: \HeartSoundRecording.timestamp, order: .reverse) private var recordings: [HeartSoundRecording]
    @Query(sort: \BreathingSession.timestamp, order: .reverse) private var breathingSessions: [BreathingSession]

    @State private var period: String = "30D"
    @State private var selectedRecording: HeartSoundRecording?
    private let periods = ["7D", "30D", "90D", "1Y"]

    private var periodDays: Int {
        switch period {
        case "7D": return 7
        case "30D": return 30
        case "90D": return 90
        default: return 365
        }
    }

    private var filteredReadings: [HeartRateReading] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -periodDays, to: .now) ?? .distantPast
        return allReadings.filter { $0.timestamp >= cutoff }
    }

    private var previousPeriodReadings: [HeartRateReading] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -periodDays, to: .now) ?? .distantPast
        let priorCutoff = Calendar.current.date(byAdding: .day, value: -(periodDays * 2), to: .now) ?? .distantPast
        return allReadings.filter { $0.timestamp >= priorCutoff && $0.timestamp < cutoff }
    }

    private var currentAverage: Int? {
        average(of: filteredReadings)
    }

    private var previousAverage: Int? {
        average(of: previousPeriodReadings)
    }

    private var averageHRV: Double? {
        let values = filteredReadings.compactMap { $0.hrvMs }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    /// One point per day (the day's average), so several readings taken minutes
    /// apart don't zoom the chart's time axis down to seconds.
    private var dailyAverages: [(day: Date, bpm: Int)] {
        let byDay = Dictionary(grouping: filteredReadings) { Calendar.current.startOfDay(for: $0.timestamp) }
        return byDay.compactMap { day, readings in average(of: readings).map { (day, $0) } }
            .sorted { $0.day < $1.day }
    }

    private var chartXDomain: ClosedRange<Date> {
        let today = Calendar.current.startOfDay(for: .now)
        let start = Calendar.current.date(byAdding: .day, value: -(periodDays - 1), to: today) ?? today
        let end = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? .now
        return start...end
    }

    /// Four evenly spaced date labels, kept off the right edge so none get clipped.
    private var chartXTicks: [Date] {
        let domain = chartXDomain
        let span = domain.upperBound.timeIntervalSince(domain.lowerBound)
        return (0..<4).map { domain.lowerBound.addingTimeInterval(span * (0.05 + Double($0) * 0.25)) }
    }

    private var chartYDomain: ClosedRange<Int> {
        let values = dailyAverages.map(\.bpm)
        let low = min(values.min() ?? 60, 60) - 10
        let high = max(values.max() ?? 90, 90) + 10
        return low...high
    }

    private var daysTracked: Int {
        Set(filteredReadings.map { Calendar.current.startOfDay(for: $0.timestamp) }).count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Tokens.Spacing.lg) {
                    HStack {
                        Text("Trends")
                            .font(Tokens.Fonts.pageTitle)
                            .tracking(Tokens.Tracking.pageTitle)
                            .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                        Spacer()
                    }
                    .padding(.top, Tokens.Spacing.sm)

                    SegmentedToggle(options: periods, selection: $period)

                    heroSummary

                    chartCard

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Tokens.Spacing.md) {
                        StatTile(icon: "heart.fill", label: "Resting HR Avg", value: currentAverage.map { "\($0) bpm" } ?? "—")
                        StatTile(icon: "waveform.path.ecg", label: "HRV Avg", value: averageHRV.map { "\(Int($0)) ms" } ?? "—")
                        StatTile(icon: "flame.fill", label: "Streak", value: "\(user.streakCount) day\(user.streakCount == 1 ? "" : "s")")
                        StatTile(icon: "calendar", label: "Days Tracked", value: "\(daysTracked)")
                    }

                    heartSoundHistory
                }
                .padding(Tokens.Spacing.lg)
            }
            .background(Tokens.Colors.adaptiveBackground)
        }
    }

    private var heroSummary: some View {
        HeroCard {
            VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
                Text("AVERAGE HEART RATE")
                    .font(Tokens.Fonts.microLabel)
                    .tracking(Tokens.Tracking.microLabel)
                    .foregroundStyle(.white.opacity(0.92))

                if let currentAverage {
                    HStack(alignment: .lastTextBaseline, spacing: Tokens.Spacing.xs) {
                        Text("\(currentAverage)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(.white)
                        Text("bpm")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                    }

                    if let previousAverage {
                        let diff = currentAverage - previousAverage
                        HStack(spacing: Tokens.Spacing.xs) {
                            Image(systemName: diff <= 0 ? "arrow.down" : "arrow.up")
                            Text("\(abs(diff)) bpm vs previous \(period)")
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                    }
                } else {
                    Text("No data yet")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var chartCard: some View {
        Card {
            VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
                Text("Heart rate over time")
                    .font(Tokens.Fonts.cardTitle)
                    .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)

                if filteredReadings.isEmpty {
                    Text("Complete a heart rate check to start your chart.")
                        .font(Tokens.Fonts.body)
                        .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                        .frame(maxWidth: .infinity, minHeight: 160)
                } else {
                    Chart(dailyAverages, id: \.day) { point in
                        AreaMark(
                            x: .value("Date", point.day, unit: .day),
                            yStart: .value("Floor", chartYDomain.lowerBound),
                            yEnd: .value("BPM", point.bpm)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Tokens.Colors.chartAreaFillTop, Tokens.Colors.chartAreaFillBottom],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        LineMark(
                            x: .value("Date", point.day, unit: .day),
                            y: .value("BPM", point.bpm)
                        )
                        .foregroundStyle(Tokens.Colors.chartLineRed)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        PointMark(
                            x: .value("Date", point.day, unit: .day),
                            y: .value("BPM", point.bpm)
                        )
                        .foregroundStyle(Tokens.Colors.chartLineRed)
                        .symbolSize(dailyAverages.count == 1 ? 60 : 20)
                    }
                    .frame(height: 180)
                    .chartXScale(domain: chartXDomain)
                    .chartYScale(domain: chartYDomain)
                    .chartXAxis {
                        AxisMarks(values: chartXTicks) { _ in
                            AxisGridLine()
                            AxisValueLabel(format: periodDays > 90
                                ? .dateTime.month(.abbreviated)
                                : .dateTime.month(.abbreviated).day())
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                }
            }
        }
    }

    private var heartSoundHistory: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
            Text("Heart sound history")
                .font(Tokens.Fonts.sectionHeading)
                .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if recordings.isEmpty {
                Card {
                    Text("No heart sound recordings yet.")
                        .font(Tokens.Fonts.body)
                        .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Tokens.Spacing.md) {
                        ForEach(recordings) { recording in
                            Button { selectedRecording = recording } label: {
                                heartSoundTile(recording)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .sheet(item: $selectedRecording) { recording in
            HeartSoundDetailView(recording: recording)
        }
    }

    private func heartSoundTile(_ recording: HeartSoundRecording) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 20))
                .foregroundStyle(Tokens.Colors.primaryRed)
            Text("Heart sound")
                .font(Tokens.Fonts.cardTitle)
                .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
            Text(recording.timestamp.formatted(date: .abbreviated, time: .omitted))
                .font(Tokens.Fonts.caption)
                .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
            Label("Play", systemImage: "play.circle.fill")
                .font(Tokens.Fonts.caption)
                .foregroundStyle(Tokens.Colors.primaryRed)
                .padding(.top, 2)
        }
        .padding(Tokens.Spacing.md)
        .frame(width: 140, alignment: .leading)
        .background(Tokens.Colors.adaptiveCard)
        .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Tokens.Radius.card, style: .continuous)
                .stroke(Tokens.Colors.adaptiveBorder, lineWidth: 1)
        )
    }

    private func average(of readings: [HeartRateReading]) -> Int? {
        guard !readings.isEmpty else { return nil }
        let sum = readings.reduce(0) { $0 + $1.bpm }
        return Int((Double(sum) / Double(readings.count)).rounded())
    }
}

/// Detail sheet for a past heart-sound recording: listen back and share the audio.
private struct HeartSoundDetailView: View {
    let recording: HeartSoundRecording
    @Environment(\.dismiss) private var dismiss
    @State private var isSharePresented = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Tokens.Spacing.lg) {
                    VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
                        Text(recording.timestamp.formatted(date: .complete, time: .shortened))
                            .font(Tokens.Fonts.sectionHeading)
                            .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                        Text("Recorded heart sound")
                            .font(Tokens.Fonts.caption)
                            .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                    }

                    HeartSoundPlayerView(url: recording.fileURL)

                    SecondaryButton(title: "Share with Doctor", icon: "square.and.arrow.up") {
                        isSharePresented = true
                    }

                    DisclaimerFooter(text: "Educational use only · Not medical advice.")
                }
                .padding(Tokens.Spacing.lg)
            }
            .background(Tokens.Colors.adaptiveBackground)
            .navigationTitle("Heart sound")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $isSharePresented) {
            ShareSheet(items: shareItems)
        }
    }

    private var shareItems: [Any] {
        var items: [Any] = ["StethoAI heart sound recording from \(recording.timestamp.formatted(date: .abbreviated, time: .shortened)). Educational use only, not medical advice."]
        if let url = recording.fileURL, FileManager.default.fileExists(atPath: url.path) {
            items.append(url)
        }
        return items
    }
}
