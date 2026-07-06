import SwiftUI
import SwiftData

struct ProfileSetupView: View {
    let onComplete: () -> Void

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: AppSettings
    @Query private var users: [User]
    @StateObject private var permissions = PermissionsManager()

    @State private var name: String = ""
    @State private var age: String = ""
    @State private var sex: BiologicalSex = .preferNotToSay
    @State private var notificationsOptIn: Bool = true

    var body: some View {
        VStack(spacing: Tokens.Spacing.xl) {
            VStack(spacing: Tokens.Spacing.xs) {
                Text("Just the basics")
                    .font(Tokens.Fonts.pageTitle)
                    .tracking(Tokens.Tracking.pageTitle)
                    .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                Text("Everything here is optional and stays on your device.")
                    .font(Tokens.Fonts.body)
                    .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, Tokens.Spacing.xxl)

            ScrollView {
                VStack(spacing: Tokens.Spacing.md) {
                    Card {
                        VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
                            fieldLabel("First name")
                            TextField("Optional", text: $name)
                                .font(Tokens.Fonts.body)
                                .textInputAutocapitalization(.words)
                        }
                    }

                    Card {
                        VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
                            fieldLabel("Age")
                            TextField("Optional", text: $age)
                                .font(Tokens.Fonts.body)
                                .keyboardType(.numberPad)
                        }
                    }

                    Card {
                        VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
                            fieldLabel("Sex assigned at birth")
                            Text("Helps calibrate normal heart-rate ranges.")
                                .font(Tokens.Fonts.caption)
                                .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                            Picker("Sex", selection: $sex) {
                                ForEach(BiologicalSex.allCases, id: \.self) { option in
                                    Text(option.rawValue).tag(option)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    Card {
                        Toggle(isOn: $notificationsOptIn) {
                            VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
                                Text("Daily reminders")
                                    .font(Tokens.Fonts.cardTitle)
                                    .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                                Text("Morning heart checks, evening breathing, weekly insights.")
                                    .font(Tokens.Fonts.caption)
                                    .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                            }
                        }
                        .tint(Tokens.Colors.primaryRed)
                    }
                }
                .padding(.horizontal, Tokens.Spacing.xl)
            }

            PrimaryButton(title: "Complete Setup", icon: "checkmark", action: completeSetup)
                .padding(.horizontal, Tokens.Spacing.xl)
                .padding(.bottom, Tokens.Spacing.xl)
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(Tokens.Fonts.microLabel)
            .tracking(Tokens.Tracking.microLabel)
            .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
    }

    private func completeSetup() {
        let user = users.first ?? {
            let newUser = User()
            modelContext.insert(newUser)
            return newUser
        }()

        user.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        user.age = Int(age)
        user.sex = sex

        settings.notificationsEnabled = notificationsOptIn
        if notificationsOptIn {
            permissions.requestNotifications { granted in
                if granted {
                    NotificationManager.shared.scheduleAllNotifications(settings: settings)
                }
            }
        }

        onComplete()
    }
}
