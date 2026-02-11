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

/// A checkbox component with square and circle shape variants.
///
/// Supports checked/unchecked states with animated transitions, optional text label,
/// and injectable theming via `CheckboxColorScheme`.
///
/// Icons are injected via the `configure` method — the host app loads icons
/// (e.g., via DSIcon) and passes them as UIImage parameters.
public final class CheckboxView: UIView {

    // MARK: - Types

    public enum Shape {
        case square
        case circle
    }

    // MARK: - Layout Constants (from Figma)

    private enum Layout {
        static let outerSize: CGFloat = 24
        static let innerSize: CGFloat = 20
        static let innerInset: CGFloat = 2       // (24 - 20) / 2
        static let borderWidth: CGFloat = 2
        static let squareCornerRadius: CGFloat = 6
        static let circleCornerRadius: CGFloat = 10  // innerSize / 2
        static let textGap: CGFloat = 8
        static let maxWidth: CGFloat = 375
    }

    // MARK: - Public Properties

    /// Called when the checkbox is tapped (after toggling state).
    public var onTap: (() -> Void)?

    /// The current checked state. Use `setChecked(_:animated:)` to change programmatically.
    public private(set) var isChecked: Bool = false

    /// Whether the checkbox responds to taps. Visual appearance updates accordingly.
    public private(set) var isEnabled: Bool = true

    // MARK: - Private Properties

    private var shape: Shape = .square
    private var colorScheme: CheckboxColorScheme = .default
    private var checkedIcon: UIImage?

    // MARK: - Font Helper

    private static func robotoFont(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let systemFont = UIFont.systemFont(ofSize: size, weight: weight)
        let descriptor = systemFont.fontDescriptor.withFamily("Roboto")
        let font = UIFont(descriptor: descriptor, size: size)
        if font.familyName == "Roboto" { return font }
        return systemFont
    }

    private static let robotoRegular14: UIFont = robotoFont(size: 14, weight: .regular)

    // MARK: - Subviews

