import UIKit

enum DSColors {

    static let backgroundBase = dynamicColor(light: "#FFFFFF", dark: "#1A1A1A")
    static let backgroundSecond = dynamicColor(light: "#F5F5F5", dark: "#313131")
    static let backgroundSheet = dynamicColor(light: "#FFFFFF", dark: "#232325")

    static let textPrimary = dynamicColor(light: "#000000", dark: "#FFFFFF")
    static let textSecondary = dynamicColor(light: "#00000080", dark: "#FFFFFF80")
    static let textTertiary = dynamicColor(light: "#0000004d", dark: "#FFFFFF4d")

    static let separator = dynamicColor(light: "#0000001a", dark: "#FFFFFF1a")
    static let chipBackground = dynamicColor(light: "#00000014", dark: "#FFFFFF14")
    static let subtleBackground = dynamicColor(light: "#0000000f", dark: "#FFFFFF0f")

    static let successDefault = dynamicColor(light: "#40B259", dark: "#40B259")
    static let dangerDefault = dynamicColor(light: "#E06141", dark: "#E06141")
    static let warningDefault = dynamicColor(light: "#DC9B1C", dark: "#DC9B1C")

    static let white100 = UIColor.white
    static let badgeMuted = dynamicColor(light: "#C9C9C9", dark: "#484848")

    // MARK: - Helpers

    private static func dynamicColor(light: String, dark: String) -> UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        }
    }
}

extension UIColor {
    convenience init(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexString.hasPrefix("#") { hexString.removeFirst() }

        var rgba: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgba)

        let r, g, b, a: CGFloat
        if hexString.count == 8 {
            r = CGFloat((rgba >> 24) & 0xFF) / 255
            g = CGFloat((rgba >> 16) & 0xFF) / 255
            b = CGFloat((rgba >> 8) & 0xFF) / 255
            a = CGFloat(rgba & 0xFF) / 255
        } else {
            r = CGFloat((rgba >> 16) & 0xFF) / 255
            g = CGFloat((rgba >> 8) & 0xFF) / 255
            b = CGFloat(rgba & 0xFF) / 255
            a = 1.0
        }
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}
