# CheckboxView Component Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a `CheckboxView` UIKit component with Square/Circle shapes, checked/unchecked toggle with animation, enabled/disabled states, optional text label, injectable theming, and a fully interactive GalleryApp preview.

**Architecture:** The component follows the existing ChipsView pattern: a public `CheckboxView` class in `Sources/Components/` with an injectable `CheckboxColorScheme` struct, no hardcoded colors or SF Symbols. The GalleryApp preview uses `DSBrand` to generate brand-specific color schemes, and the preview supports live tap-to-toggle interaction with animated checkmark transitions. All icons come from the icons-library SVG assets rendered via `DSIcon`.

**Tech Stack:** Swift, UIKit (programmatic, no storyboards), iOS 14+, Roboto font via DSTypography, icons-library SVGs via DSIcon.

---

## Task 1: Add Missing Design System Tokens

The Figma checkbox design uses color opacities (25%, 55%) and a typography style (Body 5 - R) not yet in the design system.

**Files:**
- Modify: `GalleryApp/GalleryApp/DesignSystem/DSBrand.swift`
- Modify: `GalleryApp/GalleryApp/DesignSystem/DSTypography.swift`

**Step 1: Add `basicColor25` and `basicColor55` to DSBrand**

In `DSBrand.swift`, add these two methods after the existing `basicColor50` method (after line 89):

```swift
func basicColor25(for style: UIUserInterfaceStyle) -> UIColor {
    DSBrand.cached(self, style, 6) {
        style == .dark ? UIColor(hex: "#FFFFFF40") : UIColor(hex: "#00000040")
    }
}

func basicColor55(for style: UIUserInterfaceStyle) -> UIColor {
    DSBrand.cached(self, style, 7) {
        style == .dark ? UIColor(hex: "#FFFFFF8c") : UIColor(hex: "#0000008c")
    }
}
```

> Note: 25% = 0x40, 55% = 0x8C in hex alpha.

**Step 2: Add `body5R` to DSTypography**

In `DSTypography.swift`, add after `body3M` (after line 75):

```swift
/// Body 5 — Regular 14pt, line 16
static let body5R = DSTextStyle(font: roboto(size: 14, weight: .regular), lineHeight: 16, letterSpacing: 0)
```

**Step 3: Commit**

```bash
git add GalleryApp/GalleryApp/DesignSystem/DSBrand.swift GalleryApp/GalleryApp/DesignSystem/DSTypography.swift
git commit -m "feat: add basicColor25/55 and body5R design tokens for checkbox"
```

---

## Task 2: Bundle Checkbox Icon SVGs

Copy the 4 needed checkbox icon SVGs from the icons-library repo into the GalleryApp bundle.

**Files:**
- Create: `GalleryApp/GalleryApp/Resources/Icons/checkbox-def.svg`
- Create: `GalleryApp/GalleryApp/Resources/Icons/checkbox-active.svg`
- Create: `GalleryApp/GalleryApp/Resources/Icons/check-def-small.svg`
- Create: `GalleryApp/GalleryApp/Resources/Icons/check-active-small.svg`

**Step 1: Copy SVGs from icons-library**

```bash
cp ~/Clode\ code\ projects/Icons\ library/icons/checkbox-def.svg \
   ~/Clode\ code\ projects/ios-land-component/GalleryApp/GalleryApp/Resources/Icons/

cp ~/Clode\ code\ projects/Icons\ library/icons/checkbox-active.svg \
   ~/Clode\ code\ projects/ios-land-component/GalleryApp/GalleryApp/Resources/Icons/

cp ~/Clode\ code\ projects/Icons\ library/icons/check-def-small.svg \
   ~/Clode\ code\ projects/ios-land-component/GalleryApp/GalleryApp/Resources/Icons/

cp ~/Clode\ code\ projects/Icons\ library/icons/check-active-small.svg \
   ~/Clode\ code\ projects/ios-land-component/GalleryApp/GalleryApp/Resources/Icons/
```

**Step 2: Add SVGs to Xcode project**

The SVGs must be added to the Xcode project's GalleryApp target so they are bundled. Use the `PBXProject` — add the 4 files to the existing `Icons` group in the Xcode project, in the same `Resources/Icons` folder reference that already contains `user.svg`, `close-s.svg`, etc.

Use the ruby script approach or manually add to the `.pbxproj`. The simplest approach: open Xcode briefly or use `xcodebuild` which auto-discovers files in the Resources directory if they're in a folder reference. Check how existing SVGs are referenced — if the `Icons/` folder is a folder reference (blue folder in Xcode), new files are auto-included.

Verify by checking the project file:
```bash
grep "checkbox" GalleryApp/GalleryApp.xcodeproj/project.pbxproj
```

If not auto-included, add them to the Xcode project programmatically (see existing pattern for how `user.svg` etc. are referenced).

**Step 3: Commit**

```bash
git add GalleryApp/GalleryApp/Resources/Icons/checkbox-def.svg \
       GalleryApp/GalleryApp/Resources/Icons/checkbox-active.svg \
       GalleryApp/GalleryApp/Resources/Icons/check-def-small.svg \
       GalleryApp/GalleryApp/Resources/Icons/check-active-small.svg
git commit -m "feat: bundle checkbox icon SVGs from icons-library"
```

