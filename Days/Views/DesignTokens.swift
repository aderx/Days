import SwiftUI

enum ND {
    static func black(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "000000") : Color(hex: "F5F5F5")
    }

    static func surface(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "111111") : Color(hex: "FFFFFF")
    }

    static func surfaceRaised(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "1A1A1A") : Color(hex: "F0F0F0")
    }

    static func border(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "222222") : Color(hex: "E8E8E8")
    }

    static func borderVisible(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "333333") : Color(hex: "CCCCCC")
    }

    static func textDisabled(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "666666") : Color(hex: "999999")
    }

    static func textSecondary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "999999") : Color(hex: "666666")
    }

    static func textPrimary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "E8E8E8") : Color(hex: "1A1A1A")
    }

    static func textDisplay(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white : Color.black
    }

    static let accent = Color(hex: "D71921")
    static let success = Color(hex: "4A9E5C")
    static let warning = Color(hex: "D4A843")

    // MARK: - Adaptive panel chrome

    /// Translucent fill layered over the panel's material to lift it slightly.
    static func panelChromeFill(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.24)
    }

    /// Hairline stroke around the floating panel / popovers.
    static func panelStroke(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.14)
    }

    // MARK: - Calendar surfaces

    /// Default day-cell background (a faint card on the frosted panel).
    static func dayFill(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.045) : Color.white.opacity(0.46)
    }

    /// Slightly stronger fill used for observance / neutral-but-marked days.
    static func dayFillStrong(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.07) : Color.white.opacity(0.6)
    }

    /// Subtle shaded band for Saturday/Sunday columns so the weekend stands out.
    static func weekendFill(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.05)
    }

    /// Hairline divider for data-dense groupings.
    static func divider(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.07)
    }

    /// Shared hover wash — neutral, adapts to appearance via `Color.primary`.
    static let hoverWash = Color.primary.opacity(0.08)
    static let hoverWashStrong = Color.primary.opacity(0.14)
}

extension Font {
    static func ndDisplay(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }

    static func ndBody(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    static func ndMono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    /// Instrument-panel label — Space Mono caps. Pair with `.tracking(0.8)` + `.uppercased()`.
    static func ndLabel(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }
}

extension View {
    /// A Nothing-style ALL-CAPS monospace label with mechanical tracking.
    func ndLabelStyle() -> some View {
        self.font(.ndLabel())
            .tracking(0.9)
            .textCase(.uppercase)
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var value: UInt64 = 0
        scanner.scanHexInt64(&value)

        let red = Double((value & 0xFF0000) >> 16) / 255.0
        let green = Double((value & 0x00FF00) >> 8) / 255.0
        let blue = Double(value & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }
}

