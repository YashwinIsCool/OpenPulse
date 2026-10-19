import SwiftUI

/// Builds a one-page PDF "heart record" a person can show a doctor or health
/// worker — in places where personal health records often don't exist at all.
/// Kept in English and in fixed light colors, since it's meant to be printed or
/// read by a clinician.
enum HeartRecordPDF {
    /// US Letter at 72 dpi.
    static let pageSize = CGSize(width: 612, height: 792)

    @MainActor
    static func make(user: User, readings: [HeartRateReading]) -> URL? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("StethoAI heart record \(Date.now.formatted(.iso8601.year().month().day())).pdf")

        let renderer = ImageRenderer(content: HeartRecordPage(user: user, readings: readings)
            .frame(width: pageSize.width, height: pageSize.height))

        var box = CGRect(origin: .zero, size: pageSize)
        guard let context = CGContext(url as CFURL, mediaBox: &box, nil) else { return nil }
        renderer.render { _, draw in
            context.beginPDFPage(nil)
            draw(context)
            context.endPDFPage()
        }
        context.closePDF()
        return url
    }
}

private struct HeartRecordPage: View {
    let user: User
    let readings: [HeartRateReading]

    private let ink = Color(hex: 0x0F172A)
    private let muted = Color(hex: 0x64748B)
    private let rule = Color(hex: 0xE2E8F0)

    private var bpms: [Int] { readings.map(\.bpm) }
    private var flaggedCount: Int {
        readings.filter { HeartRateCategory.categorize(bpm: $0.bpm, activity: user.activityLevel).isConcerning }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Heart record")
                    .font(.system(size: 24, weight: .bold))
                Text("From StethoAI · created \(Date.now.formatted(date: .long, time: .shortened))")
                    .font(.system(size: 11))
                    .foregroundStyle(muted)
            }

            HStack(spacing: 28) {
                field("Name", user.name.isEmpty ? "—" : user.name)
                field("Age", user.age.map(String.init) ?? "—")
                field("Sex", user.sex.rawValue)
            }

            HStack(spacing: 28) {
                field("Readings", "\(readings.count)")
                field("Average", bpms.isEmpty ? "—" : "\(bpms.reduce(0, +) / bpms.count) bpm")
                field("Range", bpms.isEmpty ? "—" : "\(bpms.min()!)–\(bpms.max()!) bpm")
                field("Outside 50–120", "\(flaggedCount)")
            }

            VStack(spacing: 0) {
                tableRow("Date and time", "Heart rate", "Status", header: true)
                ForEach(readings, id: \.persistentModelID) { reading in
                    tableRow(
                        reading.timestamp.formatted(date: .abbreviated, time: .shortened),
                        "\(reading.bpm) bpm",
                        HeartRateCategory.categorize(bpm: reading.bpm, activity: user.activityLevel).shortName,
                        header: false
                    )
                }
            }

            Spacer(minLength: 0)

            Text("Heart rate measured with a phone camera (photoplethysmography) while resting. StethoAI is a wellness and education tool, not a medical device, and these readings are not a diagnosis. Please use your own clinical judgment.")
                .font(.system(size: 9))
                .foregroundStyle(muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(ink)
        .padding(44)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.white)
    }

    private func field(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.system(size: 9)).foregroundStyle(muted)
            Text(value).font(.system(size: 13, weight: .semibold))
        }
    }

    private func tableRow(_ a: String, _ b: String, _ c: String, header: Bool) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(a).frame(maxWidth: .infinity, alignment: .leading)
                Text(b).frame(width: 110, alignment: .leading)
                Text(c).frame(width: 110, alignment: .leading)
            }
            .font(.system(size: 10, weight: header ? .semibold : .regular))
            .foregroundStyle(header ? muted : ink)
            .padding(.vertical, 5)
            Rectangle().fill(rule).frame(height: 0.5)
        }
    }
}