    private let containerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = Layout.textGap
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    /// 24x24 container holding the border view and checked icon.
    private let checkboxContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        return view
    }()

    /// 20x20 centered border view showing the unchecked state.
    private let borderView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }()

    /// 24x24 image view showing the checked icon.
    private let checkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = false
        imageView.alpha = 0
        return imageView
    }()

    private let textLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

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

    /// Configures the checkbox appearance and state.
    /// - Parameters:
    ///   - text: Optional text label displayed to the right of the checkbox.
    ///   - shape: The checkbox shape (`.square` with 6pt corners or `.circle`).
    ///   - isChecked: Whether the checkbox starts in the checked state.
    ///   - isEnabled: Whether the checkbox responds to tap interactions.
    ///   - checkedIcon: A pre-loaded icon image for the checked state (e.g., loaded via DSIcon).
    ///     The image is rendered as-is (`.alwaysOriginal`). The host app is responsible for
    ///     tinting the icon with `colorScheme.checkedFill` before passing it in.
    ///   - colorScheme: Injectable color scheme (defaults to Frisbee Light mode).
    public func configure(
        text: String? = nil,
        shape: Shape = .square,
        isChecked: Bool = false,
        isEnabled: Bool = true,
        checkedIcon: UIImage? = nil,
        colorScheme: CheckboxColorScheme = .default
    ) {
        self.shape = shape
        self.isChecked = isChecked
        self.isEnabled = isEnabled
        self.colorScheme = colorScheme
        self.checkedIcon = checkedIcon?.withRenderingMode(.alwaysOriginal)

        // Text label
        if let text = text {
            textLabel.isHidden = false
            textLabel.text = text
        } else {
            textLabel.isHidden = true
            textLabel.text = nil
        }

        // Checked icon
        checkImageView.image = self.checkedIcon

        // Accessibility
        accessibilityLabel = text
        accessibilityValue = isChecked ? "checked" : "unchecked"

        updateAppearance()
    }

    /// Toggles the checked state with optional animation.
    public func toggleChecked(animated: Bool = true) {
        setChecked(!isChecked, animated: animated)
    }

    /// Sets the checked state with optional animation.
    public func setChecked(_ checked: Bool, animated: Bool = true) {
        guard checked != isChecked else { return }
        isChecked = checked
        accessibilityValue = isChecked ? "checked" : "unchecked"

        if animated {
            animateToggle(toChecked: checked)
        } else {
            updateCheckedAppearance()
        }
    }

    // MARK: - Private Setup

    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false

        // Content hugging so the view wraps its content
        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)

        addSubview(containerStack)

        // Build checkbox container hierarchy
        checkboxContainer.addSubview(borderView)
        checkboxContainer.addSubview(checkImageView)

        containerStack.addArrangedSubview(checkboxContainer)
        containerStack.addArrangedSubview(textLabel)

        setupConstraints()
        setupActions()
        updateAppearance()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container stack fills the view
            containerStack.topAnchor.constraint(equalTo: topAnchor),
            containerStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerStack.bottomAnchor.constraint(equalTo: bottomAnchor),

            // Max width constraint
            widthAnchor.constraint(lessThanOrEqualToConstant: Layout.maxWidth),

            // Checkbox container: fixed 24x24
            checkboxContainer.widthAnchor.constraint(equalToConstant: Layout.outerSize),
            checkboxContainer.heightAnchor.constraint(equalToConstant: Layout.outerSize),

            // Border view: 20x20 centered in 24x24 container
            borderView.centerXAnchor.constraint(equalTo: checkboxContainer.centerXAnchor),
            borderView.centerYAnchor.constraint(equalTo: checkboxContainer.centerYAnchor),
            borderView.widthAnchor.constraint(equalToConstant: Layout.innerSize),
            borderView.heightAnchor.constraint(equalToConstant: Layout.innerSize),

            // Check image view: fills 24x24 container
            checkImageView.topAnchor.constraint(equalTo: checkboxContainer.topAnchor),
            checkImageView.leadingAnchor.constraint(equalTo: checkboxContainer.leadingAnchor),
            checkImageView.trailingAnchor.constraint(equalTo: checkboxContainer.trailingAnchor),
            checkImageView.bottomAnchor.constraint(equalTo: checkboxContainer.bottomAnchor)
        ])
    }

    private func setupActions() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        addGestureRecognizer(tapGesture)
    }

    // MARK: - Appearance Updates

    private func updateAppearance() {
        isAccessibilityElement = true
        accessibilityTraits = .button

        // Border shape
        let cornerRadius: CGFloat
        switch shape {
        case .square:
            cornerRadius = Layout.squareCornerRadius
        case .circle:
            cornerRadius = Layout.circleCornerRadius
        }
        borderView.layer.cornerRadius = cornerRadius
        borderView.layer.borderWidth = Layout.borderWidth

        // Colors based on enabled state
        let borderColor = isEnabled ? colorScheme.borderEnabled : colorScheme.borderDisabled
        let textColor = isEnabled ? colorScheme.textEnabled : colorScheme.textDisabled

        borderView.layer.borderColor = borderColor.cgColor
        textLabel.font = Self.robotoRegular14
        textLabel.textColor = textColor

        // Checked/unchecked visibility
        updateCheckedAppearance()

        // Interaction
        isUserInteractionEnabled = isEnabled

        setNeedsLayout()
    }

    private func updateCheckedAppearance() {
        borderView.alpha = isChecked ? 0 : 1
        checkImageView.alpha = isChecked ? 1 : 0
        checkImageView.transform = .identity
    }

    // MARK: - Animation

    private func animateToggle(toChecked checked: Bool) {
        if checked {
            // Uncheck -> Check: border fades out, check icon appears with scale spring
            checkImageView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            checkImageView.alpha = 0

            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
                self.borderView.alpha = 0
            })

            UIView.animate(
                withDuration: 0.3,
                delay: 0,
                usingSpringWithDamping: 0.6,
                initialSpringVelocity: 0.8,
                options: .curveEaseOut,
                animations: {
                    self.checkImageView.alpha = 1
                    self.checkImageView.transform = .identity
                }
            )
        } else {
            // Check -> Uncheck: check icon fades out, border fades in
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
                self.checkImageView.alpha = 0
                self.borderView.alpha = 1
            })
        }
    }

    // MARK: - Actions

    @objc private func viewTapped() {
        guard isEnabled else { return }
        toggleChecked(animated: true)
        onTap?()
    }
}