---

## Task 3: Create CheckboxView Component

The core component with injectable theming, matching the Figma spec exactly.

**Files:**
- Create: `Sources/Components/CheckboxView.swift`

**Step 1: Write `CheckboxColorScheme` and `CheckboxView`**

```swift
import UIKit

// MARK: - CheckboxColorScheme

/// Injectable color scheme for CheckboxView component.
/// Provides Frisbee Light mode colors as default fallback.
public struct CheckboxColorScheme {
    public let borderEnabled: UIColor      // Basic Colors/55%
    public let borderDisabled: UIColor     // Basic Colors/25%
    public let checkedFill: UIColor        // ThemeFirst/Primary/Default (brand accent)
    public let textEnabled: UIColor        // Basic Colors/50%
    public let textDisabled: UIColor       // Basic Colors/25%

    public init(
        borderEnabled: UIColor,
        borderDisabled: UIColor,
        checkedFill: UIColor,
        textEnabled: UIColor,
        textDisabled: UIColor
    ) {
        self.borderEnabled = borderEnabled
        self.borderDisabled = borderDisabled
        self.checkedFill = checkedFill
        self.textEnabled = textEnabled
        self.textDisabled = textDisabled
    }

    public static let `default` = CheckboxColorScheme(
        borderEnabled: UIColor(white: 0, alpha: 0.55),
        borderDisabled: UIColor(white: 0, alpha: 0.25),
        checkedFill: UIColor(red: 64/255, green: 178/255, blue: 89/255, alpha: 1),
        textEnabled: UIColor(white: 0, alpha: 0.5),
        textDisabled: UIColor(white: 0, alpha: 0.25)
    )
}

// MARK: - CheckboxView

/// A checkbox component with Square and Circle shapes.
///
/// Supports:
/// - Two shapes: `.square` (rounded rect) and `.circle`
/// - Checked/unchecked states with animated transitions
/// - Enabled/disabled interactive states
/// - Optional text label (8pt gap, center-aligned for single line, top-aligned for multi-line)
///
/// All icons are loaded from the icons-library SVG assets. No SF Symbols.
public final class CheckboxView: UIView {

    // MARK: - Types

    public enum Shape {
        case square
        case circle
    }

    private enum Layout {
        static let outerSize: CGFloat = 24
        static let innerSize: CGFloat = 20
        static let innerInset: CGFloat = 2
        static let borderWidth: CGFloat = 2
        static let squareCornerRadius: CGFloat = 6
        static let textGap: CGFloat = 8
    }

    // MARK: - Public Properties

    public var onTap: (() -> Void)?

    public private(set) var isChecked: Bool = false
    public private(set) var isEnabled: Bool = true

    // MARK: - Private Properties

    private var shape: Shape = .square
    private var colorScheme: CheckboxColorScheme = .default
    private var showText: Bool = true

    // Subviews
    private let containerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let checkboxContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    /// The border ring (unchecked state)
    private let borderView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    /// The filled check icon (checked state)
    private let checkImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let textLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private static func robotoFont(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let systemFont = UIFont.systemFont(ofSize: size, weight: weight)
        let descriptor = systemFont.fontDescriptor.withFamily("Roboto")
        let font = UIFont(descriptor: descriptor, size: size)
        if font.familyName == "Roboto" { return font }
        return systemFont
    }

    private static let robotoRegular14: UIFont = robotoFont(size: 14, weight: .regular)

    // MARK: - Initialization

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    // MARK: - Public Methods

    /// Configures the checkbox.
    /// - Parameters:
    ///   - text: Optional label text (set nil or empty to hide)
    ///   - shape: `.square` (6pt rounded rect) or `.circle`
    ///   - isChecked: Whether the checkbox is initially checked
    ///   - isEnabled: Whether the checkbox is interactable (affects border/text opacity)
    ///   - colorScheme: Injectable color scheme (defaults to Frisbee Light)
    public func configure(
        text: String? = nil,
        shape: Shape = .square,
        isChecked: Bool = false,
        isEnabled: Bool = true,
        colorScheme: CheckboxColorScheme = .default
    ) {
        self.shape = shape
        self.isChecked = isChecked
        self.isEnabled = isEnabled
        self.colorScheme = colorScheme
        self.showText = text != nil && !text!.isEmpty

        textLabel.text = text
        textLabel.isHidden = !showText

        updateAppearance(animated: false)
    }

    /// Toggles checked state with animation.
    public func toggleChecked(animated: Bool = true) {
        isChecked.toggle()
        updateAppearance(animated: animated)
        onTap?()
    }

    /// Sets checked state.
    public func setChecked(_ checked: Bool, animated: Bool = true) {
        guard isChecked != checked else { return }
        isChecked = checked
        updateAppearance(animated: animated)
    }

    // MARK: - Setup

    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        isAccessibilityElement = true
        accessibilityTraits = .button

        // Checkbox container (fixed 24x24)
        checkboxContainer.addSubview(borderView)
        checkboxContainer.addSubview(checkImageView)

        containerStack.addArrangedSubview(checkboxContainer)
        containerStack.addArrangedSubview(textLabel)
        addSubview(containerStack)

        NSLayoutConstraint.activate([
            containerStack.topAnchor.constraint(equalTo: topAnchor),
            containerStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerStack.bottomAnchor.constraint(equalTo: bottomAnchor),

            checkboxContainer.widthAnchor.constraint(equalToConstant: Layout.outerSize),
            checkboxContainer.heightAnchor.constraint(equalToConstant: Layout.outerSize),

            borderView.centerXAnchor.constraint(equalTo: checkboxContainer.centerXAnchor),
            borderView.centerYAnchor.constraint(equalTo: checkboxContainer.centerYAnchor),
            borderView.widthAnchor.constraint(equalToConstant: Layout.innerSize),
            borderView.heightAnchor.constraint(equalToConstant: Layout.innerSize),

            checkImageView.topAnchor.constraint(equalTo: checkboxContainer.topAnchor),
            checkImageView.leadingAnchor.constraint(equalTo: checkboxContainer.leadingAnchor),
            checkImageView.trailingAnchor.constraint(equalTo: checkboxContainer.trailingAnchor),
            checkImageView.bottomAnchor.constraint(equalTo: checkboxContainer.bottomAnchor),
        ])

        // Multi-line alignment: top-align checkbox with text
        containerStack.alignment = .top
        // But for single-line, we want center — handled in updateAppearance

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }

    @objc private func handleTap() {
        guard isEnabled else { return }
        toggleChecked(animated: true)
    }

    // MARK: - Appearance

    private func updateAppearance(animated: Bool) {
        // Shape
        let cornerRadius: CGFloat = shape == .square ? Layout.squareCornerRadius : Layout.innerSize / 2
        borderView.layer.cornerRadius = cornerRadius
        borderView.layer.borderWidth = Layout.borderWidth

        // Border color based on enabled state
        let borderColor = isEnabled ? colorScheme.borderEnabled : colorScheme.borderDisabled
        borderView.layer.borderColor = borderColor.cgColor
        borderView.backgroundColor = .clear

        // Text styling (Body 5 - R: Roboto Regular 14pt, line height 16pt)
        let textColor = isEnabled ? colorScheme.textEnabled : colorScheme.textDisabled
        textLabel.font = Self.robotoRegular14
        textLabel.textColor = textColor

        // Alignment: center for single line, top for multiline
        let isSingleLine = (textLabel.text?.contains("\n") == false) && showText
        containerStack.alignment = isSingleLine ? .center : .top

        // Load the appropriate check icon
        let iconName: String
        switch shape {
        case .square: iconName = "checkbox-active"
        case .circle: iconName = "check-active-small"
        }

        // Checked/unchecked transition
        let showCheck = isChecked
        let showBorder = !isChecked

        if animated {
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut) {
                self.borderView.alpha = showBorder ? 1 : 0
                self.checkImageView.alpha = showCheck ? 1 : 0
            }
            // Scale bounce on the check icon
            if showCheck {
                checkImageView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                checkImageView.image = DSIconBridge.loadIcon(named: iconName, size: Layout.outerSize)?
                    .withTintColor(colorScheme.checkedFill, renderingMode: .alwaysOriginal)
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8, options: []) {
                    self.checkImageView.transform = .identity
                }
            }
        } else {
            borderView.alpha = showBorder ? 1 : 0
            checkImageView.alpha = showCheck ? 1 : 0
            if showCheck {
                checkImageView.image = DSIconBridge.loadIcon(named: iconName, size: Layout.outerSize)?
                    .withTintColor(colorScheme.checkedFill, renderingMode: .alwaysOriginal)
            }
        }

        // Accessibility
        accessibilityLabel = textLabel.text
        accessibilityValue = isChecked ? "checked" : "unchecked"
    }
}

// MARK: - DSIconBridge

/// Minimal SVG icon loader for the Components package.
/// Mirrors DSIcon logic so CheckboxView can load icons-library SVGs without depending on GalleryApp.
/// In production, the host app provides icons via the configure method or bundles them.
public enum DSIconBridge {

    private static let cache = NSCache<NSString, UIImage>()

    /// Loads an SVG icon from the main bundle as a template image.
    public static func loadIcon(named name: String, size: CGFloat = 24) -> UIImage? {
        let key = "\(name)_\(size)" as NSString
        if let cached = cache.object(forKey: key) { return cached }

        guard let url = Bundle.main.url(forResource: name, withExtension: "svg"),
              let svgString = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }

        let viewBox = parseViewBox(svgString) ?? CGRect(x: 0, y: 0, width: 24, height: 24)
        let paths = parsePaths(svgString)

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let image = renderer.image { context in
            let scaleX = size / viewBox.width
            let scaleY = size / viewBox.height
            context.cgContext.translateBy(x: -viewBox.origin.x * scaleX,
                                          y: -viewBox.origin.y * scaleY)
            context.cgContext.scaleBy(x: scaleX, y: scaleY)
            UIColor.black.setFill()
            for bezier in paths { bezier.fill() }
        }

        let result = image.withRenderingMode(.alwaysTemplate)
        cache.setObject(result, forKey: key)
        return result
    }

    private static func parseViewBox(_ svg: String) -> CGRect? {
        guard let range = svg.range(of: "viewBox=\""),
              let endRange = svg[range.upperBound...].range(of: "\"") else { return nil }
        let parts = svg[range.upperBound..<endRange.lowerBound]
            .split(separator: " ").compactMap { Double($0) }
        guard parts.count == 4 else { return nil }
        return CGRect(x: parts[0], y: parts[1], width: parts[2], height: parts[3])
    }

    private static func parsePaths(_ svg: String) -> [UIBezierPath] {
        var results: [UIBezierPath] = []
        var searchStart = svg.startIndex
        while let pathStart = svg[searchStart...].range(of: "<path") {
            guard let tagEnd = svg[pathStart.lowerBound...].range(of: "/>") ??
                               svg[pathStart.lowerBound...].range(of: ">") else { break }
            let tag = String(svg[pathStart.lowerBound..<tagEnd.upperBound])
            if let d = extractAttribute("d", from: tag) {
                let fillRule: String? = extractAttribute("fill-rule", from: tag)
                let bezier = SVGPathParserLite.parse(d, evenOdd: fillRule == "evenodd")
                results.append(bezier)
            }
            searchStart = tagEnd.upperBound
        }
        return results
    }

    private static func extractAttribute(_ name: String, from tag: String) -> String? {
        let pattern = name + "=\""
        guard let start = tag.range(of: pattern) else { return nil }
        guard let end = tag[start.upperBound...].range(of: "\"") else { return nil }
        return String(tag[start.upperBound..<end.lowerBound])
    }
}

// MARK: - SVGPathParserLite

/// Lightweight SVG path parser for the Components package.
/// Handles the subset of SVG path commands used in icons-library checkbox icons.
public enum SVGPathParserLite {

    public static func parse(_ d: String, evenOdd: Bool = false) -> UIBezierPath {
        let path = UIBezierPath()
        if evenOdd { path.usesEvenOddFillRule = true }

        var scanner = Scanner(string: d)
        scanner.charactersToBeSkipped = CharacterSet.whitespaces.union(CharacterSet(charactersIn: ","))
        var currentPoint = CGPoint.zero
        var lastCommand: Character = "M"

        while !scanner.isAtEnd {
            var cmd: Character = lastCommand
            // Try to scan a command letter
            let saved = scanner.currentIndex
            if let ch = scanner.scanCharacter(), ch.isLetter {
                cmd = ch
            } else {
                scanner.currentIndex = saved
            }

            switch cmd {
            case "M":
                guard let x = scanner.scanDouble(), let y = scanner.scanDouble() else { break }
                currentPoint = CGPoint(x: x, y: y)
                path.move(to: currentPoint)
                lastCommand = "L" // subsequent coords are line-to
            case "m":
                guard let dx = scanner.scanDouble(), let dy = scanner.scanDouble() else { break }
                currentPoint = CGPoint(x: currentPoint.x + dx, y: currentPoint.y + dy)
                path.move(to: currentPoint)
                lastCommand = "l"
            case "L":
                guard let x = scanner.scanDouble(), let y = scanner.scanDouble() else { break }
                currentPoint = CGPoint(x: x, y: y)
                path.addLine(to: currentPoint)
                lastCommand = "L"
            case "l":
                guard let dx = scanner.scanDouble(), let dy = scanner.scanDouble() else { break }
                currentPoint = CGPoint(x: currentPoint.x + dx, y: currentPoint.y + dy)
                path.addLine(to: currentPoint)
                lastCommand = "l"
            case "H":
                guard let x = scanner.scanDouble() else { break }
                currentPoint = CGPoint(x: x, y: currentPoint.y)
                path.addLine(to: currentPoint)
                lastCommand = "H"
            case "h":
                guard let dx = scanner.scanDouble() else { break }
                currentPoint = CGPoint(x: currentPoint.x + dx, y: currentPoint.y)
                path.addLine(to: currentPoint)
                lastCommand = "h"
            case "V":
                guard let y = scanner.scanDouble() else { break }
                currentPoint = CGPoint(x: currentPoint.x, y: y)
                path.addLine(to: currentPoint)
                lastCommand = "V"
            case "v":
                guard let dy = scanner.scanDouble() else { break }
                currentPoint = CGPoint(x: currentPoint.x, y: currentPoint.y + dy)
                path.addLine(to: currentPoint)
                lastCommand = "v"
            case "C":
                guard let x1 = scanner.scanDouble(), let y1 = scanner.scanDouble(),
                      let x2 = scanner.scanDouble(), let y2 = scanner.scanDouble(),
                      let x = scanner.scanDouble(), let y = scanner.scanDouble() else { break }
                currentPoint = CGPoint(x: x, y: y)
                path.addCurve(to: currentPoint,
                              controlPoint1: CGPoint(x: x1, y: y1),
                              controlPoint2: CGPoint(x: x2, y: y2))
                lastCommand = "C"
            case "c":
                guard let dx1 = scanner.scanDouble(), let dy1 = scanner.scanDouble(),
                      let dx2 = scanner.scanDouble(), let dy2 = scanner.scanDouble(),
                      let dx = scanner.scanDouble(), let dy = scanner.scanDouble() else { break }
                let cp1 = CGPoint(x: currentPoint.x + dx1, y: currentPoint.y + dy1)
                let cp2 = CGPoint(x: currentPoint.x + dx2, y: currentPoint.y + dy2)
                currentPoint = CGPoint(x: currentPoint.x + dx, y: currentPoint.y + dy)
                path.addCurve(to: currentPoint, controlPoint1: cp1, controlPoint2: cp2)
                lastCommand = "c"
            case "Z", "z":
                path.close()
                lastCommand = "M"
            default:
                // Skip unknown command
                _ = scanner.scanDouble()
            }
        }

        return path
    }
}
```

