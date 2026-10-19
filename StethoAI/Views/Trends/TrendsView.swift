import SwiftUI
import SwiftData
import Charts

/// The History tab: how readings have moved over time, every reading in a plain
/// list, saved heart sounds, and a one-tap heart record to show a doctor.
struct TrendsView: View {
    let user: User

    @Query(sort: \HeartRateReading.timestamp, order: .reverse) private var allReadings: [HeartRateReading]
    @Query(sort: \HeartSoundRecording.timestamp, order: .reverse) private var recordings: [HeartSoundRecording]
    @ObservedObject private var loc = Localizer.shared

    enum Period: String, CaseIterable, Identifiable {
        case week = "Week", month = "Month", year = "Year"
        var id: String { rawValue }
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .year: return 365
            }
        }
    }

    @State private var period: Period = .month
    @State private var showAllReadings = false
    @State private var selectedRecording: HeartSoundRecording?
    @State private var report: SharedFile?

    private var readings: [HeartRateReading] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -period.days, to: .now) ?? .distantPast
        return allReadings.filter { $0.timestamp >= cutoff }
    }

    private var average: Int? {
        guard !readings.isEmpty else { return nil }
        return Int((Double(readings.reduce(0) { $0 + $1.bpm }) / Double(readings.count)).rounded())
    }

    private var daysChecked: Int {
        Set(readings.map { Calendar.current.startOfDay(for: $0.timestamp) }).count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Tokens.Spacing.xxl) {
                    Text(loc.t("History"))
                        .font(Tokens.Fonts.screenTitle)
                        .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)

                    Picker("", selection: $period) {
                        ForEach(Period.allCases) { Text(loc.t($0.rawValue)).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    if readings.isEmpty {
                        emptyState
                    } else {
                        summary
                        HeartRateHistoryChart(readings: readings, days: period.days)
                            .frame(height: 200)
                        readingsList
                    }

                    heartSounds

                    if !allReadings.isEmpty {
                        SecondaryButton(title: loc.t("Share with a doctor"), icon: "doc.text") {
                            report = HeartRecordPDF.make(user: user, readings: Array(allReadings.prefix(30)))
                                .map(SharedFile.init)
                        }
                    }
                }
                .padding(.horizontal, Tokens.Spacing.xl)
                .padding(.top, Tokens.Spacing.lg)
                .padding(.bottom, Tokens.Spacing.xxl)
            }
            .background(Tokens.Colors.adaptiveBackground)
            .navigationBarHidden(true)
            .sheet(item: $selectedRecording) { HeartSoundDetailView(recording: $0) }
            .sheet(item: $report) { ShareSheet(items: [$0.url]) }
        }
    }

    // MARK: - Sections

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
            Text(loc.t("No checks yet"))
                .font(Tokens.Fonts.headline)
                .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
            Text(loc.t("Your readings will show up here after your first heart check."))
                .font(Tokens.Fonts.bodyText)
                .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(loc.t("Average"))
                .font(Tokens.Fonts.secondaryText)
                .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
            (
                Text("\(average ?? 0)")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                + Text(" bpm · \(daysChecked) \(loc.t(daysChecked == 1 ? "day checked" : "days checked"))")
                    .font(Tokens.Fonts.secondaryText)
                    .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
            )
        }
    }

    private var readingsList: some View {
        let shown = showAllReadings ? readings : Array(readings.prefix(5))
        return VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
            Text(loc.t("Readings"))
                .font(Tokens.Fonts.headline)
                .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
            ListCard {
                ForEach(Array(shown.enumerated()), id: \.element.id) { index, reading in
                    if index > 0 { ListDivider() }
                    readingRow(reading)
                }
                if readings.count > 5 {
                    ListDivider()
                    Button {
                        withAnimation { showAllReadings.toggle() }
                    } label: {
                        Text(showAllReadings ? loc.t("Show fewer") : "\(loc.t("Show all")) (\(readings.count))")
                            .font(Tokens.Fonts.bodyText)
                            .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func readingRow(_ reading: HeartRateReading) -> some View {
        let category = HeartRateCategory.categorize(bpm: reading.bpm, activity: user.activityLevel)
        return HStack {
            Text(reading.timestamp.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                .font(Tokens.Fonts.bodyText)
                .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
            Spacer()
            Text("\(reading.bpm)")
                .font(Tokens.Fonts.bodyText.weight(.semibold))
                .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                .monospacedDigit()
            Text(loc.t(category.shortName))
                .font(Tokens.Fonts.secondaryText)
                .foregroundStyle(category.statusColor)
                .frame(minWidth: 70, alignment: .trailing)
        }
        .padding(.vertical, 12)
    }

    private var heartSounds: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
            Text(loc.t("Heart sounds"))
                .font(Tokens.Fonts.headline)
                .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
            if recordings.isEmpty {
                Text(loc.t("Recordings you make will appear here, ready to play or share."))
                    .font(Tokens.Fonts.secondaryText)
                    .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
            } else {
                ListCard {
                    ForEach(Array(recordings.prefix(10).enumerated()), id: \.element.id) { index, recording in
                        if index > 0 { ListDivider() }
                        Button { selectedRecording = recording } label: {
                            HStack {
                                Text(recording.timestamp.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                                    .font(Tokens.Fonts.bodyText)
                                    .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                                Spacer()
                                Image(systemName: "play.circle")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                            }
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Chart

/// Daily averages over the period, with the typical resting range (50–90) shaded so
/// the line has meaning without reading axis numbers.
struct HeartRateHistoryChart: View {
    let readings: [HeartRateReading]
    let days: Int

    private var dailyAverages: [(day: Date, bpm: Int)] {
        let byDay = Dictionary(grouping: readings) { Calendar.current.startOfDay(for: $0.timestamp) }
        return byDay.map { day, items in
            (day, Int((Double(items.reduce(0) { $0 + $1.bpm }) / Double(items.count)).rounded()))
        }
        .sorted { $0.day < $1.day }
    }

    private var xDomain: ClosedRange<Date> {
        let today = Calendar.current.startOfDay(for: .now)
        let start = Calendar.current.date(byAdding: .day, value: -(days - 1), to: today) ?? today
        let end = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? .now
        return start...end
    }

    private var xTicks: [Date] {
        let span = xDomain.upperBound.timeIntervalSince(xDomain.lowerBound)
        return (0..<4).map { xDomain.lowerBound.addingTimeInterval(span * (0.05 + Double($0) * 0.25)) }
    }

    private var yDomain: ClosedRange<Int> {
        let values = dailyAverages.map(\.bpm)
        return (min(values.min() ?? 50, 50) - 10)...(max(values.max() ?? 90, 90) + 10)
    }

    var body: some View {
        Chart {
            RectangleMark(
                xStart: .value("Start", xDomain.lowerBound),
                xEnd: .value("End", xDomain.upperBound),
                yStart: .value("Low", 50),
                yEnd: .value("High", 90)
            )
            .foregroundStyle(Tokens.Colors.statusGood.opacity(0.08))

            ForEach(dailyAverages, id: \.day) { point in
                LineMark(x: .value("Date", point.day, unit: .day), y: .value("BPM", point.bpm))
                    .foregroundStyle(Tokens.Colors.ink)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                PointMark(x: .value("Date", point.day, unit: .day), y: .value("BPM", point.bpm))
                    .foregroundStyle(Tokens.Colors.ink)
                    .symbolSize(dailyAverages.count == 1 ? 60 : 16)
            }
        }
        .chartXScale(domain: xDomain)
        .chartYScale(domain: yDomain)
        .chartXAxis {
            AxisMarks(values: xTicks) { _ in
                AxisValueLabel(format: days > 90 ? .dateTime.month(.abbreviated) : .dateTime.month(.abbreviated).day())
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: [50, 90, 120].filter { yDomain.contains($0) }) { _ in
                AxisGridLine()
                AxisValueLabel()
            }
        }
    }
}

// MARK: - Small list building blocks

struct ListCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) { content }
            .padding(.horizontal, Tokens.Spacing.lg)
            .background(Tokens.Colors.adaptiveCard)
            .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Tokens.Radius.card, style: .continuous)
                    .stroke(Tokens.Colors.adaptiveBorder, lineWidth: 1)
            )
    }
}

struct ListDivider: View {
    var body: some View {
        Rectangle().fill(Tokens.Colors.adaptiveBorder).frame(height: 1)
    }
}

/// A file ready to hand to the share sheet.
struct SharedFile: Identifiable {
    let url: URL
    var id: URL { url }
}

// MARK: - Heart sound detail

/// Detail sheet for a past heart-sound recording: listen back and share the audio.
private struct HeartSoundDetailView: View {
    let recording: HeartSoundRecording
    @Environment(\.dismiss) private var dismiss
    @State private var isSharePresented = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Tokens.Spacing.lg) {
                    Text(recording.timestamp.formatted(date: .complete, time: .shortened))
                        .font(Tokens.Fonts.headline)
                        .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)

                    HeartSoundPlayerView(url: recording.fileURL)

                    SecondaryButton(title: "Share with a doctor", icon: "square.and.arrow.up") {
                        isSharePresented = true
                    }

                    DisclaimerFooter(text: "Educational use only · Not medical advice.")
                }
                .padding(Tokens.Spacing.xl)
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
