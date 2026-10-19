import SwiftUI

/// The reading result — the screen people remember. Big number, one plain sentence
/// in a color that means something, a simple range bar anyone can read, and (if the
/// reading is flagged) the routes to care right here rather than behind a button.
struct HeartRateResultView: View {
    let user: User
    let bpm: Int
    let hrvMs: Double?
    let onSave: () -> Void

    @ObservedObject private var loc = Localizer.shared

    private var category: HeartRateCategory { HeartRateCategory.categorize(bpm: bpm) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Spacing.xxl) {
                reading
                HeartRateRangeBar(bpm: bpm)
                guidance
                if category.isConcerning {
                    careOptions
                }
            }
            .padding(.horizontal, Tokens.Spacing.xl)
            .padding(.top, 48)
            .padding(.bottom, Tokens.Spacing.xl)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: Tokens.Spacing.sm) {
                PrimaryButton(title: loc.t("Save & Continue"), action: onSave)
                DisclaimerFooter()
            }
            .padding(.horizontal, Tokens.Spacing.xl)
            .padding(.top, Tokens.Spacing.md)
            .padding(.bottom, Tokens.Spacing.sm)
            .background(Tokens.Colors.adaptiveBackground)
        }
    }

    private var reading: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
            Text(loc.t("Your heart rate"))
                .font(Tokens.Fonts.secondaryText)
                .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
            HStack(alignment: .lastTextBaseline, spacing: Tokens.Spacing.sm) {
                Text("\(bpm)")
                    .font(Tokens.Fonts.readingNumber)
                    .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                Text("bpm")
                    .font(Tokens.Fonts.headline)
                    .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
            }
            Text(loc.t(category.headline))
                .font(Tokens.Fonts.headline)
                .foregroundStyle(category.statusColor)
        }
    }

    private var guidance: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
            Text(loc.t(category.plainGuidance))
                .font(Tokens.Fonts.bodyText)
                .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
            if let hrvMs {
                Text("\(loc.t("Heart rate variability")): \(Int(hrvMs)) ms")
                    .font(Tokens.Fonts.secondaryText)
                    .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
            }
        }
    }

    // MARK: - Pathway to care, shown inline for flagged readings

    private var careOptions: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
            Text(loc.t("Where to go"))
                .font(Tokens.Fonts.headline)
                .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)

            VStack(spacing: 0) {
                ForEach(Array(CareResources.forDeployment.enumerated()), id: \.element.id) { index, resource in
                    if index > 0 {
                        Rectangle().fill(Tokens.Colors.adaptiveBorder).frame(height: 1)
                    }
                    careRow(resource)
                }
            }
            .padding(.horizontal, Tokens.Spacing.lg)
            .background(Tokens.Colors.adaptiveCard)
            .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Tokens.Radius.card, style: .continuous)
                    .stroke(Tokens.Colors.adaptiveBorder, lineWidth: 1)
            )
        }
    }

    private func careRow(_ resource: CareResource) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
            Text(loc.t(resource.title))
                .font(Tokens.Fonts.bodyText.weight(.semibold))
                .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
            Text(loc.t(resource.detail))
                .font(Tokens.Fonts.secondaryText)
                .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
            careAction(resource)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private func careAction(_ resource: CareResource) -> some View {
        switch resource.action {
        case .call(let number):
            Button {
                if let url = URL(string: "tel://\(number.filter { $0.isNumber })") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("\(loc.t(resource.actionLabel ?? "Call")) (\(number))", systemImage: "phone.fill")
                    .font(Tokens.Fonts.secondaryText.weight(.semibold))
                    .foregroundStyle(Tokens.Colors.statusFlag)
            }
            .padding(.top, 2)
        case .website(let urlString):
            Button {
                if let url = URL(string: urlString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label(loc.t(resource.actionLabel ?? "Learn more"), systemImage: "arrow.up.right.square")
                    .font(Tokens.Fonts.secondaryText.weight(.semibold))
                    .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
            }
            .padding(.top, 2)
        case .info:
            EmptyView()
        }
    }
}

/// A low / normal / high bar with a marker for the reading — readable at a glance
/// without needing to know what "bpm" ranges mean.
struct HeartRateRangeBar: View {
    let bpm: Int

    private let lower = 40.0
    private let upper = 140.0
    // Zone boundaries match HeartRateCategory.categorize.
    private let zones: [(end: Double, color: Color)] = [
        (50, Tokens.Colors.statusFlag),
        (90, Tokens.Colors.statusGood),
        (120, Tokens.Colors.statusWatch),
        (140, Tokens.Colors.statusFlag)
    ]

    private func fraction(_ value: Double) -> CGFloat {
        CGFloat((min(max(value, lower), upper) - lower) / (upper - lower))
    }

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                let width = geo.size.width
                ZStack(alignment: .leading) {
                    HStack(spacing: 2) {
                        ForEach(Array(zones.enumerated()), id: \.offset) { index, zone in
                            let start = index == 0 ? lower : zones[index - 1].end
                            Capsule()
                                .fill(zone.color.opacity(0.3))
                                .frame(width: max(0, width * fraction(zone.end) - width * fraction(start) - 2))
                        }
                    }
                    .frame(height: 10)

                    Capsule()
                        .fill(Tokens.Colors.adaptiveTextPrimary)
                        .frame(width: 5, height: 24)
                        .offset(x: width * fraction(Double(bpm)) - 2.5)
                }
                .frame(height: 24)
            }
            .frame(height: 24)

            GeometryReader { geo in
                ForEach([50, 90, 120], id: \.self) { mark in
                    Text("\(mark)")
                        .font(.caption)
                        .foregroundStyle(Tokens.Colors.adaptiveTextQuaternary)
                        .fixedSize()
                        .position(x: geo.size.width * fraction(Double(mark)), y: 8)
                }
            }
            .frame(height: 16)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(bpm) beats per minute")
    }
}

extension HeartRateCategory {
    /// Plain-language headline for the result screen.
    var headline: String {
        switch self {
        case .low: return "Lower than usual at rest"
        case .restingNormal: return "Normal for a resting heart"
        case .elevated: return "A little higher than usual"
        case .high: return "Higher than usual at rest"
        }
    }

    /// One-word status for compact places like Home's "last check" line.
    var shortName: String {
        switch self {
        case .low: return "Low"
        case .restingNormal: return "Normal"
        case .elevated: return "A little high"
        case .high: return "High"
        }
    }

    var statusColor: Color {
        switch self {
        case .restingNormal: return Tokens.Colors.statusGood
        case .elevated: return Tokens.Colors.statusWatch
        case .low, .high: return Tokens.Colors.statusFlag
        }
    }
}
