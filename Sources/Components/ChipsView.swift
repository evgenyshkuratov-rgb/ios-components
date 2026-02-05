import UIKit

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

        var height: CGFloat {
            switch self {
            case .small: return 32
            case .medium: return 40
            }
        }

        var avatarSize: CGFloat {
            switch self {
            case .small: return 24
            case .medium: return 32
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .small: return 8
            case .medium: return 12
            }
        }
    }

    // MARK: - Public Properties

    public var onClose: (() -> Void)?
    public var onTap: (() -> Void)?

    // MARK: - Private Properties

    private var currentState: State = .default
    private var currentSize: Size = .small

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
        imageView.tintColor = ChipsColors.textPrimary
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let textLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = ChipsColors.textPrimary
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
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        button.tintColor = ChipsColors.textSecondary
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private var heightConstraint: NSLayoutConstraint?
    private var iconWidthConstraint: NSLayoutConstraint?
    private var iconHeightConstraint: NSLayoutConstraint?
    private var avatarWidthConstraint: NSLayoutConstraint?
    private var avatarHeightConstraint: NSLayoutConstraint?

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
    public func configure(
        text: String,
        icon: UIImage? = nil,
        state: State = .default,
        size: Size = .small
    ) {
        currentState = state
        currentSize = size

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
    ///   - size: The size variant (.small = 32pt, .medium = 40pt)
    public func configureAvatar(
        name: String,
        avatarImage: UIImage?,
        size: Size = .small
    ) {
        currentState = .avatar
        currentSize = size

        textLabel.text = name
        textLabel.font = .systemFont(ofSize: 14, weight: .regular)

        avatarImageView.image = avatarImage
        avatarImageView.isHidden = false
        avatarImageView.layer.cornerRadius = size.avatarSize / 2

        iconImageView.isHidden = true
        closeButton.isHidden = false

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

        // Leading constraint pins stack to left edge
        let leadingConstraint = containerStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8)

        // Trailing constraint pins view's right edge to stack's right edge + padding
        // This makes the view's width determined by the stack's content
        let trailingConstraint = trailingAnchor.constraint(equalTo: containerStack.trailingAnchor, constant: 12)

        NSLayoutConstraint.activate([
            heightConstraint!,

            leadingConstraint,
            trailingConstraint,
            containerStack.centerYAnchor.constraint(equalTo: centerYAnchor),

            iconWidthConstraint!,
            iconHeightConstraint!,

            avatarWidthConstraint!,
            avatarHeightConstraint!,

            closeButton.widthAnchor.constraint(equalToConstant: 28),
            closeButton.heightAnchor.constraint(equalToConstant: 28),

            textLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 224)
        ])
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
            backgroundColor = ChipsColors.backgroundDefault
            iconImageView.tintColor = ChipsColors.textPrimary
            textLabel.textColor = ChipsColors.textPrimary
            textLabel.font = .systemFont(ofSize: 14, weight: .medium)

        case .active:
            backgroundColor = ChipsColors.backgroundActive
            iconImageView.tintColor = ChipsColors.textPrimary
            textLabel.textColor = ChipsColors.textPrimary
            textLabel.font = .systemFont(ofSize: 14, weight: .medium)

        case .avatar:
            backgroundColor = ChipsColors.backgroundDefault
            textLabel.textColor = ChipsColors.textPrimary
            textLabel.font = .systemFont(ofSize: 14, weight: .regular)
        }

        setNeedsLayout()
    }

    @objc private func closeButtonTapped() {
        onClose?()
    }

    @objc private func viewTapped() {
        onTap?()
    }
}

// MARK: - ChipsColors

/// Color constants for ChipsView component.
public enum ChipsColors {
    /// Primary green color (#40B259)
    public static let backgroundActive = UIColor(red: 64/255, green: 178/255, blue: 89/255, alpha: 1)

    /// 8% black background
    public static let backgroundDefault = UIColor(white: 0, alpha: 0.08)

    /// 90% black text
    public static let textPrimary = UIColor(white: 0, alpha: 0.9)

    /// 60% black text for secondary elements
    public static let textSecondary = UIColor(white: 0, alpha: 0.6)
}
