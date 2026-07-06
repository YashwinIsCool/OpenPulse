import SwiftUI

struct SegmentedToggle: View {
    let options: [String]
    @Binding var selection: String

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                Text(option)
                    .font(Tokens.Fonts.body)
                    .foregroundStyle(selection == option ? Tokens.Colors.primaryRed : Tokens.Colors.adaptiveTextTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Tokens.Spacing.sm)
                    .background(
                        Group {
                            if selection == option {
                                RoundedRectangle(cornerRadius: Tokens.Radius.segmentedToggle - 2, style: .continuous)
                                    .fill(Tokens.Colors.adaptiveCard)
                            }
                        }
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.15)) { selection = option }
                    }
            }
        }
        .padding(Tokens.Padding.segmentedToggle)
        .background(Tokens.Colors.adaptiveLightRedTint)
        .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.segmentedToggle, style: .continuous))
    }
}