**Important design decisions:**
- The component includes `DSIconBridge` and `SVGPathParserLite` to load SVG icons from the main bundle without depending on the GalleryApp's `DSIcon`/`SVGPathParser`. This mirrors the ChipsView pattern where the component package is self-contained.
- The `checkbox-active` SVG has a filled rounded rect + checkmark in white. We load it as a template image and tint it with `colorScheme.checkedFill` (brand accent color).
- `check-active-small` is the circle equivalent.
- The border view draws the unchecked state (a ring with `borderWidth: 2`, correct `cornerRadius`).
- Toggle animation: border fades out while check icon scales in with spring bounce.
- Multi-line text: stack alignment switches to `.top`, single-line stays `.center`.

**Step 2: Update Package.swift if needed**

Check that `Sources/Components/CheckboxView.swift` is auto-included by the Swift Package manifest (it should be, since the target points to `Sources/Components` directory).

**Step 3: Commit**

```bash
git add Sources/Components/CheckboxView.swift
git commit -m "feat: add CheckboxView component with injectable theming"
```

---

## Task 4: Add CheckboxColorScheme to DSBrand

Wire up brand-specific checkbox color schemes in the GalleryApp.

**Files:**
- Modify: `GalleryApp/GalleryApp/DesignSystem/DSBrand.swift`

