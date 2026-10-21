import SwiftUI

struct OnboardingContainerView: View {
    let onComplete: () -> Void
    @State private var step: Int = 0
    @StateObject private var permissions = PermissionsManager()

    var body: some View {
        ZStack {
            Tokens.Colors.adaptiveBackground.ignoresSafeArea()

            switch step {
            case 0:
                WelcomeView(onNext: { withAnimation { step = 1 } })
            case 1:
                PermissionsView(permissions: permissions, onNext: { withAnimation { step = 2 } })
            default:
                ProfileSetupView(onComplete: onComplete)
            }
        }
    }
}
