import SwiftUI

struct LanguageSettingsView: View {
    @ObservedObject private var loc = Localizer.shared

    var body: some View {
        List {
            Section {
                ForEach(AppLanguage.allCases) { language in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) { loc.language = language }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(language.nativeName)
                                    .font(Tokens.Fonts.bodyText)
                                    .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                                if language != .en {
                                    Text(language.englishName)
                                        .font(Tokens.Fonts.secondaryText)
                                        .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                                }
                            }
                            Spacer()
                            if loc.language == language {
                                Image(systemName: "checkmark")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(Tokens.Colors.ink)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(loc.language == language ? .isSelected : [])
                }
            } header: {
                Text(loc.t("Choose your language"))
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Tokens.Colors.adaptiveBackground)
        .navigationTitle(loc.t("Language"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