**Step 1: Add `checkboxColorScheme` method**

Add after the existing `chipsColorScheme` method (after line 100):

```swift
// MARK: - CheckboxView Integration

func checkboxColorScheme(for style: UIUserInterfaceStyle) -> CheckboxColorScheme {
    CheckboxColorScheme(
        borderEnabled: basicColor55(for: style),
        borderDisabled: basicColor25(for: style),
        checkedFill: accentColor(for: style),
        textEnabled: basicColor50(for: style),
        textDisabled: basicColor25(for: style)
    )
}
```

**Step 2: Commit**

```bash
git add GalleryApp/GalleryApp/DesignSystem/DSBrand.swift
git commit -m "feat: add checkboxColorScheme to DSBrand"
```

---

## Task 5: Create Interactive Preview

Build the preview VC following the ChipsViewPreviewVC pattern, with live tap-to-toggle and animated checkmark.

**Files:**
- Create: `GalleryApp/GalleryApp/Previews/CheckboxViewPreviewVC.swift`

**Step 1: Write the preview ViewController**

```swift
import UIKit
import Components

final class CheckboxViewPreviewVC: UIViewController {

    // MARK: - State

    private var selectedShape: CheckboxView.Shape = .square
    private var selectedEnabled: Bool = true
    private var selectedShowText: Bool = true
    private var selectedBrand: DSBrand = .frisbee
    private var selectedStyle: UIUserInterfaceStyle = .light

    // MARK: - UI Elements

    private var currentCheckbox: CheckboxView?

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let contentStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = DSSpacing.verticalSection
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let previewContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = DSCornerRadius.card
        v.clipsToBounds = true
        return v
    }()

    private let controlsStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = DSSpacing.listItemSpacing
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private lazy var shapeDropdown = DropdownControl()
    private lazy var enabledDropdown = DropdownControl()
    private lazy var textDropdown = DropdownControl()
    private let themeSegment = UISegmentedControl(items: ["Light", "Dark"])
    private lazy var brandSegment = UISegmentedControl(items: DSBrand.allCases.map { $0.rawValue })

    // MARK: - Menu Options

    private let shapeOptions: [(String, CheckboxView.Shape)] = [
        ("Square", .square),
        ("Circle", .circle)
    ]

    private let enabledOptions: [(String, Bool)] = [
        ("Enabled", true),
        ("Disabled", false)
    ]

    private let textOptions: [(String, Bool)] = [
        ("With text", true),
        ("Without text", false)
    ]

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = DSColors.backgroundBase
        setupLayout()
        setupControls()
        rebuildCheckbox()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        shapeDropdown.dismissOptions()
        enabledDropdown.dismissOptions()
        textDropdown.dismissOptions()
    }

    // MARK: - Layout

    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: DSSpacing.verticalSection),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: DSSpacing.horizontalPadding),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -DSSpacing.horizontalPadding),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -DSSpacing.verticalSection),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -DSSpacing.horizontalPadding * 2)
        ])

        // Brand selector (above preview)
        contentStack.addArrangedSubview(brandSegment)

        // Preview container
        contentStack.addArrangedSubview(previewContainer)
        previewContainer.heightAnchor.constraint(equalToConstant: 160).isActive = true

        // Hint label
        let hintLabel = UILabel()
        hintLabel.font = DSTypography.subhead3R.font
        hintLabel.textColor = DSColors.textTertiary
        hintLabel.text = "Tap the checkbox to toggle"
        hintLabel.textAlignment = .center
        contentStack.addArrangedSubview(hintLabel)

        // Controls stack (below preview)
        contentStack.addArrangedSubview(controlsStack)
        controlsStack.addArrangedSubview(makeControlRow(label: "Shape", control: shapeDropdown))
        controlsStack.addArrangedSubview(makeControlRow(label: "State", control: enabledDropdown))
        controlsStack.addArrangedSubview(makeControlRow(label: "Text", control: textDropdown))
        controlsStack.addArrangedSubview(makeControlRow(label: "Theme", control: themeSegment))
    }

    private func makeControlRow(label text: String, control: UIView) -> UIStackView {
        let label = UILabel()
        label.text = text
        label.font = DSTypography.subhead4M.font
        label.textColor = DSColors.textPrimary
        label.widthAnchor.constraint(equalToConstant: 52).isActive = true

        let row = UIStackView(arrangedSubviews: [label, control])
        row.axis = .horizontal
        row.spacing = 8
        row.alignment = .center
        return row
    }

    // MARK: - Controls Setup

    private func setupControls() {
        themeSegment.selectedSegmentIndex = 0
        brandSegment.selectedSegmentIndex = 0

        themeSegment.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        brandSegment.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)

        shapeDropdown.label.text = shapeOptions.first?.0
        shapeDropdown.onTap = { [weak self] in self?.toggleShapeDropdown() }

        enabledDropdown.label.text = enabledOptions.first?.0
        enabledDropdown.onTap = { [weak self] in self?.toggleEnabledDropdown() }

        textDropdown.label.text = textOptions.first?.0
        textDropdown.onTap = { [weak self] in self?.toggleTextDropdown() }
    }

    private func dismissAllDropdowns() {
        shapeDropdown.dismissOptions()
        enabledDropdown.dismissOptions()
        textDropdown.dismissOptions()
    }

    private func toggleShapeDropdown() {
        enabledDropdown.dismissOptions()
        textDropdown.dismissOptions()
        if shapeDropdown.isShowingOptions {
            shapeDropdown.dismissOptions()
            return
        }
        let titles = shapeOptions.map { $0.0 }
        let selectedIndex = shapeOptions.firstIndex { $0.1 == selectedShape } ?? 0
        shapeDropdown.showOptions(titles: titles, selectedIndex: selectedIndex) { [weak self] index in
            guard let self else { return }
            self.selectedShape = self.shapeOptions[index].1
            self.shapeDropdown.label.text = self.shapeOptions[index].0
            self.rebuildCheckbox()
        }
    }

    private func toggleEnabledDropdown() {
        shapeDropdown.dismissOptions()
        textDropdown.dismissOptions()
        if enabledDropdown.isShowingOptions {
            enabledDropdown.dismissOptions()
            return
        }
        let titles = enabledOptions.map { $0.0 }
        let selectedIndex = enabledOptions.firstIndex { $0.1 == selectedEnabled } ?? 0
        enabledDropdown.showOptions(titles: titles, selectedIndex: selectedIndex) { [weak self] index in
            guard let self else { return }
            self.selectedEnabled = self.enabledOptions[index].1
            self.enabledDropdown.label.text = self.enabledOptions[index].0
            self.rebuildCheckbox()
        }
    }

    private func toggleTextDropdown() {
        shapeDropdown.dismissOptions()
        enabledDropdown.dismissOptions()
        if textDropdown.isShowingOptions {
            textDropdown.dismissOptions()
            return
        }
        let titles = textOptions.map { $0.0 }
        let selectedIndex = textOptions.firstIndex { $0.1 == selectedShowText } ?? 0
        textDropdown.showOptions(titles: titles, selectedIndex: selectedIndex) { [weak self] index in
            guard let self else { return }
            self.selectedShowText = self.textOptions[index].1
            self.textDropdown.label.text = self.textOptions[index].0
            self.rebuildCheckbox()
        }
    }

    @objc private func segmentChanged() {
        dismissAllDropdowns()

        switch themeSegment.selectedSegmentIndex {
        case 0: selectedStyle = .light
        case 1: selectedStyle = .dark
        default: break
        }

        let brandIndex = brandSegment.selectedSegmentIndex
        if brandIndex >= 0, brandIndex < DSBrand.allCases.count {
            selectedBrand = DSBrand.allCases[brandIndex]
        }

        rebuildCheckbox()
    }

    // MARK: - Checkbox Rebuild

    private func rebuildCheckbox() {
        currentCheckbox?.removeFromSuperview()

        previewContainer.backgroundColor = selectedBrand.backgroundSecond(for: selectedStyle)
        previewContainer.overrideUserInterfaceStyle = selectedStyle

        let colorScheme = selectedBrand.checkboxColorScheme(for: selectedStyle)

        let checkbox = CheckboxView()
        checkbox.configure(
            text: selectedShowText ? "Content" : nil,
            shape: selectedShape,
            isChecked: currentCheckbox?.isChecked ?? false,
            isEnabled: selectedEnabled,
            colorScheme: colorScheme
        )

        previewContainer.addSubview(checkbox)
        NSLayoutConstraint.activate([
            checkbox.centerXAnchor.constraint(equalTo: previewContainer.centerXAnchor),
            checkbox.centerYAnchor.constraint(equalTo: previewContainer.centerYAnchor),
            checkbox.widthAnchor.constraint(lessThanOrEqualTo: previewContainer.widthAnchor, constant: -32)
        ])

        currentCheckbox = checkbox
    }
}

// MARK: - DropdownControl (reused from ChipsViewPreviewVC)

// NOTE: DropdownControl and DropdownOptionsView are defined as fileprivate in
// ChipsViewPreviewVC.swift. Since they can't be shared across files as-is,
// duplicate them here. In the future these could be extracted to a shared file.
// The implementation is identical to ChipsViewPreviewVC's DropdownControl.

fileprivate final class DropdownControl: UIView {

    let label: UILabel = {
        let l = UILabel()
        l.font = DSTypography.subhead2R.font
        l.textColor = DSColors.textPrimary
        return l
    }()

    private let chevronView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = DSColors.textSecondary
        iv.image = DSIcon.named("toggle-down", size: 20)?
            .withRenderingMode(.alwaysTemplate)
        return iv
    }()

    var onTap: (() -> Void)?
    private(set) var isShowingOptions = false
    private var optionsView: DropdownOptionsView?
    private var backdropView: UIView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = DSColors.backgroundSecond
        layer.cornerRadius = DSCornerRadius.inputField
        clipsToBounds = true

        let stack = UIStackView(arrangedSubviews: [label, chevronView])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 44),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            chevronView.widthAnchor.constraint(equalToConstant: 20),
            chevronView.heightAnchor.constraint(equalToConstant: 20),
        ])

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped)))
    }

    @objc private func tapped() { onTap?() }
    @objc private func backdropTapped() { dismissOptions() }

    func showOptions(titles: [String], selectedIndex: Int, onSelect: @escaping (Int) -> Void) {
        dismissOptions()
        guard let window = window else { return }

        let optionsView = DropdownOptionsView(titles: titles, selectedIndex: selectedIndex) { [weak self] index in
            onSelect(index)
            self?.dismissOptions()
        }

        let frameInWindow = convert(bounds, to: window)
        optionsView.frame = CGRect(
            x: frameInWindow.minX,
            y: frameInWindow.maxY + 4,
            width: frameInWindow.width,
            height: CGFloat(titles.count) * 44
        )

        let backdrop = UIView(frame: window.bounds)
        backdrop.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backdrop.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(backdropTapped)))
        window.addSubview(backdrop)
        self.backdropView = backdrop

        optionsView.alpha = 0
        optionsView.transform = CGAffineTransform(translationX: 0, y: -8)
        window.addSubview(optionsView)

        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
            optionsView.alpha = 1
            optionsView.transform = .identity
        }

        self.optionsView = optionsView
        isShowingOptions = true
        UIView.animate(withDuration: 0.2) {
            self.chevronView.transform = CGAffineTransform(rotationAngle: .pi)
        }
    }

    func dismissOptions() {
        guard isShowingOptions, let optionsView else { return }
        isShowingOptions = false
        backdropView?.removeFromSuperview()
        backdropView = nil
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseIn, animations: {
            optionsView.alpha = 0
            optionsView.transform = CGAffineTransform(translationX: 0, y: -8)
            self.chevronView.transform = .identity
        }) { _ in
            optionsView.removeFromSuperview()
        }
        self.optionsView = nil
    }
}

fileprivate final class DropdownOptionsView: UIView {

    private let onSelect: (Int) -> Void

    init(titles: [String], selectedIndex: Int, onSelect: @escaping (Int) -> Void) {
        self.onSelect = onSelect
        super.init(frame: .zero)

        backgroundColor = DSColors.backgroundSheet
        layer.cornerRadius = DSCornerRadius.inputField
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.12
        layer.shadowRadius = 12
        layer.shadowOffset = CGSize(width: 0, height: 4)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        for (index, title) in titles.enumerated() {
            let row = makeRow(title: title, isSelected: index == selectedIndex, index: index)
            stack.addArrangedSubview(row)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    private func makeRow(title: String, isSelected: Bool, index: Int) -> UIView {
        let container = UIView()
        container.heightAnchor.constraint(equalToConstant: 44).isActive = true

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = isSelected ? DSTypography.subhead4M.font : DSTypography.subhead2R.font
        titleLabel.textColor = DSColors.textPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])

        if isSelected {
            let check = UIImageView()
            check.image = DSIcon.named("done", size: 20)?.withRenderingMode(.alwaysTemplate)
            check.tintColor = DSColors.textPrimary
            check.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(check)
            NSLayoutConstraint.activate([
                check.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
                check.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                check.widthAnchor.constraint(equalToConstant: 20),
                check.heightAnchor.constraint(equalToConstant: 20),
            ])
        }

        container.tag = index
        container.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(rowTapped(_:))))
        return container
    }

    @objc private func rowTapped(_ gesture: UITapGestureRecognizer) {
        guard let tag = gesture.view?.tag else { return }
        onSelect(tag)
    }
}
```

