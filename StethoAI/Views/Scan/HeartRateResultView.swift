import SwiftUI

struct HeartRateResultView: View {
    let user: User
    let bpm: Int
    let hrvMs: Double?
    let onSave: () -> Void

    @State private var showCare = false

    private var category: HeartRateCategory { HeartRateCategory.categorize(bpm: bpm) }

    private var badgeColor: Color {
        switch category {
        case .low, .restingNormal: return Tokens.Colors.successGreen
        case .elevated: return Tokens.Colors.warningAmber
        case .high: return Tokens.Colors.dangerDark
        }
    }

    private var badgeBg: Color {
        switch category {
        case .low, .restingNormal: return Tokens.Colors.successBg
        case .elevated: return Tokens.Colors.warningBg
        case .high: return Tokens.Colors.lightRedTint
        }
    }

    var body: some View {
        VStack(spacing: Tokens.Spacing.xl) {
            Spacer()

            VStack(spacing: Tokens.Spacing.xs) {
                HStack(alignment: .lastTextBaseline, spacing: Tokens.Spacing.xs) {
                    Text("\(bpm)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(Tokens.Colors.primaryRed)
                    Text("bpm")
                        .font(Tokens.Fonts.body)
                        .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                }

                Text(category.rawValue)
                    .font(Tokens.Fonts.microLabel)
                    .tracking(Tokens.Tracking.microLabel)
                    .foregroundStyle(badgeColor)
                    .padding(.horizontal, Tokens.Spacing.md)
                    .padding(.vertical, Tokens.Spacing.xs)
                    .background(badgeBg)
                    .clipShape(Capsule())
            }

            if let hrvMs {
                StatTile(icon: "waveform.path.ecg", label: "HRV Estimate", value: "\(Int(hrvMs)) ms")
                    .frame(maxWidth: 200)
            }

            Text(category.plainGuidance)
                .font(Tokens.Fonts.body)
                .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Tokens.Spacing.xxl)

            Spacer()

            VStack(spacing: Tokens.Spacing.md) {
                if category.isConcerning {
                    SecondaryButton(title: "See where to get care", icon: "cross.case.fill") {
                        showCare = true
                    }
                }
                PrimaryButton(title: "Save & Continue", icon: "checkmark", action: onSave)
                DisclaimerFooter()
            }
            .padding(.horizontal, Tokens.Spacing.xl)
            .padding(.bottom, Tokens.Spacing.xl)
        }
        .sheet(isPresented: $showCare) {
            FindCareView(category: category)
        }
    }
}
