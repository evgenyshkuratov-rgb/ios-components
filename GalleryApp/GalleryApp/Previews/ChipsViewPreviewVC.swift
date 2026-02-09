import UIKit
import Components

final class ChipsViewPreviewVC: UIViewController {

    // MARK: - State

    private var selectedState: ChipsView.State = .default
    private var selectedSize: ChipsView.Size = .small
    private var selectedBrand: DSBrand = .frisbee
    private var selectedStyle: UIUserInterfaceStyle = .unspecified

    // MARK: - UI Elements

    private var currentChip: ChipsView?

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

    private let stateSegment = UISegmentedControl(items: ["Default", "Active", "Avatar"])
    private let sizeSegment = UISegmentedControl(items: ["32px", "40px"])
    private let themeSegment = UISegmentedControl(items: ["System", "Light", "Dark"])
    private lazy var brandSegment = UISegmentedControl(items: DSBrand.allCases.map { $0.rawValue })

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = DSColors.backgroundBase
        setupLayout()
        setupControls()
        rebuildChip()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if selectedStyle == .unspecified,
           traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            rebuildChip()
        }
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

        // Preview container
        contentStack.addArrangedSubview(previewContainer)
        previewContainer.heightAnchor.constraint(equalToConstant: 160).isActive = true

        // Controls stack
        contentStack.addArrangedSubview(controlsStack)

        controlsStack.addArrangedSubview(makeControlRow(label: "State", control: stateSegment))
        controlsStack.addArrangedSubview(makeControlRow(label: "Size", control: sizeSegment))
        controlsStack.addArrangedSubview(makeControlRow(label: "Theme", control: themeSegment))
        controlsStack.addArrangedSubview(makeControlRow(label: "Brand", control: brandSegment))
    }

    private func makeControlRow(label text: String, control: UISegmentedControl) -> UIStackView {
        let label = UILabel()
        label.text = text
        label.font = DSTypography.subhead4M.font
        label.textColor = DSColors.textPrimary
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
        case 2: selectedState = .avatar
        default: break
        }

        // Read size
        switch sizeSegment.selectedSegmentIndex {
        case 0: selectedSize = .small
        case 1: selectedSize = .medium
        default: break
        }

        // Read theme
        switch themeSegment.selectedSegmentIndex {
        case 0: selectedStyle = .unspecified
        case 1: selectedStyle = .light
        case 2: selectedStyle = .dark
        default: break
        }

        // Read brand
        let brandIndex = brandSegment.selectedSegmentIndex
        if brandIndex >= 0, brandIndex < DSBrand.allCases.count {
            selectedBrand = DSBrand.allCases[brandIndex]
        }

        rebuildChip()
    }

    // MARK: - Chip Rebuild

    private func rebuildChip() {
        currentChip?.removeFromSuperview()

        let effectiveStyle: UIUserInterfaceStyle
        if selectedStyle == .unspecified {
            effectiveStyle = traitCollection.userInterfaceStyle
        } else {
            effectiveStyle = selectedStyle
        }

        previewContainer.backgroundColor = selectedBrand.backgroundSecond(for: effectiveStyle)
        previewContainer.overrideUserInterfaceStyle = selectedStyle

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
                avatarImage: createPlaceholderAvatar(size: selectedSize.avatarSize, brand: selectedBrand, style: effectiveStyle),
                closeIcon: DSIcon.named("close-s", size: 24),
                size: selectedSize,
                colorScheme: colorScheme
            )
            chip.onClose = { print("Close tapped") }
        }

        previewContainer.addSubview(chip)
        NSLayoutConstraint.activate([
            chip.centerXAnchor.constraint(equalTo: previewContainer.centerXAnchor),
            chip.centerYAnchor.constraint(equalTo: previewContainer.centerYAnchor)
        ])

        currentChip = chip
    }

    // MARK: - Helpers

    private func createPlaceholderAvatar(size: CGFloat, brand: DSBrand, style: UIUserInterfaceStyle) -> UIImage {
        let bgColor = brand.backgroundSecond(for: style)
        let iconTint = brand.basicColor50(for: style)

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
