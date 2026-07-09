import Foundation

/// One route to real care shown in the "Where to get care" pathway.
///
/// This is the product side of our first commitment: never flag someone without a
/// pathway to care. Each deployment (a specific health camp, region, or partner)
/// should replace `CareResources.forDeployment` with the actual local resources —
/// the nearest health centre, the partner hospital, the community health worker's
/// number — verified by the on-the-ground clinical partner before any screening.
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
    /// The active resource list for the current deployment.
    ///
    /// The defaults below are illustrative pathways for an India pilot. They are
    /// starting points, NOT verified for any specific location — a clinical partner
    /// must confirm and localize them before a real screening.
    static var forDeployment: [CareResource] { indiaPilotDefaults }

    private static let indiaPilotDefaults: [CareResource] = [
        CareResource(
            icon: "cross.case.fill",
            title: "Nearest government health centre",
            detail: "Primary Health Centres (PHCs) and Community Health Centres offer free or low-cost check-ups. A health worker can measure your blood pressure and refer you further if needed.",
            action: .info,
            actionLabel: nil
        ),
        CareResource(
            icon: "indianrupeesign.circle.fill",
            title: "Ayushman Bharat (PM-JAY)",
            detail: "A government scheme that covers free hospital care for eligible families. Many people who qualify don't know they're eligible — ask a health worker to help you check.",
            action: .website("https://pmjay.gov.in"),
            actionLabel: "Learn about eligibility"
        ),
        CareResource(
            icon: "person.2.fill",
            title: "Your community health worker (ASHA)",
            detail: "ASHA workers can guide you to the right care, help with government schemes, and follow up with you locally.",
            action: .info,
            actionLabel: nil
        ),
        CareResource(
            icon: "stethoscope",
            title: "Partner clinic / health camp",
            detail: "If you were screened at a StethoAI health camp, the clinician there can review your reading and tell you the next step. Show them your saved heart record.",
            action: .info,
            actionLabel: nil
        ),
        CareResource(
            icon: "phone.fill",
            title: "Emergency",
            detail: "If you have chest pain, trouble breathing, fainting, or feel very unwell right now, seek help immediately.",
            action: .call("108"),
            actionLabel: "Call 108 (ambulance)"
        )
    ]
}
