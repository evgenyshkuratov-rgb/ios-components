# Interactive ChipsView Preview with Brand Theming

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Refactor ChipsView to match Figma exactly with injectable colors, then build an interactive preview page with controls for state, size, theme, and brand switching.

**Architecture:** ChipsView gets a `ChipsColorScheme` struct for injectable theming and a `closeIcon` image parameter. A new `DSBrand` enum in GalleryApp defines 5 brand palettes. The preview page shows a live chip in a themed container with segmented controls below.

**Tech Stack:** Swift, UIKit (programmatic, no storyboards), iOS 14+, Components Swift Package

**Testing:** No test target — verify visually in GalleryApp simulator after each task.

---

### Task 1: Refactor ChipsView with Injectable Colors and Figma-Exact Layout

**Files:**
- Modify: `Sources/Components/ChipsView.swift` (full rewrite of the 300-line file)

**Step 1: Replace ChipsColors with ChipsColorScheme**

Replace the `ChipsColors` enum (lines 287–299) with a public struct that consumers inject:

```swift
public struct ChipsColorScheme {
    public let backgroundDefault: UIColor   // Basic Colors/8%
    public let backgroundActive: UIColor    // ThemeFirst/Primary/Default
    public let textPrimary: UIColor         // Basic Colors/90%
    public let closeIconTint: UIColor       // Basic Colors/50%

    public init(
        backgroundDefault: UIColor,
        backgroundActive: UIColor,
        textPrimary: UIColor,
        closeIconTint: UIColor
    ) {
        self.backgroundDefault = backgroundDefault
        self.backgroundActive = backgroundActive
        self.textPrimary = textPrimary
        self.closeIconTint = closeIconTint
    }

    /// Fallback matching Frisbee Light mode
    public static let `default` = ChipsColorScheme(
        backgroundDefault: UIColor(white: 0, alpha: 0.08),
        backgroundActive: UIColor(red: 64/255, green: 178/255, blue: 89/255, alpha: 1),
        textPrimary: UIColor(white: 0, alpha: 0.9),
        closeIconTint: UIColor(white: 0, alpha: 0.5)
    )
}
```

**Step 2: Update configure/configureAvatar to accept colorScheme and closeIcon**

Update the public API:

```swift
public func configure(
    text: String,
    icon: UIImage? = nil,
    state: State = .default,
    size: Size = .small,
    colorScheme: ChipsColorScheme = .default
)

public func configureAvatar(
    name: String,
    avatarImage: UIImage?,
    closeIcon: UIImage? = nil,
    size: Size = .small,
    colorScheme: ChipsColorScheme = .default
)
```

Store `colorScheme` as a private property `private var colorScheme: ChipsColorScheme = .default`.

**Step 3: Replace SF Symbol close button with injected icon**

Remove from `closeButton` initializer (lines 100–106):
```swift
let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
button.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
button.tintColor = ChipsColors.textSecondary
```

Replace with just:
```swift
button.tintColor = UIColor(white: 0, alpha: 0.5) // will be updated by colorScheme
```

In `configureAvatar`, set the close icon:
```swift
closeButton.setImage(closeIcon?.withRenderingMode(.alwaysTemplate), for: .normal)
```

**Step 4: Fix padding to match Figma exactly**

The `Size` enum needs different padding per state. Update `setupConstraints` to use dynamic leading/trailing constraints that get updated in `updateAppearance`.

Figma spec per state/size:
- **Default 32**: leading 8, trailing 12, vertical centered
- **Default 40**: leading 12, trailing 12, vertical centered
- **Active 32**: leading 8, trailing 12, vertical centered
- **Active 40**: leading 12, trailing 12, vertical centered
- **Avatar 32**: leading 4, vertical 4 (top/bottom), no trailing (close btn provides it)
- **Avatar 40**: leading 4, vertical 4, no trailing

Store leading and trailing constraints as properties and update them in `updateAppearance`:

```swift
private var leadingConstraint: NSLayoutConstraint?
private var trailingConstraint: NSLayoutConstraint?
private var stackTopConstraint: NSLayoutConstraint?
private var stackBottomConstraint: NSLayoutConstraint?
```

