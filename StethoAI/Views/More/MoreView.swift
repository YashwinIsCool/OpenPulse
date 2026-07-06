import SwiftUI

struct MoreView: View {
    let user: User
    @State private var isSharePresented = false
    @State private var isFeedbackPresented = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Tokens.Spacing.xl) {
                    Text("More")
                        .font(Tokens.Fonts.pageTitle)
                        .tracking(Tokens.Tracking.pageTitle)
                        .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                        .padding(.top, Tokens.Spacing.sm)

                    section(title: "Profile") {
                        navRow(icon: "person.fill", title: "Account") { AccountView(user: user) }
                    }

                    section(title: "Preferences") {
                        navRow(icon: "bell.fill", title: "Notifications") { NotificationSettingsView() }
                    }

                    section(title: "Learn") {
                        navRow(icon: "book.fill", title: "Heart health basics") { EducationLibraryView() }
                    }

                    section(title: "About") {
                        navRow(icon: "info.circle.fill", title: "About StethoAI") { AboutView() }
                        navRow(icon: "doc.text.fill", title: "Privacy Policy & Terms") { PrivacyPolicyView() }
                    }

                    section(title: "Support") {
                        actionRow(icon: "square.and.arrow.up", title: "Share StethoAI") { isSharePresented = true }
                        actionRow(icon: "envelope.fill", title: "Send Feedback") { isFeedbackPresented = true }
                    }

                    Text("StethoAI is a wellness and education tool. It is not a medical device and does not diagnose conditions.")
                        .font(Tokens.Fonts.caption)
                        .foregroundStyle(Tokens.Colors.adaptiveTextQuaternary)
                        .padding(.top, Tokens.Spacing.sm)
                }
                .padding(Tokens.Spacing.lg)
            }
            .background(Tokens.Colors.adaptiveBackground)
            .sheet(isPresented: $isSharePresented) {
                ShareSheet(items: ["Check out StethoAI — an AI-powered heart wellness companion.", URL(string: "https://apps.apple.com")].compactMap { $0 })
            }
            .sheet(isPresented: $isFeedbackPresented) {
                ShareSheet(items: ["StethoAI feedback: "])
            }
        }
    }

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
            Text(title.uppercased())
                .font(Tokens.Fonts.microLabel)
                .tracking(Tokens.Tracking.microLabel)
                .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
            VStack(spacing: Tokens.Spacing.sm) {
                content()
            }
        }
    }

    private func navRow<Destination: View>(icon: String, title: String, @ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink(destination: destination()) {
            Card {
                rowContent(icon: icon, title: title, showsChevron: true)
            }
        }
        .buttonStyle(.plain)
    }

    private func actionRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Card {
                rowContent(icon: icon, title: title, showsChevron: false)
            }
        }
        .buttonStyle(.plain)
    }

    private func rowContent(icon: String, title: String, showsChevron: Bool) -> some View {
        HStack(spacing: Tokens.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Tokens.Colors.primaryRed)
                .frame(width: 32, height: 32)
                .background(Tokens.Colors.adaptiveSoftRedSurface)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text(title)
                .font(Tokens.Fonts.cardTitle)
                .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
            Spacer()
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Tokens.Colors.adaptiveTextQuaternary)
            }
        }
    }
}
