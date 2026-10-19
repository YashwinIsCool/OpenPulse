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
                VStack(alignment: .leading, spacing: Tokens.Spacing.lg) {
                    header

                    ForEach(resources) { resource in
                        resourceCard(resource)
                    }

                    DisclaimerFooter(text: "StethoAI is for awareness and education — not a diagnosis. These are starting points for finding care, not medical advice.")
                        .padding(.top, Tokens.Spacing.sm)
                }
                .padding(Tokens.Spacing.lg)
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

    private var header: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 34))
                .foregroundStyle(Tokens.Colors.primaryRed)

            Text(loc.t(headline))
                .font(Tokens.Fonts.sectionHeading)
                .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)

            Text(loc.t(subhead))
                .font(Tokens.Fonts.body)
                .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

    private func resourceCard(_ resource: CareResource) -> some View {
        Card {
            VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
                HStack(spacing: Tokens.Spacing.md) {
                    Image(systemName: resource.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(Tokens.Colors.primaryRed)
                        .frame(width: 32, height: 32)
                        .background(Tokens.Colors.adaptiveSoftRedSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                    Text(loc.t(resource.title))
                        .font(Tokens.Fonts.cardTitle)
                        .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                }

                Text(loc.t(resource.detail))
                    .font(Tokens.Fonts.body)
                    .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                actionButton(for: resource)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func actionButton(for resource: CareResource) -> some View {
        switch resource.action {
        case .call(let number):
            Button {
                if let url = URL(string: "tel://\(number.filter { $0.isNumber })") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("\(loc.t(resource.actionLabel ?? "Call")) (\(number))", systemImage: "phone.fill")
                    .font(Tokens.Fonts.body)
                    .foregroundStyle(Tokens.Colors.primaryRed)
            }
            .padding(.top, 2)
        case .website(let urlString):
            Button {
                if let url = URL(string: urlString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label(loc.t(resource.actionLabel ?? "Learn more"), systemImage: "arrow.up.right.square")
                    .font(Tokens.Fonts.body)
                    .foregroundStyle(Tokens.Colors.primaryRed)
            }
            .padding(.top, 2)
        case .info:
            EmptyView()
        }
    }
}
