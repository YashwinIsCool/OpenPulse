import SwiftUI

struct PrivacyPolicyView: View {
    private let sections: [(title: String, body: String)] = [
        ("Wellness, not diagnosis",
         "\(AppInfo.name) is for general wellness and education only. It is not a medical device, is not FDA-approved, and does not diagnose, treat, cure, or prevent any disease or condition."),
        ("Not a substitute for care",
         "Heart rate readings never replace a qualified healthcare provider. Always talk to a doctor about concerns with your heart."),
        ("Your data stays on your phone",
         "Readings, check-ins, and your profile are stored only on this device. The camera image is turned into brightness numbers on the phone; no photos or video are saved or uploaded. The personal heart model is trained on this phone and never leaves it."),
        ("No account",
         "There's no sign-in and no cloud sync. Deleting the app deletes all of its data."),
        ("Sharing is your choice",
         "Nothing is shared unless you choose to share it, for example sending your heart record PDF to a doctor."),
        ("Acknowledgment",
         "By using \(AppInfo.name), you accept that it's a wellness and education tool, that its results are informational only, and that you'll seek professional medical advice for health decisions.")
    ]

    var body: some View {
        List {
            ForEach(sections, id: \.title) { section in
                Section(section.title) {
                    Text(section.body)
                        .font(Tokens.Fonts.bodyText)
                        .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Tokens.Colors.adaptiveBackground)
        .navigationTitle("Privacy and terms")
        .navigationBarTitleDisplayMode(.inline)
    }
}
