import SwiftUI

struct LanguageSettingsView: View {
    @ObservedObject private var loc = Localizer.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
                Text(loc.t("Choose your language"))
                    .font(Tokens.Fonts.sectionHeading)
                    .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                    .padding(.bottom, Tokens.Spacing.xs)

                ForEach(AppLanguage.allCases) { language in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) { loc.language = language }
                    } label: {
                        HStack(spacing: Tokens.Spacing.md) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(language.nativeName)
                                    .font(Tokens.Fonts.cardTitle)
                                    .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                                if language != .en {
                                    Text(language.englishName)
                                        .font(Tokens.Fonts.caption)
                                        .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                                }
                            }
                            Spacer()
                            if loc.language == language {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Tokens.Colors.primaryRed)
                            }
                        }
                        .padding(Tokens.Spacing.lg)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Tokens.Colors.adaptiveCard)
                        .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.card, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Tokens.Radius.card, style: .continuous)
                                .stroke(loc.language == language ? Tokens.Colors.primaryRed : Tokens.Colors.adaptiveBorder,
                                        lineWidth: loc.language == language ? 1.5 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Tokens.Spacing.lg)
        }
        .background(Tokens.Colors.adaptiveBackground)
        .navigationTitle(loc.t("Language"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
