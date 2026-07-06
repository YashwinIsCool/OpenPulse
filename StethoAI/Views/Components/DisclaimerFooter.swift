import SwiftUI

/// Required on every result screen per regulatory guidance — this is a wellness
/// app, not a diagnostic device.
struct DisclaimerFooter: View {
    var text: String = "For educational and informational use only. Not medical advice. Consult a healthcare provider."

    var body: some View {
        Text(text)
            .font(Tokens.Fonts.caption)
            .foregroundStyle(Tokens.Colors.adaptiveTextQuaternary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }
}

/// Shown when a result is flagged as possible-murmur or abnormal.
struct ConsultDoctorCTA: View {
    var body: some View {
        SecondaryButton(title: "Find a Doctor", icon: "stethoscope") {
            if let url = URL(string: "https://www.google.com/maps/search/cardiologist+near+me") {
                UIApplication.shared.open(url)
            }
        }
    }
}