In `updateAppearance`, set padding based on state + size:
```swift
switch currentState {
case .default, .active:
    let leadPad: CGFloat = currentSize == .small ? 8 : 12
    leadingConstraint?.constant = leadPad
    trailingConstraint?.constant = 12
    stackTopConstraint?.isActive = false
    stackBottomConstraint?.isActive = false
    containerStack.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

case .avatar:
    leadingConstraint?.constant = 4
    trailingConstraint?.constant = 0
    // For avatar, pin top and bottom with 4pt padding
}
```

Actually, a cleaner approach: remove the centerY constraint for avatar and use top/bottom pinning with 4pt insets. Use a dedicated set of constraints that get toggled.

**Step 5: Fix close button touch area**

Figma shows close button as 36x36 area with 24x24 icon inside (4pt padding). Update constraints:
```swift
closeButton.widthAnchor.constraint(equalToConstant: 36),
closeButton.heightAnchor.constraint(equalToConstant: 36),
```

**Step 6: Fix text styles per Figma**

Default/Active text: Roboto Medium 14pt, line-height 20 (matches `Subhead 4 -M` / `subhead4M`).
Avatar name: Roboto Regular 14pt, line-height 18, letter-spacing 0.25.

Keep using `robotoFont(size:weight:)` helper since the component package doesn't have DSTypography. But add letter spacing for avatar:

In `updateAppearance`, for `.avatar` state:
```swift
case .avatar:
    // ... colors ...
    textLabel.font = ChipsView.robotoFont(size: 14, weight: .regular)
    // Apply 0.25 letter spacing
    if let text = textLabel.text {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: ChipsView.robotoFont(size: 14, weight: .regular),
            .kern: 0.25,
            .foregroundColor: colorScheme.textPrimary
        ]
        textLabel.attributedText = NSAttributedString(string: text, attributes: attributes)
    }
```

**Step 7: Update updateAppearance to use colorScheme**

```swift
private func updateAppearance() {
    heightConstraint?.constant = currentSize.height
    avatarWidthConstraint?.constant = currentSize.avatarSize
    avatarHeightConstraint?.constant = currentSize.avatarSize
    layer.cornerRadius = currentSize.height / 2

    switch currentState {
    case .default:
        backgroundColor = colorScheme.backgroundDefault
        iconImageView.tintColor = colorScheme.textPrimary
        textLabel.textColor = colorScheme.textPrimary
        textLabel.font = ChipsView.robotoFont(size: 14, weight: .medium)

    case .active:
        backgroundColor = colorScheme.backgroundActive
        iconImageView.tintColor = colorScheme.textPrimary
        textLabel.textColor = colorScheme.textPrimary
        textLabel.font = ChipsView.robotoFont(size: 14, weight: .medium)

    case .avatar:
        backgroundColor = colorScheme.backgroundDefault
        closeButton.tintColor = colorScheme.closeIconTint
        // Avatar text with letter spacing applied separately
    }

    updatePadding()
    setNeedsLayout()
}
```

**Step 8: Build and verify in simulator**

Run:
```bash
cd GalleryApp
xcodebuild -project GalleryApp.xcodeproj -scheme GalleryApp \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```
Expected: BUILD SUCCEEDED (existing preview still works with `.default` color scheme)

**Step 9: Commit**

```bash
git add Sources/Components/ChipsView.swift
git commit -m "refactor: ChipsView with injectable ChipsColorScheme, Figma-exact padding and close icon"
```

---

### Task 2: Add DSBrand Enum with Per-Brand Color Palettes

**Files:**
- Create: `GalleryApp/GalleryApp/DesignSystem/DSBrand.swift`

**Step 1: Create DSBrand enum**

