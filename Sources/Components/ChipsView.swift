import UIKit

// MARK: - ChipsColorScheme

/// Injectable color scheme for ChipsView component.
/// Provides Frisbee Light mode colors as default fallback.
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

    public static let `default` = ChipsColorScheme(
        backgroundDefault: UIColor(white: 0, alpha: 0.08),
        backgroundActive: UIColor(red: 64/255, green: 178/255, blue: 89/255, alpha: 1),
        textPrimary: UIColor(white: 0, alpha: 0.9),
        closeIconTint: UIColor(white: 0, alpha: 0.5)
    )
}

// MARK: - ChipsView

/// A filter chip component with multiple states and sizes.
///
/// Supports three states:
/// - `default`: Gray background with optional icon and text
/// - `active`: Green background with optional icon and text
/// - `avatar`: Gray background with avatar image, name, and close button
public final class ChipsView: UIView {

    // MARK: - Types

    public enum State {
        case `default`
        case active
        case avatar
    }

    public enum Size {
        case small  // 32pt height
        case medium // 40pt height

        public var height: CGFloat {
            switch self {
            case .small: return 32
            case .medium: return 40
            }
        }

        public var avatarSize: CGFloat {
            switch self {
            case .small: return 24
            case .medium: return 32
            }
        }
    }

    // MARK: - Public Properties

    public var onClose: (() -> Void)?
    public var onTap: (() -> Void)?

    // MARK: - Private Properties

    private var currentState: State = .default
    private var currentSize: Size = .small
    private var colorScheme: ChipsColorScheme = .default

    private static func robotoFont(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let systemFont = UIFont.systemFont(ofSize: size, weight: weight)
        let descriptor = systemFont.fontDescriptor.withFamily("Roboto")
        let font = UIFont(descriptor: descriptor, size: size)
        if font.familyName == "Roboto" { return font }
        return systemFont
    }

    private let containerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let textLabel: UILabel = {
        let label = UILabel()
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private var heightConstraint: NSLayoutConstraint?
    private var iconWidthConstraint: NSLayoutConstraint?
    private var iconHeightConstraint: NSLayoutConstraint?
    private var avatarWidthConstraint: NSLayoutConstraint?
    private var avatarHeightConstraint: NSLayoutConstraint?

    // Dynamic layout constraints
    private var leadingConstraint: NSLayoutConstraint?
    private var trailingConstraint: NSLayoutConstraint?
    private var centerYConstraint: NSLayoutConstraint?
    private var topConstraint: NSLayoutConstraint?
    private var bottomConstraint: NSLayoutConstraint?

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

    /// Configures the chip for default or active state.
    /// - Parameters:
    ///   - text: The text to display
    ///   - icon: Optional icon image (displayed on the left)
    ///   - state: The visual state (.default or .active)
    ///   - size: The size variant (.small = 32pt, .medium = 40pt)
    ///   - colorScheme: Injectable color scheme (defaults to Frisbee Light mode)
    public func configure(
        text: String,
        icon: UIImage? = nil,
        state: State = .default,
        size: Size = .small,
        colorScheme: ChipsColorScheme = .default
    ) {
        currentState = state
        currentSize = size
        self.colorScheme = colorScheme

        textLabel.text = text
        iconImageView.image = icon
        iconImageView.isHidden = icon == nil

        avatarImageView.isHidden = true
        closeButton.isHidden = true

        updateAppearance()
    }

    /// Configures the chip for avatar state with user info and close button.
    /// - Parameters:
    ///   - name: The user's name to display
    ///   - avatarImage: The user's avatar image
    ///   - closeIcon: Optional close icon image (injected, no SF Symbol fallback)
    ///   - size: The size variant (.small = 32pt, .medium = 40pt)
    ///   - colorScheme: Injectable color scheme (defaults to Frisbee Light mode)
    public func configureAvatar(
        name: String,
        avatarImage: UIImage?,
        closeIcon: UIImage? = nil,
        size: Size = .small,
        colorScheme: ChipsColorScheme = .default
    ) {
        currentState = .avatar
        currentSize = size
        self.colorScheme = colorScheme

        textLabel.text = name

        avatarImageView.image = avatarImage
        avatarImageView.isHidden = false
        avatarImageView.layer.cornerRadius = size.avatarSize / 2

        iconImageView.isHidden = true
        closeButton.isHidden = false
        closeButton.setImage(closeIcon?.withRenderingMode(.alwaysTemplate), for: .normal)

        updateAppearance()
    }

    // MARK: - Private Methods

    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 16
        clipsToBounds = true

        // Set content hugging to ensure view wraps content
        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)

