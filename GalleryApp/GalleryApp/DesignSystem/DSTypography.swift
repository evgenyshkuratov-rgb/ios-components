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

/// All text styles from the Figma design system.
/// Font: Roboto (variable), Roboto Mono (variable).
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

    private static func robotoMono(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let systemFont = UIFont.systemFont(ofSize: size, weight: weight)
        let descriptor = systemFont.fontDescriptor.withFamily("Roboto Mono")
        let font = UIFont(descriptor: descriptor, size: size)
        if font.familyName == "Roboto Mono" { return font }
        return .monospacedSystemFont(ofSize: size, weight: weight)
    }

    // MARK: - Titles

    /// Title 1 — Bold 32pt, line 40, spacing 0.11
    static let title1B = DSTextStyle(font: roboto(size: 32, weight: .bold), lineHeight: 40, letterSpacing: 0.11)

    /// Title 2 — Bold 28pt, line 32
    static let title2B = DSTextStyle(font: roboto(size: 28, weight: .bold), lineHeight: 32, letterSpacing: 0)

    /// Title 3 — Bold 24pt, line 32
    static let title3B = DSTextStyle(font: roboto(size: 24, weight: .bold), lineHeight: 32, letterSpacing: 0)

    /// Title 4 — Regular 24pt, line 32
    static let title4R = DSTextStyle(font: roboto(size: 24, weight: .regular), lineHeight: 32, letterSpacing: 0)

    /// Title 5 — Bold 20pt, line 28
    static let title5B = DSTextStyle(font: roboto(size: 20, weight: .bold), lineHeight: 28, letterSpacing: 0)

    /// Title 6 — Medium 20pt, line 28
    static let title6M = DSTextStyle(font: roboto(size: 20, weight: .medium), lineHeight: 28, letterSpacing: 0)

    /// Title 7 — Regular 20pt, line 28
    static let title7R = DSTextStyle(font: roboto(size: 20, weight: .regular), lineHeight: 28, letterSpacing: 0)

    // MARK: - Subtitles

    /// Subtitle 1 — Medium 18pt, line 24
    static let subtitle1M = DSTextStyle(font: roboto(size: 18, weight: .medium), lineHeight: 24, letterSpacing: 0)

    /// Subtitle 2 — Regular 18pt, line 24
    static let subtitle2R = DSTextStyle(font: roboto(size: 18, weight: .regular), lineHeight: 24, letterSpacing: 0)

    // MARK: - Body

    /// Body 1 — Regular 16pt, line 20
    static let body1R = DSTextStyle(font: roboto(size: 16, weight: .regular), lineHeight: 20, letterSpacing: 0)

    /// Body 2 — Bold 16pt, line 22, spacing 0.32
    static let body2B = DSTextStyle(font: roboto(size: 16, weight: .bold), lineHeight: 22, letterSpacing: 0.32)

    /// Body 3 — Medium 16pt, line 22
    static let body3M = DSTextStyle(font: roboto(size: 16, weight: .medium), lineHeight: 22, letterSpacing: 0)

    /// Body 4 — Medium 14pt, line 16
    static let body4M = DSTextStyle(font: roboto(size: 14, weight: .medium), lineHeight: 16, letterSpacing: 0)

    /// Body 5 — Regular 14pt, line 16
    static let body5R = DSTextStyle(font: roboto(size: 14, weight: .regular), lineHeight: 16, letterSpacing: 0)

    // MARK: - Subheads

    /// Subhead 1 — Bold 14pt, line 20
    static let subhead1B = DSTextStyle(font: roboto(size: 14, weight: .bold), lineHeight: 20, letterSpacing: 0)

    /// Subhead 2 — Regular 14pt, line 20
    static let subhead2R = DSTextStyle(font: roboto(size: 14, weight: .regular), lineHeight: 20, letterSpacing: 0)

    /// Subhead 3 — Regular 13pt, line 16
    static let subhead3R = DSTextStyle(font: roboto(size: 13, weight: .regular), lineHeight: 16, letterSpacing: 0)

    /// Subhead 4 — Medium 14pt, line 20
    static let subhead4M = DSTextStyle(font: roboto(size: 14, weight: .medium), lineHeight: 20, letterSpacing: 0)

    // MARK: - Captions

    /// Caption 1 — Bold 12pt, line 16
    static let caption1B = DSTextStyle(font: roboto(size: 12, weight: .bold), lineHeight: 16, letterSpacing: 0)

    /// Caption 2 — Regular 12pt, line 14
    static let caption2R = DSTextStyle(font: roboto(size: 12, weight: .regular), lineHeight: 14, letterSpacing: 0)

    /// Caption 3 — Medium 11pt, line 14
    static let caption3M = DSTextStyle(font: roboto(size: 11, weight: .medium), lineHeight: 14, letterSpacing: 0)

    /// Subcaption — Regular 11pt, line 13
    static let subcaptionR = DSTextStyle(font: roboto(size: 11, weight: .regular), lineHeight: 13, letterSpacing: 0)

    // MARK: - Bubble (Chat Messages)

    /// Bubble — Regular 13pt, line 16
    static let bubbleR13 = DSTextStyle(font: roboto(size: 13, weight: .regular), lineHeight: 16, letterSpacing: 0)

    /// Bubble — Regular 14pt, line 18
    static let bubbleR14 = DSTextStyle(font: roboto(size: 14, weight: .regular), lineHeight: 18, letterSpacing: 0)

    /// Bubble — Regular 15pt, line 20 (default chat size)
    static let bubbleR15 = DSTextStyle(font: roboto(size: 15, weight: .regular), lineHeight: 20, letterSpacing: 0)

    /// Bubble — Regular 16pt, line 22
    static let bubbleR16 = DSTextStyle(font: roboto(size: 16, weight: .regular), lineHeight: 22, letterSpacing: 0)

    /// Bubble — Regular 18pt, line 24
    static let bubbleR18 = DSTextStyle(font: roboto(size: 18, weight: .regular), lineHeight: 24, letterSpacing: 0)

    /// Bubble — Regular 20pt, line 24
    static let bubbleR20 = DSTextStyle(font: roboto(size: 20, weight: .regular), lineHeight: 24, letterSpacing: 0)

    /// Bubble — Regular 22pt, line 30 (actual font size 24pt per Figma)
    static let bubbleR22 = DSTextStyle(font: roboto(size: 24, weight: .regular), lineHeight: 30, letterSpacing: 0)

    /// Bubble — Medium 13pt, line 16
    static let bubbleM13 = DSTextStyle(font: roboto(size: 13, weight: .medium), lineHeight: 16, letterSpacing: 0)

    // MARK: - Bubble Mono (Chat Messages - Monospaced)

    /// Bubble Mono — Regular 13pt, line 16
    static let bubbleMonoR13 = DSTextStyle(font: robotoMono(size: 13, weight: .regular), lineHeight: 16, letterSpacing: 0)

    /// Bubble Mono — Regular 14pt, line 18
    static let bubbleMonoR14 = DSTextStyle(font: robotoMono(size: 14, weight: .regular), lineHeight: 18, letterSpacing: 0)

    /// Bubble Mono — Regular 15pt, line 20 (default chat size)
    static let bubbleMonoR15 = DSTextStyle(font: robotoMono(size: 15, weight: .regular), lineHeight: 20, letterSpacing: 0)

    /// Bubble Mono — Regular 16pt, line 22
    static let bubbleMonoR16 = DSTextStyle(font: robotoMono(size: 16, weight: .regular), lineHeight: 22, letterSpacing: 0)

    /// Bubble Mono — Regular 18pt, line 24
    static let bubbleMonoR18 = DSTextStyle(font: robotoMono(size: 18, weight: .regular), lineHeight: 24, letterSpacing: 0)

    /// Bubble Mono — Regular 20pt, line 24
    static let bubbleMonoR20 = DSTextStyle(font: robotoMono(size: 20, weight: .regular), lineHeight: 24, letterSpacing: 0)

    /// Bubble Mono — Regular 22pt, line 30 (actual font size 24pt per Figma)
    static let bubbleMonoR22 = DSTextStyle(font: robotoMono(size: 24, weight: .regular), lineHeight: 30, letterSpacing: 0)
}
