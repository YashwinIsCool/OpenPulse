import SwiftUI

/// The pathway-to-care screen. Opened when a reading is flagged, or anytime from the
/// More tab. Its job: turn "see a doctor" (useless to someone with no doctor) into
/// real, local, actionable routes to care — given calmly and with dignity.
struct FindCareView: View {
    /// Optional reading context to show a calm, specific message at the top.
    var category: HeartRateCategory? = nil
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var loc = Localizer.shared

    private let resources = CareResources.forDeployment

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Tokens.Spacing.xxl) {
                    VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
                        Text(loc.t(headline))
                            .font(Tokens.Fonts.screenTitle)
                            .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                        Text(loc.t(subhead))
                            .font(Tokens.Fonts.bodyText)
                            .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    ListCard {
                        ForEach(Array(resources.enumerated()), id: \.element.id) { index, resource in
                            if index > 0 { ListDivider() }
                            CareResourceRow(resource: resource)
                        }
                    }

                    DisclaimerFooter(text: "OpenPulse is for awareness and education — not a diagnosis. These are starting points for finding care, not medical advice.")
                }
                .padding(.horizontal, Tokens.Spacing.xl)
                .padding(.vertical, Tokens.Spacing.lg)
            }
            .background(Tokens.Colors.adaptiveBackground)
            .navigationTitle(loc.t("Where to get care"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(loc.t("Done")) { dismiss() }
                }
            }
        }
    }

    private var headline: String {
        guard let category, category.isConcerning else {
            return "Getting your heart checked"
        }
        return "Let's find you some care"
    }

    private var subhead: String {
        if let category, category.isConcerning {
            return "This is only a reading, not a diagnosis — try not to worry. The best next step is to have a health worker or doctor take a look. Here's where you can start, close to you and low-cost or free."
        }
        return "If you ever want a professional to check your heart, here are low-cost and free places to start — no matter where you are."
    }
}
