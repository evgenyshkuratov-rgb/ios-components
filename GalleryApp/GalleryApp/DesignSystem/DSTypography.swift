import UIKit

// MARK: - DSTextStyle

/// A text style from the Frisbee design system (Roboto font family).
/// Captures font, line height, and letter spacing from the Figma type system.
struct DSTextStyle {
    let font: UIFont
    let lineHeight: CGFloat
    let letterSpacing: CGFloat

    /// Applies full text style to a UILabel, including line height and letter spacing.
    /// Call again after changing label text.
    func apply(to label: UILabel, text: String? = nil) {
        let content = text ?? label.text ?? ""
        label.font = font

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight
        paragraphStyle.lineBreakMode = label.lineBreakMode
        paragraphStyle.alignment = label.textAlignment

        var attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle,
            .baselineOffset: (lineHeight - font.lineHeight) / 4
        ]

        if letterSpacing != 0 {
            attributes[.kern] = letterSpacing
        }

        if let color = label.textColor {
            attributes[.foregroundColor] = color
        }

        label.attributedText = NSAttributedString(string: content, attributes: attributes)
    }
}

// MARK: - DSTypography

/// Text styles from the Figma design system (used subset only).
/// Font: Roboto (variable).
/// Use `style.font` for simple UIFont access, or `style.apply(to:)` for full fidelity.
enum DSTypography {

    // MARK: - Font Helpers

    private static func roboto(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let systemFont = UIFont.systemFont(ofSize: size, weight: weight)
        let descriptor = systemFont.fontDescriptor.withFamily("Roboto")
        let font = UIFont(descriptor: descriptor, size: size)
        if font.familyName == "Roboto" { return font }
        return systemFont
    }

    // MARK: - Titles

    /// Title 1 — Bold 32pt, line 40, spacing 0.11
    static let title1B = DSTextStyle(font: roboto(size: 32, weight: .bold), lineHeight: 40, letterSpacing: 0.11)

    // MARK: - Subtitles

    /// Subtitle 1 — Medium 18pt, line 24
    static let subtitle1M = DSTextStyle(font: roboto(size: 18, weight: .medium), lineHeight: 24, letterSpacing: 0)

    // MARK: - Body

    /// Body 1 — Regular 16pt, line 20
    static let body1R = DSTextStyle(font: roboto(size: 16, weight: .regular), lineHeight: 20, letterSpacing: 0)

    /// Body 3 — Medium 16pt, line 22
    static let body3M = DSTextStyle(font: roboto(size: 16, weight: .medium), lineHeight: 22, letterSpacing: 0)

    // MARK: - Subheads

    /// Subhead 2 — Regular 14pt, line 20
    static let subhead2R = DSTextStyle(font: roboto(size: 14, weight: .regular), lineHeight: 20, letterSpacing: 0)

    /// Subhead 3 — Regular 13pt, line 16
    static let subhead3R = DSTextStyle(font: roboto(size: 13, weight: .regular), lineHeight: 16, letterSpacing: 0)

    /// Subhead 4 — Medium 14pt, line 20
    static let subhead4M = DSTextStyle(font: roboto(size: 14, weight: .medium), lineHeight: 20, letterSpacing: 0)
}
