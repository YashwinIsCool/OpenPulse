import SwiftUI

/// Central design-system constants. Every screen references these — never hardcode
/// colors, fonts, spacing, or corner radii inline.
enum Tokens {

    enum Colors {
        static let primaryRed = Color(hex: 0xDC2626)
        static let primaryRedDark = Color(hex: 0xB91C1C)
        static let lightRedTint = Color(hex: 0xFEE2E2)
        static let softRedSurface = Color(hex: 0xFEF2F2)
        static let appBackground = Color(hex: 0xFAFBFC)
        static let cardWhite = Color.white
        static let border = Color(hex: 0xE8ECF4)

        static let textPrimary = Color(hex: 0x0F172A)
        static let textSecondary = Color(hex: 0x475569)
        static let textTertiary = Color(hex: 0x64748B)
        static let textQuaternary = Color(hex: 0x94A3B8)

        static let successGreen = Color(hex: 0x16A34A)
        static let successBg = Color(hex: 0xDCFCE7)
        static let warningAmber = Color(hex: 0xF59E0B)
        static let warningBg = Color(hex: 0xFEF3C7)
        static let dangerDark = Color(hex: 0x991B1B)

        static let chartLineRed = Color(hex: 0xDC2626)
        static let chartAreaFillTop = Color(hex: 0xDC2626).opacity(0.15)
        static let chartAreaFillBottom = Color(hex: 0xDC2626).opacity(0.0)

        // Dark-mode aware surface colors, used where the flat palette above
        // needs to invert grays while keeping red as the constant primary.
        static let adaptiveBackground = Color(light: 0xFAFBFC, dark: 0x0B0F14)
        static let adaptiveCard = Color(light: 0xFFFFFF, dark: 0x151A21)
        static let adaptiveBorder = Color(light: 0xE8ECF4, dark: 0x262E38)
        static let adaptiveTextPrimary = Color(light: 0x0F172A, dark: 0xF1F5F9)
        static let adaptiveTextSecondary = Color(light: 0x475569, dark: 0xCBD5E1)
        static let adaptiveTextTertiary = Color(light: 0x64748B, dark: 0x94A3B8)
        static let adaptiveTextQuaternary = Color(light: 0x94A3B8, dark: 0x64748B)
        static let adaptiveSoftRedSurface = Color(light: 0xFEF2F2, dark: 0x2A1416)
        static let adaptiveLightRedTint = Color(light: 0xFEE2E2, dark: 0x3A1A1D)

        // Neutral "ink" for primary actions. Red is reserved for the brand mark and
        // for flagged readings, so it keeps its meaning in a health app.
        static let ink = Color(light: 0x0F172A, dark: 0xF1F5F9)
        static let onInk = Color(light: 0xFFFFFF, dark: 0x0B0F14)

        // Reading-status text colors, dark enough to read on white (and light
        // enough on dark). Only used where the color means something.
        static let statusGood = Color(light: 0x15803D, dark: 0x4ADE80)
        static let statusWatch = Color(light: 0xB45309, dark: 0xFBBF24)
        static let statusFlag = Color(light: 0xB91C1C, dark: 0xF87171)
    }

    enum Fonts {
        static let display = Font.system(size: 32, weight: .bold, design: .default)
        static let pageTitle = Font.system(size: 22, weight: .bold)
        static let sectionHeading = Font.system(size: 18, weight: .bold)
        static let cardTitle = Font.system(size: 15, weight: .semibold)
        static let body = Font.system(size: 13, weight: .medium)
        static let caption = Font.system(size: 11, weight: .medium)
        static let microLabel = Font.system(size: 11, weight: .semibold)

        // Larger, Dynamic Type-aware styles for the simplified screens — they grow
        // with the user's iPhone text size, which matters for older users.
        static let screenTitle = Font.system(.title, weight: .bold)
        static let headline = Font.system(.title3, weight: .semibold)
        static let bodyText = Font.system(.body)
        static let secondaryText = Font.system(.subheadline)
        static let readingNumber = Font.system(size: 72, weight: .semibold).monospacedDigit()
    }

    enum Tracking {
        static let display: CGFloat = -0.5
        static let pageTitle: CGFloat = -0.3
        static let microLabel: CGFloat = 0.5
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
    }

    enum Radius {
        static let card: CGFloat = 14
        static let hero: CGFloat = 20
        static let statTile: CGFloat = 12
        static let button: CGFloat = 12
        static let segmentedToggle: CGFloat = 12
    }

    enum Padding {
        static let card: CGFloat = 14
        static let hero: CGFloat = 18
        static let statTile: CGFloat = 10
        static let button: CGFloat = 13
        static let segmentedToggle: CGFloat = 4
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }

    /// A color that resolves to `light` in light mode and `dark` in dark mode.
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor(light: UIColor(Color(hex: light)), dark: UIColor(Color(hex: dark))))
    }
}

extension UIColor {
    convenience init(light: UIColor, dark: UIColor) {
        self.init { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        }
    }
}
