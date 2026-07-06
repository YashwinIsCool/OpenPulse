import SwiftUI

struct NotificationSettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @StateObject private var permissions = PermissionsManager()

    var body: some View {
        ScrollView {
            VStack(spacing: Tokens.Spacing.md) {
                Card {
                    Toggle("Enable notifications", isOn: $settings.notificationsEnabled)
                        .font(Tokens.Fonts.cardTitle)
                        .tint(Tokens.Colors.primaryRed)
                        .onChange(of: settings.notificationsEnabled) { _, enabled in
                            if enabled {
                                permissions.requestNotifications { granted in
                                    if granted { NotificationManager.shared.scheduleAllNotifications(settings: settings) }
                                }
                            } else {
                                NotificationManager.shared.scheduleAllNotifications(settings: settings)
                            }
                        }
                }

                Card {
                    VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
                        Toggle("Morning heart check", isOn: $settings.morningCheckEnabled)
                            .tint(Tokens.Colors.primaryRed)
                        DatePicker("Time", selection: $settings.morningTime, displayedComponents: .hourAndMinute)
                    }
                    .font(Tokens.Fonts.body)
                    .onChange(of: settings.morningCheckEnabled) { _, _ in reschedule() }
                    .onChange(of: settings.morningTime) { _, _ in reschedule() }
                }

                Card {
                    VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
                        Toggle("Evening breathing", isOn: $settings.eveningBreathingEnabled)
                            .tint(Tokens.Colors.primaryRed)
                        DatePicker("Time", selection: $settings.eveningTime, displayedComponents: .hourAndMinute)
                    }
                    .font(Tokens.Fonts.body)
                    .onChange(of: settings.eveningBreathingEnabled) { _, _ in reschedule() }
                    .onChange(of: settings.eveningTime) { _, _ in reschedule() }
                }

                Card {
                    Toggle("Weekly insight", isOn: $settings.weeklyInsightEnabled)
                        .font(Tokens.Fonts.body)
                        .tint(Tokens.Colors.primaryRed)
                        .onChange(of: settings.weeklyInsightEnabled) { _, _ in reschedule() }
                }
            }
            .padding(Tokens.Spacing.lg)
        }
        .background(Tokens.Colors.adaptiveBackground)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func reschedule() {
        NotificationManager.shared.scheduleAllNotifications(settings: settings)
    }
}
