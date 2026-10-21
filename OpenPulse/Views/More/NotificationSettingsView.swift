import SwiftUI

struct NotificationSettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @StateObject private var permissions = PermissionsManager()

    var body: some View {
        Form {
            Section {
                Toggle("Allow reminders", isOn: $settings.notificationsEnabled)
                    .onChange(of: settings.notificationsEnabled) { _, enabled in
                        if enabled {
                            permissions.requestNotifications { granted in
                                if granted { NotificationManager.shared.scheduleAllNotifications(settings: settings) }
                            }
                        } else {
                            reschedule()
                        }
                    }
            }

            if settings.notificationsEnabled {
                Section {
                    Toggle("Morning heart check", isOn: $settings.morningCheckEnabled)
                    if settings.morningCheckEnabled {
                        DatePicker("Time", selection: $settings.morningTime, displayedComponents: .hourAndMinute)
                    }
                }
                Section {
                    Toggle("Evening breathing", isOn: $settings.eveningBreathingEnabled)
                    if settings.eveningBreathingEnabled {
                        DatePicker("Time", selection: $settings.eveningTime, displayedComponents: .hourAndMinute)
                    }
                }
                Section {
                    Toggle("Weekly insights", isOn: $settings.weeklyInsightEnabled)
                }
            }
        }
        .tint(Tokens.Colors.statusGood)
        .scrollContentBackground(.hidden)
        .background(Tokens.Colors.adaptiveBackground)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: settings.morningCheckEnabled) { _, _ in reschedule() }
        .onChange(of: settings.morningTime) { _, _ in reschedule() }
        .onChange(of: settings.eveningBreathingEnabled) { _, _ in reschedule() }
        .onChange(of: settings.eveningTime) { _, _ in reschedule() }
        .onChange(of: settings.weeklyInsightEnabled) { _, _ in reschedule() }
    }

    private func reschedule() {
        NotificationManager.shared.scheduleAllNotifications(settings: settings)
    }
}
