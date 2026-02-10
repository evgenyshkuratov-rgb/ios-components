import UIKit

enum DSColors {

    static let backgroundBase = dynamicColor(light: "#FFFFFF", dark: "#1A1A1A")
    static let backgroundSecond = dynamicColor(light: "#F5F5F5", dark: "#313131")
    static let backgroundSheet = dynamicColor(light: "#FFFFFF", dark: "#232325")

    static let textPrimary = dynamicColor(light: "#000000", dark: "#FFFFFF")
    static let textSecondary = dynamicColor(light: "#00000080", dark: "#FFFFFF80")
    static let textTertiary = dynamicColor(light: "#0000004d", dark: "#FFFFFF4d")

    static let chipBackground = dynamicColor(light: "#00000014", dark: "#FFFFFF14")

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