```swift
import UIKit
import Components

enum DSBrand: String, CaseIterable {
    case frisbee = "Frisbee"
    case tdm = "TDM"
    case sover = "Sover"
    case kchat = "KCHAT"
    case senseNew = "Sense New"

    // MARK: - Accent Colors (ThemeFirst/Primary/Default)

    func accentColor(for style: UIUserInterfaceStyle) -> UIColor {
        switch self {
        case .frisbee:   return UIColor(hex: "#40B259")
        case .tdm:       return UIColor(hex: style == .dark ? "#3886E1" : "#3E87DD")
        case .sover:     return UIColor(hex: style == .dark ? "#C4944D" : "#C7964F")
        case .kchat:     return UIColor(hex: style == .dark ? "#E9474E" : "#EA5355")
        case .senseNew:  return UIColor(hex: "#7548AD")
        }
    }

    // MARK: - Background Colors

    func backgroundBase(for style: UIUserInterfaceStyle) -> UIColor {
        if style == .dark {
            switch self {
            case .sover:    return UIColor(hex: "#101D2E")
            case .senseNew: return UIColor(hex: "#161419")
            default:        return UIColor(hex: "#1A1A1A")
            }
        }
        return UIColor(hex: "#FFFFFF")
    }

    func backgroundSecond(for style: UIUserInterfaceStyle) -> UIColor {
        if style == .dark {
            switch self {
            case .sover:    return UIColor(hex: "#1C2838")
            case .senseNew: return UIColor(hex: "#2A282E")
            default:        return UIColor(hex: "#313131")
            }
        }
        return UIColor(hex: "#F5F5F5")
    }

    // MARK: - Basic Colors (same across all brands)

    func basicColor8(for style: UIUserInterfaceStyle) -> UIColor {
        style == .dark ? UIColor(hex: "#FFFFFF14") : UIColor(hex: "#00000014")
    }

    func basicColor90(for style: UIUserInterfaceStyle) -> UIColor {
        style == .dark ? UIColor(hex: "#FFFFFFe5") : UIColor(hex: "#000000e5")
    }

    func basicColor50(for style: UIUserInterfaceStyle) -> UIColor {
        style == .dark ? UIColor(hex: "#FFFFFF80") : UIColor(hex: "#00000080")
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
```

**Step 2: Add the new file to the Xcode project**

The file needs to be added to the GalleryApp target in the Xcode project. Since we're working with `project.pbxproj`, we can either:
- Open Xcode and add it manually, OR
- Use a script to add it to the pbxproj

Simplest: place it alongside the other DS files. The Xcode project likely uses folder references or file references — check the pbxproj to confirm other DSColors.swift etc. are listed, then add DSBrand.swift to the same group.

**Step 3: Build and verify**

```bash
cd GalleryApp
xcodebuild -project GalleryApp.xcodeproj -scheme GalleryApp \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add GalleryApp/GalleryApp/DesignSystem/DSBrand.swift
git commit -m "feat: add DSBrand enum with 5 brand color palettes for ChipsView theming"
```

---

### Task 3: Rewrite ChipsViewPreviewVC as Interactive Preview

**Files:**
- Modify: `GalleryApp/GalleryApp/Previews/ChipsViewPreviewVC.swift` (full rewrite)

**Step 1: Write the interactive preview controller**

The screen has two zones:

**Top — Preview Container:**
- A rounded rect view (`backgroundSecond` for the selected brand/theme) centered on screen
- Inside: the live `ChipsView` instance, centered
- Container height ~160pt, full width with 16pt horizontal margins

**Bottom — Controls Panel:**
- Scrollable vertical stack of control rows
- Each row: label (left) + UISegmentedControl (right)
- Rows: State, Size, Theme, Brand

