import SwiftUI

struct BreathingLibraryView: View {
    let user: User
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: Tokens.Spacing.lg) {
                HStack {
                    Text("Breathing")
                        .font(Tokens.Fonts.pageTitle)
                        .tracking(Tokens.Tracking.pageTitle)
                        .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                            .padding(Tokens.Spacing.sm)
                            .background(Tokens.Colors.adaptiveCard)
                            .clipShape(Circle())
                    }
                }
                .padding(.top, Tokens.Spacing.sm)

                ForEach(BreathingExerciseType.allCases, id: \.self) { type in
                    NavigationLink(destination: BreathingDetailView(user: user, exerciseType: type)) {
                        Card {
                            HStack(spacing: Tokens.Spacing.md) {
                                Image(systemName: "wind")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(Tokens.Colors.primaryRed)
                                    .frame(width: 40, height: 40)
                                    .background(Tokens.Colors.adaptiveSoftRedSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                                VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
                                    Text(type.rawValue)
                                        .font(Tokens.Fonts.cardTitle)
                                        .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                                    Text("\(type.subtitle) · \(type.durationSeconds / 60) min")
                                        .font(Tokens.Fonts.caption)
                                        .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                                }
                                Spacer()
                                Text("Start")
                                    .font(Tokens.Fonts.caption)
                                    .foregroundStyle(Tokens.Colors.primaryRed)
                                    .padding(.horizontal, Tokens.Spacing.sm)
                                    .padding(.vertical, Tokens.Spacing.xs)
                                    .background(Tokens.Colors.adaptiveSoftRedSurface)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 0)
            }
            .padding(Tokens.Spacing.lg)
        }
        .background(Tokens.Colors.adaptiveBackground)
        .navigationBarHidden(true)
    }
}
