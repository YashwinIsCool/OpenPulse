import SwiftUI

struct AccountView: View {
    let user: User

    @State private var name: String = ""
    @State private var age: String = ""
    @State private var sex: BiologicalSex = .preferNotToSay

    var body: some View {
        ScrollView {
            VStack(spacing: Tokens.Spacing.md) {
                Card {
                    VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
                        fieldLabel("First name")
                        TextField("Optional", text: $name)
                            .font(Tokens.Fonts.body)
                            .onChange(of: name) { _, newValue in user.name = newValue }
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
                        fieldLabel("Age")
                        TextField("Optional", text: $age)
                            .font(Tokens.Fonts.body)
                            .keyboardType(.numberPad)
                            .onChange(of: age) { _, newValue in user.age = Int(newValue) }
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
                        fieldLabel("Sex assigned at birth")
                        Picker("Sex", selection: $sex) {
                            ForEach(BiologicalSex.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: sex) { _, newValue in user.sex = newValue }
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
                        fieldLabel("Current streak")
                        Text("\(user.streakCount) days")
                            .font(Tokens.Fonts.cardTitle)
                            .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                    }
                }
            }
            .padding(Tokens.Spacing.lg)
        }
        .background(Tokens.Colors.adaptiveBackground)
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            name = user.name
            age = user.age.map(String.init) ?? ""
            sex = user.sex
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(Tokens.Fonts.microLabel)
            .tracking(Tokens.Tracking.microLabel)
            .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
    }
}
