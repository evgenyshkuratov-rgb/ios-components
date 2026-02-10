import UIKit
import Components

enum DSBrand: String, CaseIterable {
    case frisbee = "Frisbee"
    case tdm = "TDM"
    case sover = "Sover"
    case kchat = "KCHAT"
    case senseNew = "Sense New"

    // MARK: - Color Cache

    private struct ColorKey: Hashable {
        let brand: DSBrand
        let style: UIUserInterfaceStyle
        let slot: UInt8
    }

    private static var colorCache: [ColorKey: UIColor] = [:]

    private static func cached(_ brand: DSBrand, _ style: UIUserInterfaceStyle, _ slot: UInt8, _ make: () -> UIColor) -> UIColor {
        let key = ColorKey(brand: brand, style: style, slot: slot)
        if let hit = colorCache[key] { return hit }
        let color = make()
        colorCache[key] = color
        return color
    }

    // MARK: - Accent Colors (ThemeFirst/Primary/Default)

    func accentColor(for style: UIUserInterfaceStyle) -> UIColor {
        DSBrand.cached(self, style, 0) {
            switch self {
            case .frisbee:   return UIColor(hex: "#40B259")
            case .tdm:       return UIColor(hex: style == .dark ? "#3886E1" : "#3E87DD")
            case .sover:     return UIColor(hex: style == .dark ? "#C4944D" : "#C7964F")
            case .kchat:     return UIColor(hex: style == .dark ? "#E9474E" : "#EA5355")
            case .senseNew:  return UIColor(hex: "#7548AD")
            }
        }
    }

    // MARK: - Background Colors

    func backgroundBase(for style: UIUserInterfaceStyle) -> UIColor {
        DSBrand.cached(self, style, 1) {
            if style == .dark {
                switch self {
                case .sover:    return UIColor(hex: "#101D2E")
                case .senseNew: return UIColor(hex: "#161419")
                default:        return UIColor(hex: "#1A1A1A")
                }
            }
            return UIColor(hex: "#FFFFFF")
        }
    }

    func backgroundSecond(for style: UIUserInterfaceStyle) -> UIColor {
        DSBrand.cached(self, style, 2) {
            if style == .dark {
                switch self {
                case .sover:    return UIColor(hex: "#1C2838")
                case .senseNew: return UIColor(hex: "#2A282E")
                default:        return UIColor(hex: "#313131")
                }
            }
            return UIColor(hex: "#F5F5F5")
        }
    }

    // MARK: - Basic Colors (same across all brands)

    func basicColor8(for style: UIUserInterfaceStyle) -> UIColor {
        DSBrand.cached(self, style, 3) {
            style == .dark ? UIColor(hex: "#FFFFFF14") : UIColor(hex: "#00000014")
        }
    }

    func basicColor90(for style: UIUserInterfaceStyle) -> UIColor {
        DSBrand.cached(self, style, 4) {
            style == .dark ? UIColor(hex: "#FFFFFFe5") : UIColor(hex: "#000000e5")
        }
    }

    func basicColor50(for style: UIUserInterfaceStyle) -> UIColor {
        DSBrand.cached(self, style, 5) {
            style == .dark ? UIColor(hex: "#FFFFFF80") : UIColor(hex: "#00000080")
        }
    }

    // MARK: - ChipsView Integration

    func chipsColorScheme(for style: UIUserInterfaceStyle) -> ChipsColorScheme {
        ChipsColorScheme(
            backgroundDefault: basicColor8(for: style),
            backgroundActive: accentColor(for: style),
            textPrimary: basicColor90(for: style),
            closeIconTint: basicColor50(for: style)
        )
    }
}
