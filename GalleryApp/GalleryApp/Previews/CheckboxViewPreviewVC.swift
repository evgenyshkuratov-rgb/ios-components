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

    private let hintLabel: UILabel = {
        let label = UILabel()
        label.text = "Tap the checkbox to toggle"
        label.font = DSTypography.subhead3R.font
        label.textColor = DSColors.textTertiary
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let controlsStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = DSSpacing.listItemSpacing
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let shapeSegment = UISegmentedControl(items: ["Square", "Circle"])
    private let stateSegment = UISegmentedControl(items: ["Enabled", "Disabled"])
    private let textSegment = UISegmentedControl(items: ["With text", "Without text"])
    private let themeSegment = UISegmentedControl(items: ["Light", "Dark"])
    private lazy var brandSegment = UISegmentedControl(items: DSBrand.allCases.map { $0.rawValue })

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = DSColors.backgroundBase
        setupLayout()
        setupControls()
        rebuildCheckbox()
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
        contentStack.addArrangedSubview(hintLabel)

        // Controls stack (below preview)
        contentStack.addArrangedSubview(controlsStack)
        controlsStack.addArrangedSubview(makeControlRow(label: "Shape", control: shapeSegment))
        controlsStack.addArrangedSubview(makeControlRow(label: "State", control: stateSegment))
        controlsStack.addArrangedSubview(makeControlRow(label: "Text", control: textSegment))
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
        shapeSegment.selectedSegmentIndex = 0
        stateSegment.selectedSegmentIndex = 0
        textSegment.selectedSegmentIndex = 0
        themeSegment.selectedSegmentIndex = 0
        brandSegment.selectedSegmentIndex = 0

        shapeSegment.addTarget(self, action: #selector(controlChanged), for: .valueChanged)
        stateSegment.addTarget(self, action: #selector(controlChanged), for: .valueChanged)
        textSegment.addTarget(self, action: #selector(controlChanged), for: .valueChanged)
        themeSegment.addTarget(self, action: #selector(controlChanged), for: .valueChanged)
        brandSegment.addTarget(self, action: #selector(controlChanged), for: .valueChanged)
    }

    @objc private func controlChanged() {
        selectedShape = shapeSegment.selectedSegmentIndex == 0 ? .square : .circle
        selectedEnabled = stateSegment.selectedSegmentIndex == 0
        selectedShowText = textSegment.selectedSegmentIndex == 0

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
        let wasChecked = currentCheckbox?.isChecked ?? false
        currentCheckbox?.removeFromSuperview()

        previewContainer.backgroundColor = selectedBrand.backgroundSecond(for: selectedStyle)
        previewContainer.overrideUserInterfaceStyle = selectedStyle

        let colorScheme = selectedBrand.checkboxColorScheme(for: selectedStyle)

        // Load the appropriate checked icon based on shape, tint with accent
        let iconName = selectedShape == .square ? "checkbox-active" : "check-active-small"
        let checkedIcon = DSIcon.named(iconName, size: 24)?
            .withTintColor(colorScheme.checkedFill, renderingMode: .alwaysOriginal)

        let checkbox = CheckboxView()
        checkbox.configure(
            text: selectedShowText ? "Label" : nil,
            shape: selectedShape,
            isChecked: wasChecked,
            isEnabled: selectedEnabled,
            checkedIcon: checkedIcon,
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
