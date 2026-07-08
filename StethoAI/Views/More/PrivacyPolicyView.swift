import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Spacing.lg) {
                Text("Privacy Policy & Terms of Service")
                    .font(Tokens.Fonts.pageTitle)
                    .tracking(Tokens.Tracking.pageTitle)
                    .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)

                group(
                    title: "Wellness, not diagnosis",
                    body: "StethoAI is intended for general wellness and educational purposes only. It is not a medical device, is not FDA-approved, and does not diagnose, treat, cure, or prevent any disease or medical condition."
                )

                group(
                    title: "Not a substitute for clinical care",
                    body: "StethoAI does not analyze or diagnose your heart sounds — it lets you record, save, and share them. Heart rate readings and recordings should never replace evaluation by a qualified healthcare provider. Always consult a doctor about any concerns regarding your heart."
                )

                group(
                    title: "Your data",
                    body: "All health data you record — heart rate readings, heart sound recordings, breathing sessions, and logs — is stored locally on your device. StethoAI does not upload your health data to any server without your explicit opt-in, and any such transfer would be encrypted."
                )

                group(
                    title: "No account required",
                    body: "StethoAI v1 does not require sign-in and does not sync data to the cloud. Deleting the app removes all locally stored data."
                )

                group(
                    title: "Acknowledgment",
                    body: "By using StethoAI, you acknowledge that the app is a wellness and education tool, that its outputs are informational only, and that you will seek professional medical advice for any health decisions."
                )
            }
            .padding(Tokens.Spacing.lg)
        }
        .background(Tokens.Colors.adaptiveBackground)
        .navigationTitle("Privacy & Terms")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func group(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
            Text(title)
                .font(Tokens.Fonts.cardTitle)
                .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
            Text(body)
                .font(Tokens.Fonts.body)
                .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
        }
    }
}