**Key interactive behaviors:**
- Tapping the checkbox in the preview toggles checked state with spring animation
- Changing any control (shape, enabled, text, theme, brand) rebuilds the checkbox but **preserves the current checked state** via `currentCheckbox?.isChecked`
- "Tap the checkbox to toggle" hint label below the preview
- Controls: Shape (Square/Circle), State (Enabled/Disabled), Text (With/Without), Theme (Light/Dark), Brand (5 brands)

**Step 2: Add to Xcode project**

Ensure the new file is added to the GalleryApp target in the Xcode project.

**Step 3: Commit**

```bash
git add GalleryApp/GalleryApp/Previews/CheckboxViewPreviewVC.swift
git commit -m "feat: add interactive CheckboxView preview with tap-to-toggle"
```

---

## Task 6: Register Component and Update Specs

Wire up the new component in the gallery and create the JSON spec.

**Files:**
- Modify: `GalleryApp/GalleryApp/ComponentListVC.swift` (line 6)
- Create: `specs/components/CheckboxView.json`
- Modify: `specs/index.json`

**Step 1: Add to ComponentListVC**

In `ComponentListVC.swift`, add a second entry to the `components` array (line 6):

```swift
private let components: [(name: String, description: String, viewController: () -> UIViewController)] = [
    ("ChipsView", "Filter chips with Default, Active, and Avatar states", { ChipsViewPreviewVC() }),
    ("CheckboxView", "Checkbox with Square and Circle shapes, animated toggle", { CheckboxViewPreviewVC() })
]
```

