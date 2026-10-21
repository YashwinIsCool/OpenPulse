import SwiftUI

/// One route to care (title, explanation, and a call or link if it has one). Used
/// on the result screen for flagged readings and on the "Where to get care" screen.
/// Put rows inside a ListCard, separated by ListDivider.
struct CareResourceRow: View {
    let resource: CareResource
    @ObservedObject private var loc = Localizer.shared

    var body: some View {
        HStack(alignment: .top, spacing: Tokens.Spacing.md) {
            Image(systemName: resource.icon)
                .font(.system(size: 17))
                .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                .frame(width: 24)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
                Text(loc.t(resource.title))
                    .font(Tokens.Fonts.bodyText.weight(.semibold))
                    .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                Text(loc.t(resource.detail))
                    .font(Tokens.Fonts.secondaryText)
                    .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                action
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private var action: some View {
        switch resource.action {
        case .call(let number):
            Button {
                if let url = URL(string: "tel://\(number.filter { $0.isNumber })") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("\(loc.t(resource.actionLabel ?? "Call")) (\(number))", systemImage: "phone.fill")
                    .font(Tokens.Fonts.secondaryText.weight(.semibold))
                    .foregroundStyle(Tokens.Colors.statusFlag)
            }
            .padding(.top, 2)
        case .website(let urlString):
            Button {
                if let url = URL(string: urlString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label(loc.t(resource.actionLabel ?? "Learn more"), systemImage: "arrow.up.right.square")
                    .font(Tokens.Fonts.secondaryText.weight(.semibold))
                    .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
            }
            .padding(.top, 2)
        case .info:
            EmptyView()
        }
    }
}