```swift
import UIKit
import Components

final class ChipsViewPreviewVC: UIViewController {

    // MARK: - State

    private var selectedState: ChipsView.State = .default
    private var selectedSize: ChipsView.Size = .small
    private var selectedBrand: DSBrand = .frisbee
    private var selectedStyle: UIUserInterfaceStyle = .unspecified // follows system

    // MARK: - UI

    private let previewContainer = UIView()
    private var currentChip: ChipsView?

    private let stateSegment = UISegmentedControl(items: ["Default", "Active", "Avatar"])
    private let sizeSegment = UISegmentedControl(items: ["32px", "40px"])
    private let themeSegment = UISegmentedControl(items: ["System", "Light", "Dark"])
    private let brandSegment: UISegmentedControl = {
        let items = DSBrand.allCases.map { $0.rawValue }
        return UISegmentedControl(items: items)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = DSColors.backgroundBase
        setupLayout()
        setupControls()
        rebuildChip()
    }

    // MARK: - Layout

    private func setupLayout() {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = DSSpacing.verticalSection
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: DSSpacing.verticalSection),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: DSSpacing.horizontalPadding),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -DSSpacing.horizontalPadding),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -DSSpacing.verticalSection),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -DSSpacing.horizontalPadding * 2)
        ])

        // Preview container
        previewContainer.layer.cornerRadius = DSCornerRadius.card
        previewContainer.clipsToBounds = true
        previewContainer.translatesAutoresizingMaskIntoConstraints = false
        previewContainer.heightAnchor.constraint(equalToConstant: 160).isActive = true
        contentStack.addArrangedSubview(previewContainer)

        // Controls
        let controlsStack = UIStackView()
        controlsStack.axis = .vertical
        controlsStack.spacing = DSSpacing.listItemSpacing
        controlsStack.translatesAutoresizingMaskIntoConstraints = false

        controlsStack.addArrangedSubview(makeControlRow(label: "State", control: stateSegment))
        controlsStack.addArrangedSubview(makeControlRow(label: "Size", control: sizeSegment))
        controlsStack.addArrangedSubview(makeControlRow(label: "Theme", control: themeSegment))
        controlsStack.addArrangedSubview(makeControlRow(label: "Brand", control: brandSegment))

        contentStack.addArrangedSubview(controlsStack)
    }

    private func makeControlRow(label text: String, control: UISegmentedControl) -> UIView {
        let label = UILabel()
        label.font = DSTypography.subhead4M.font
        label.textColor = DSColors.textPrimary
        label.text = text
        label.setContentHuggingPriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [label, control])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        return row
    }

    // MARK: - Controls Setup

    private func setupControls() {
        stateSegment.selectedSegmentIndex = 0
        sizeSegment.selectedSegmentIndex = 0
        themeSegment.selectedSegmentIndex = 0
        brandSegment.selectedSegmentIndex = 0

        stateSegment.addTarget(self, action: #selector(controlChanged), for: .valueChanged)
        sizeSegment.addTarget(self, action: #selector(controlChanged), for: .valueChanged)
        themeSegment.addTarget(self, action: #selector(controlChanged), for: .valueChanged)
        brandSegment.addTarget(self, action: #selector(controlChanged), for: .valueChanged)
    }

    @objc private func controlChanged() {
        // Read state
        switch stateSegment.selectedSegmentIndex {
        case 0: selectedState = .default
        case 1: selectedState = .active
        default: selectedState = .avatar
        }

        selectedSize = sizeSegment.selectedSegmentIndex == 0 ? .small : .medium

        switch themeSegment.selectedSegmentIndex {
        case 1: selectedStyle = .light
        case 2: selectedStyle = .dark
        default: selectedStyle = .unspecified
        }

        selectedBrand = DSBrand.allCases[brandSegment.selectedSegmentIndex]

        rebuildChip()
    }

    // MARK: - Chip Rendering

    private func rebuildChip() {
        currentChip?.removeFromSuperview()

        // Resolve effective style
        let effectiveStyle: UIUserInterfaceStyle
        if selectedStyle == .unspecified {
            effectiveStyle = traitCollection.userInterfaceStyle
        } else {
            effectiveStyle = selectedStyle
        }

        // Update preview container background
        previewContainer.backgroundColor = selectedBrand.backgroundSecond(for: effectiveStyle)

        // Override trait collection on preview container for theme
        if selectedStyle != .unspecified {
            previewContainer.overrideUserInterfaceStyle = selectedStyle
        } else {
            previewContainer.overrideUserInterfaceStyle = .unspecified
        }

        // Build chip
        let colorScheme = selectedBrand.chipsColorScheme(for: effectiveStyle)
        let chip = ChipsView()

        switch selectedState {
        case .default, .active:
            chip.configure(
                text: "Filter option",
                icon: DSIcon.named("user-2", size: 20),
                state: selectedState,
                size: selectedSize,
                colorScheme: colorScheme
            )
        case .avatar:
            chip.configureAvatar(
                name: "Имя",
                avatarImage: createPlaceholderAvatar(
                    size: selectedSize.avatarSize,
                    style: effectiveStyle
                ),
                closeIcon: DSIcon.named("close-s", size: 24),
                size: selectedSize,
                colorScheme: colorScheme
            )
            chip.onClose = { print("Close tapped") }
        }

        chip.translatesAutoresizingMaskIntoConstraints = false
        previewContainer.addSubview(chip)

        NSLayoutConstraint.activate([
            chip.centerXAnchor.constraint(equalTo: previewContainer.centerXAnchor),
            chip.centerYAnchor.constraint(equalTo: previewContainer.centerYAnchor)
        ])

        currentChip = chip
    }

    // MARK: - Avatar Helper

    private func createPlaceholderAvatar(size: CGFloat, style: UIUserInterfaceStyle) -> UIImage {
        let bgColor = style == .dark ? UIColor(hex: "#313131") : UIColor(hex: "#F5F5F5")
        let iconTint = style == .dark ? UIColor(hex: "#FFFFFF4d") : UIColor(hex: "#0000004d")

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { context in
            bgColor.setFill()
            UIBezierPath(
                roundedRect: CGRect(origin: .zero, size: CGSize(width: size, height: size)),
                cornerRadius: size / 2
            ).fill()

            if let personIcon = DSIcon.named("user", size: size * 0.6) {
                let tintedIcon = personIcon.withTintColor(iconTint, renderingMode: .alwaysOriginal)
                let iconSize = size * 0.6
                let iconRect = CGRect(
                    x: (size - iconSize) / 2,
                    y: (size - iconSize) / 2,
                    width: iconSize,
                    height: iconSize
                )
                tintedIcon.draw(in: iconRect)
            }
        }
    }
}
```