**Step 2: Create CheckboxView.json spec**

```json
{
  "name": "CheckboxView",
  "description": "A checkbox component with Square (rounded rect) and Circle shapes. Supports checked/unchecked toggle with spring animation, enabled/disabled interactive states, and optional text label. Uses injectable CheckboxColorScheme for brand theming.",
  "import": "import Components",
  "properties": [
    {
      "name": "text",
      "type": "String?",
      "description": "Optional label text displayed to the right of the checkbox (8pt gap). Nil or empty hides the label."
    },
    {
      "name": "shape",
      "type": "CheckboxView.Shape",
      "description": "Checkbox shape: .square (6pt corner radius rounded rect) or .circle"
    },
    {
      "name": "isChecked",
      "type": "Bool",
      "description": "Whether the checkbox is currently checked (read-only, set via configure or toggleChecked)"
    },
    {
      "name": "isEnabled",
      "type": "Bool",
      "description": "Whether the checkbox is interactable. Disabled state uses lighter border and text colors."
    },
    {
      "name": "colorScheme",
      "type": "CheckboxColorScheme",
      "description": "Injectable color scheme with borderEnabled, borderDisabled, checkedFill, textEnabled, textDisabled colors"
    },
    {
      "name": "onTap",
      "type": "(() -> Void)?",
      "description": "Callback fired when checkbox is toggled"
    }
  ],
  "usage": "import Components\n\n// Basic square checkbox\nlet checkbox = CheckboxView()\ncheckbox.configure(\n    text: \"Accept terms\",\n    shape: .square,\n    isChecked: false,\n    isEnabled: true,\n    colorScheme: .default\n)\ncheckbox.onTap = { print(\"Toggled: \\(checkbox.isChecked)\") }\n\n// Circle checkbox without text\nlet radio = CheckboxView()\nradio.configure(\n    shape: .circle,\n    isChecked: true,\n    isEnabled: true\n)\n\n// Programmatic toggle with animation\ncheckbox.toggleChecked(animated: true)\ncheckbox.setChecked(false, animated: true)",
  "tags": ["checkbox", "check", "toggle", "square", "circle", "selection", "form"]
}
```

