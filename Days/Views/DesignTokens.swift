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