        addSubview(containerStack)

        containerStack.addArrangedSubview(avatarImageView)
        containerStack.addArrangedSubview(iconImageView)
        containerStack.addArrangedSubview(textLabel)
        containerStack.addArrangedSubview(closeButton)

        // Initial hidden states
        avatarImageView.isHidden = true
        closeButton.isHidden = true

        setupConstraints()
        setupActions()
        updateAppearance()
    }

    private func setupConstraints() {
        heightConstraint = heightAnchor.constraint(equalToConstant: currentSize.height)
        iconWidthConstraint = iconImageView.widthAnchor.constraint(equalToConstant: 20)
        iconHeightConstraint = iconImageView.heightAnchor.constraint(equalToConstant: 20)
        avatarWidthConstraint = avatarImageView.widthAnchor.constraint(equalToConstant: currentSize.avatarSize)
        avatarHeightConstraint = avatarImageView.heightAnchor.constraint(equalToConstant: currentSize.avatarSize)

        // Dynamic layout constraints (created but managed via updatePadding)
        leadingConstraint = containerStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8)
        trailingConstraint = trailingAnchor.constraint(equalTo: containerStack.trailingAnchor, constant: 12)
        centerYConstraint = containerStack.centerYAnchor.constraint(equalTo: centerYAnchor)
        topConstraint = containerStack.topAnchor.constraint(equalTo: topAnchor, constant: 4)
        bottomConstraint = bottomAnchor.constraint(equalTo: containerStack.bottomAnchor, constant: 4)

        NSLayoutConstraint.activate([
            heightConstraint!,

            leadingConstraint!,
            trailingConstraint!,
            centerYConstraint!,

            iconWidthConstraint!,
            iconHeightConstraint!,

            avatarWidthConstraint!,
            avatarHeightConstraint!,

            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 36),

            textLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 224)
        ])

        // Top/bottom start inactive (used only for avatar state)
        topConstraint?.isActive = false
        bottomConstraint?.isActive = false
    }

    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        addGestureRecognizer(tapGesture)
    }

    private func updateAppearance() {
        heightConstraint?.constant = currentSize.height
        avatarWidthConstraint?.constant = currentSize.avatarSize
        avatarHeightConstraint?.constant = currentSize.avatarSize
        layer.cornerRadius = currentSize.height / 2

        switch currentState {
        case .default:
            backgroundColor = colorScheme.backgroundDefault
            iconImageView.tintColor = colorScheme.textPrimary
            let defaultText = textLabel.text
            textLabel.attributedText = nil
            textLabel.text = defaultText
            textLabel.font = ChipsView.robotoFont(size: 14, weight: .medium)
            textLabel.textColor = colorScheme.textPrimary

        case .active:
            backgroundColor = colorScheme.backgroundActive
            iconImageView.tintColor = colorScheme.textPrimary
            let activeText = textLabel.text
            textLabel.attributedText = nil
            textLabel.text = activeText
            textLabel.font = ChipsView.robotoFont(size: 14, weight: .medium)
            textLabel.textColor = colorScheme.textPrimary

        case .avatar:
            backgroundColor = colorScheme.backgroundDefault
            closeButton.tintColor = colorScheme.closeIconTint
            let font = ChipsView.robotoFont(size: 14, weight: .regular)
            if let text = textLabel.text {
                textLabel.attributedText = NSAttributedString(
                    string: text,
                    attributes: [
                        .font: font,
                        .kern: 0.25,
                        .foregroundColor: colorScheme.textPrimary
                    ]
                )
            }
        }

        updatePadding()
        setNeedsLayout()
    }

    private func updatePadding() {
        switch currentState {
        case .default, .active:
            let leadPad: CGFloat = currentSize == .small ? 8 : 12
            leadingConstraint?.constant = leadPad
            trailingConstraint?.constant = 12

            // Deactivate top/bottom before activating centerY + height
            topConstraint?.isActive = false
            bottomConstraint?.isActive = false
            heightConstraint?.isActive = true
            centerYConstraint?.isActive = true

        case .avatar:
            leadingConstraint?.constant = 4
            trailingConstraint?.constant = 0

            // Deactivate centerY + height, let top/bottom determine height
            centerYConstraint?.isActive = false
            heightConstraint?.isActive = false
            topConstraint?.isActive = true
            topConstraint?.constant = 4
            bottomConstraint?.isActive = true
            bottomConstraint?.constant = 4
        }
    }

    @objc private func closeButtonTapped() {
        onClose?()
    }

    @objc private func viewTapped() {
        onTap?()
    }
}
