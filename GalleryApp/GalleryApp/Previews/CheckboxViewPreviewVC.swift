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

    private lazy var shapeDropdown = DropdownControl()
    private lazy var stateDropdown = DropdownControl()
    private lazy var textDropdown = DropdownControl()
    private let themeSegment = UISegmentedControl(items: ["Light", "Dark"])
    private lazy var brandSegment = UISegmentedControl(items: DSBrand.allCases.map { $0.rawValue })

    // MARK: - Menu Options

    private let shapeOptions: [(String, CheckboxView.Shape)] = [
        ("Square", .square),
        ("Circle", .circle)
    ]

    private let stateOptions: [(String, Bool)] = [
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
        stateDropdown.dismissOptions()
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
        contentStack.addArrangedSubview(hintLabel)

        // Controls stack (below preview)
        contentStack.addArrangedSubview(controlsStack)
        controlsStack.addArrangedSubview(makeControlRow(label: "Shape", control: shapeDropdown))
        controlsStack.addArrangedSubview(makeControlRow(label: "State", control: stateDropdown))
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

        // Shape dropdown
        shapeDropdown.label.text = shapeOptions.first?.0
        shapeDropdown.onTap = { [weak self] in self?.toggleShapeDropdown() }

        // State dropdown
        stateDropdown.label.text = stateOptions.first?.0
        stateDropdown.onTap = { [weak self] in self?.toggleStateDropdown() }

        // Text dropdown
        textDropdown.label.text = textOptions.first?.0
        textDropdown.onTap = { [weak self] in self?.toggleTextDropdown() }
    }

    private func toggleShapeDropdown() {
        stateDropdown.dismissOptions()
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

    private func toggleStateDropdown() {
        shapeDropdown.dismissOptions()
        textDropdown.dismissOptions()
        if stateDropdown.isShowingOptions {
            stateDropdown.dismissOptions()
            return
        }
        let titles = stateOptions.map { $0.0 }
        let selectedIndex = stateOptions.firstIndex { $0.1 == selectedEnabled } ?? 0
        stateDropdown.showOptions(titles: titles, selectedIndex: selectedIndex) { [weak self] index in
            guard let self else { return }
            self.selectedEnabled = self.stateOptions[index].1
            self.stateDropdown.label.text = self.stateOptions[index].0
            self.rebuildCheckbox()
        }
    }

    private func toggleTextDropdown() {
        shapeDropdown.dismissOptions()
        stateDropdown.dismissOptions()
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
        shapeDropdown.dismissOptions()
        stateDropdown.dismissOptions()
        textDropdown.dismissOptions()

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
            text: selectedShowText ? "Content" : nil,
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

// MARK: - DropdownControl

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

    @objc private func tapped() {
        onTap?()
    }

    @objc private func backdropTapped() {
        dismissOptions()
    }

    func showOptions(titles: [String], selectedIndex: Int, onSelect: @escaping (Int) -> Void) {
        dismissOptions()

        guard let window = window else { return }

        let optionsView = DropdownOptionsView(
            titles: titles,
            selectedIndex: selectedIndex
        ) { [weak self] index in
            onSelect(index)
            self?.dismissOptions()
        }

        // Position below this control, aligned to its leading/trailing edges
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

        // Rotate chevron
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

// MARK: - DropdownOptionsView

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
