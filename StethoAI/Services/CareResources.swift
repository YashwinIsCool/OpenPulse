import Foundation

/// One route to real care shown in the "Where to get care" pathway.
///
/// This is the product side of our first commitment: never flag someone without a
/// pathway to care. The defaults are general starting points that apply in most
/// countries; a specific deployment can replace `CareResources.forDeployment` with
/// verified local resources.
struct CareResource: Identifiable {
    enum Action {
        case call(String)        // phone number
        case website(String)     // URL string
        case info                // guidance only, no link
    }

    let id = UUID()
    let icon: String
    let title: String
    let detail: String
    let action: Action
    let actionLabel: String?
}

enum CareResources {
    /// The active resource list.
    static var forDeployment: [CareResource] { general }

    private static var general: [CareResource] {
        [
            CareResource(
                icon: "cross.case.fill",
                title: "A local clinic or health center",
                detail: "Many communities have public or community health centers with free or low-cost check-ups. A nurse or health worker can check your blood pressure and refer you if needed.",
                action: .info,
                actionLabel: nil
            ),
            CareResource(
                icon: "stethoscope",
                title: "A doctor or pharmacist",
                detail: "If you have a doctor, show them your readings. Many pharmacists can check your blood pressure for free and tell you where to go next.",
                action: .info,
                actionLabel: nil
            ),
            CareResource(
                icon: "phone.bubble.fill",
                title: "A nurse or health advice line",
                detail: "Many countries have a free phone line where a nurse can tell you how urgent things are and where to go. Search for your country's health advice line.",
                action: .info,
                actionLabel: nil
            ),
            CareResource(
                icon: "doc.text.fill",
                title: "Bring your heart record",
                detail: "In the History tab, tap Share with a doctor to make a one-page record of your readings, so a clinician sees the pattern, not just one number.",
                action: .info,
                actionLabel: nil
            ),
            CareResource(
                icon: "phone.fill",
                title: "Emergency",
                detail: "If you have chest pain, trouble breathing, fainting, or feel very unwell right now, seek help immediately.",
                action: .call(emergencyNumber),
                actionLabel: "Call emergency services"
            )
        ]
    }

    /// The emergency number for the phone's region. 112 is the fallback because
    /// mobile networks in most countries route it to local emergency services.
    static var emergencyNumber: String {
        switch Locale.current.region?.identifier {
        case "US", "CA", "MX", "PR", "PH": return "911"
        case "GB", "IE", "HK", "MY", "SG": return "999"
        case "AU": return "000"
        case "NZ": return "111"
        case "JP", "KR": return "119"
        default: return "112"
        }
    }
}
