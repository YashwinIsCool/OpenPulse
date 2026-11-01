import SwiftUI

/// The Help tab: getting care first, then learning, then settings and about.
/// A standard iOS grouped list — familiar, and it never looks generated.
struct MoreView: View {
    let user: User
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var settings = AppSettings.shared
    @State private var isSharePresented = false
    @State private var isFeedbackPresented = false
    @State private var isCarePresented = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button { isCarePresented = true } label: {
                        row(icon: "cross.case", title: "Where to get care", subtitle: "Free and low-cost places to start")
                    }
                    NavigationLink { EducationLibraryView() } label: {
                        row(icon: "book", title: "Heart health basics", subtitle: nil)
                    }
                }

                Section("Settings") {
                    NavigationLink { AccountView(user: user) } label: {
                        row(icon: "person", title: "Account", subtitle: nil)
                    }
                    NavigationLink { NotificationSettingsView() } label: {
                        row(icon: "bell", title: "Notifications", subtitle: nil)
                    }
                    Picker(selection: $settings.appearance) {
                        ForEach(Appearance.allCases) { Text($0.title).tag($0) }
                    } label: {
                        row(icon: "circle.lefthalf.filled", title: "Appearance", subtitle: nil)
                    }
                }

                Section("About") {
                    NavigationLink { AboutView() } label: {
                        row(icon: "info.circle", title: "About OpenPulse", subtitle: nil)
                    }
                    NavigationLink { PrivacyPolicyView() } label: {
                        row(icon: "lock", title: "Privacy and terms", subtitle: nil)
                    }
                    Button { isSharePresented = true } label: {
                        row(icon: "square.and.arrow.up", title: "Share OpenPulse", subtitle: nil)
                    }
                    Button { isFeedbackPresented = true } label: {
                        row(icon: "envelope", title: "Send feedback", subtitle: nil)
                    }
                }

                // Debug builds only: turning demo data off wipes every reading,
                // so real users must never see this switch.
                #if DEBUG
                Section {
                    Toggle(isOn: Binding(
                        get: { settings.isDemoMode },
                        set: { on in
                            settings.isDemoMode = on
                            if on { HeartSampleData.seed(context: modelContext, user: user) }
                            else { HeartSampleData.clear(context: modelContext, user: user) }
                        }
                    )) {
                        row(icon: "wand.and.stars", title: "Demo data", subtitle: "Replaces all data with samples for screenshots")
                    }
                } header: {
                    Text("Developer")
                }
                #endif

                Section {
                } footer: {
                    Text("OpenPulse is a wellness and education tool. It is not a medical device and does not diagnose conditions.")
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Tokens.Colors.adaptiveBackground)
            .navigationTitle("Help")
            .sheet(isPresented: $isSharePresented) {
                ShareSheet(items: ["OpenPulse — a free heart check using just your phone's camera.", URL(string: "https://apps.apple.com")].compactMap { $0 })
            }
            .sheet(isPresented: $isFeedbackPresented) {
                ShareSheet(items: ["OpenPulse feedback: "])
            }
            .sheet(isPresented: $isCarePresented) {
                FindCareView()
            }
        }
    }

    private func row(icon: String, title: String, subtitle: String?) -> some View {
        HStack(spacing: Tokens.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Tokens.Fonts.bodyText)
                    .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(Tokens.Fonts.secondaryText)
                        .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