**Step 2: Build and run in simulator**

```bash
cd GalleryApp
xcodebuild -project GalleryApp.xcodeproj -scheme GalleryApp \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```
Expected: BUILD SUCCEEDED

Then launch in simulator and verify:
- Navigate to ChipsView from main screen
- Toggle each control and see the chip update
- Try all 5 brands in both light and dark theme
- Verify Default, Active, Avatar states at both 32px and 40px
- Verify close button uses `close-s` icon, not SF Symbol
- Verify colors match Figma for Frisbee brand

**Step 3: Commit**

```bash
git add GalleryApp/GalleryApp/Previews/ChipsViewPreviewVC.swift
git commit -m "feat: interactive ChipsView preview with state/size/theme/brand controls"
```

---

### Task 4: Add DSBrand.swift to Xcode Project

**Files:**
- Modify: `GalleryApp/GalleryApp.xcodeproj/project.pbxproj`

This task may need to be done manually in Xcode or via pbxproj editing. The new `DSBrand.swift` file must be added to the GalleryApp target's Compile Sources build phase, in the same group as the other DesignSystem files.

**Step 1:** Check how existing DS files (DSColors.swift, DSTypography.swift, etc.) are referenced in the pbxproj and replicate for DSBrand.swift.

**Step 2:** Build to confirm file is compiled.

**Step 3:** This is done as part of Task 2 — combined commit.

---

### Summary of Changes

| File | Action | Description |
|------|--------|-------------|
| `Sources/Components/ChipsView.swift` | Modify | Injectable `ChipsColorScheme`, `closeIcon` param, Figma-exact padding, letter spacing |
| `GalleryApp/.../DesignSystem/DSBrand.swift` | Create | 5 brand palettes → `ChipsColorScheme` |
| `GalleryApp/.../Previews/ChipsViewPreviewVC.swift` | Rewrite | Interactive preview with 4 segmented controls |
| `GalleryApp/GalleryApp.xcodeproj/project.pbxproj` | Modify | Add DSBrand.swift to compile sources |

### Execution Order

1. **Task 1** — ChipsView refactor (standalone, no dependencies)
2. **Task 2 + 4** — DSBrand enum + add to Xcode project
3. **Task 3** — Interactive preview (depends on Task 1 + 2)

Each task ends with a build check and commit.
