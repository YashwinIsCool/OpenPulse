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

/// Opens the pathway-to-care screen — real, local, low-cost routes to care rather
/// than a generic "find a doctor" search.
struct ConsultDoctorCTA: View {
    @State private var showCare = false

    var body: some View {
        SecondaryButton(title: "See where to get care", icon: "cross.case.fill") {
            showCare = true
        }
        .sheet(isPresented: $showCare) {
            FindCareView()
        }
    }
}