**Step 3: Update specs/index.json**

```json
{
  "version": "1.0.0",
  "components": [
    {
      "name": "ChipsView",
      "description": "Filter chip with Default, Active, and Avatar states in two sizes (32pt, 40pt)"
    },
    {
      "name": "CheckboxView",
      "description": "Checkbox with Square and Circle shapes, animated toggle, enabled/disabled states"
    }
  ]
}
```

**Step 4: Commit**

```bash
git add GalleryApp/GalleryApp/ComponentListVC.swift \
       specs/components/CheckboxView.json \
       specs/index.json
git commit -m "feat: register CheckboxView in gallery and add JSON spec"
```

---

## Task 7: Build, Test, and Verify

**Step 1: Build the project**

```bash
cd GalleryApp
xcodebuild -project GalleryApp.xcodeproj -scheme GalleryApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Fix any compilation errors.

**Step 2: Install and run on simulator**

```bash
xcrun simctl install booted <path-to-built-app>
xcrun simctl launch booted com.evgenyshkuratov.GalleryApp
```

**Step 3: Verify in simulator**

- [ ] Main screen shows "CheckboxView" card below "ChipsView"
- [ ] Tapping card navigates to CheckboxView preview
- [ ] Preview shows checkbox centered in preview container
- [ ] Tapping checkbox toggles with spring animation
- [ ] Shape dropdown switches between Square and Circle
- [ ] State dropdown switches between Enabled and Disabled
- [ ] Disabled checkbox does not respond to taps
- [ ] Text dropdown toggles label visibility
- [ ] Brand selector changes accent color (Frisbee green, TDM blue, etc.)
- [ ] Theme toggle switches light/dark correctly
- [ ] Checked state persists when changing controls

**Step 4: Final commit if any fixes were needed**

```bash
git add -A
git commit -m "fix: checkbox preview adjustments after testing"
```
