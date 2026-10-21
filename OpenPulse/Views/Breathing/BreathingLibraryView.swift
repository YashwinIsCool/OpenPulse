import SwiftUI

struct BreathingLibraryView: View {
    let user: User
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Spacing.xxl) {
                HStack {
                    Text("Breathing")
                        .font(Tokens.Fonts.screenTitle)
                        .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                            .padding(10)
                            .background(Tokens.Colors.adaptiveCard)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Close")
                }
                .padding(.top, Tokens.Spacing.sm)

                Text("Slow breathing can help your heart settle. Pick one and follow the circle.")
                    .font(Tokens.Fonts.bodyText)
                    .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)

                ListCard {
                    ForEach(Array(BreathingExerciseType.allCases.enumerated()), id: \.element) { index, type in
                        if index > 0 { ListDivider() }
                        NavigationLink(destination: BreathingDetailView(user: user, exerciseType: type)) {
                            HStack(spacing: Tokens.Spacing.md) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(type.rawValue)
                                        .font(Tokens.Fonts.bodyText)
                                        .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                                    Text("\(type.subtitle) · \(type.durationSeconds / 60) min")
                                        .font(Tokens.Fonts.secondaryText)
                                        .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Tokens.Colors.adaptiveTextQuaternary)
                            }
                            .padding(.vertical, 14)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, Tokens.Spacing.xl)
            .padding(.bottom, Tokens.Spacing.xl)
        }
        .background(Tokens.Colors.adaptiveBackground)
        .navigationBarHidden(true)
    }
}
