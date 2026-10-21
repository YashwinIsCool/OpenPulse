import SwiftUI

struct AboutView: View {

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
                    Image(systemName: "waveform.path.ecg.rectangle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Tokens.Colors.primaryRed)
                    Text(AppInfo.name)
                        .font(Tokens.Fonts.screenTitle)
                        .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                    Text("Version \(AppInfo.version)")
                        .font(Tokens.Fonts.secondaryText)
                        .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                }
                .padding(.vertical, Tokens.Spacing.sm)
            }

            Section("What it does") {
                Text("A free heart check that uses your phone's camera to measure your heart rate, keeps a record you can show a doctor, and points you to care when a reading looks unusual.")
            }

            Section("How it works") {
                Text("Each heartbeat pushes a little more blood into your fingertip, which absorbs a little more of the flash's light. The camera records those tiny brightness changes, and signal processing turns them into your heart rate.")
                Text("A small machine-learning model, trained only on your own readings and check-ins on this phone, learns what's usual for you. Nothing is uploaded.")
            }

            Section("Not a medical device") {
                Text("This app is for wellness and education. It is not FDA-approved, does not diagnose any condition, and never replaces a doctor.")
            }
        }
        .font(Tokens.Fonts.bodyText)
        .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Tokens.Colors.adaptiveBackground)
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
