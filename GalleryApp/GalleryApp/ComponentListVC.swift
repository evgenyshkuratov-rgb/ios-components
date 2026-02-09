import UIKit

final class ComponentListVC: UIViewController {

    private let components: [(name: String, description: String, icon: String, viewController: () -> UIViewController)] = [
        ("ChipsView", "Filter chips with Default, Active, and Avatar states", "label-24", { ChipsViewPreviewVC() })
    ]

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.alwaysBounceVertical = true
        return sv
    }()

    private let contentStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let statusLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = DSColors.backgroundBase
        setupLayout()
        buildContent()
        fetchCounts()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Layout

    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    private func buildContent() {
        let pad: CGFloat = DSSpacing.horizontalPadding

        // --- Top spacing ---
        contentStack.addArrangedSubview(spacer(28))

        // --- Logo circle ---
        let logoCircle = BrandCircleView(size: 44, iconName: "grid-view", iconSize: 22)
        contentStack.addArrangedSubview(wrapped(logoCircle, leading: pad))

        contentStack.addArrangedSubview(spacer(20))

        // --- Title ---
        let titleLabel = UILabel()
        DSTypography.title1B.apply(to: titleLabel, text: "Components")
        titleLabel.textColor = DSColors.textPrimary
        contentStack.addArrangedSubview(padded(titleLabel))

        // --- Status line ---
        contentStack.addArrangedSubview(spacer(6))
        DSTypography.subhead3R.apply(to: statusLabel, text: "Loading\u{2026}")
        statusLabel.textColor = DSColors.textTertiary
        contentStack.addArrangedSubview(padded(statusLabel))

        // --- Search bar ---
        contentStack.addArrangedSubview(spacer(24))
        contentStack.addArrangedSubview(padded(SearchBarView()))

        // --- Component cards ---
        contentStack.addArrangedSubview(spacer(28))

        for (index, component) in components.enumerated() {
            let card = ComponentCard(
                name: component.name,
                description: component.description,
                iconName: component.icon
            ) { [weak self] in
                self?.navigateToComponent(at: index)
            }
            contentStack.addArrangedSubview(padded(card))

            if index < components.count - 1 {
                contentStack.addArrangedSubview(spacer(DSSpacing.listItemSpacing))
            }
        }

        contentStack.addArrangedSubview(spacer(48))
    }

    // MARK: - Helpers

    private func spacer(_ height: CGFloat) -> UIView {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: height).isActive = true
        return v
    }

    private func padded(_ child: UIView) -> UIView {
        let wrapper = UIView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        child.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(child)
        NSLayoutConstraint.activate([
            child.topAnchor.constraint(equalTo: wrapper.topAnchor),
            child.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
            child.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: DSSpacing.horizontalPadding),
            child.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: -DSSpacing.horizontalPadding)
        ])
        return wrapper
    }

    private func wrapped(_ child: UIView, leading: CGFloat) -> UIView {
        let wrapper = UIView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        child.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(child)
        NSLayoutConstraint.activate([
            child.topAnchor.constraint(equalTo: wrapper.topAnchor),
            child.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
            child.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: leading)
        ])
        return wrapper
    }

    // MARK: - Navigation

    private func navigateToComponent(at index: Int) {
        let component = components[index]
        let vc = component.viewController()
        vc.title = component.name
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Data Loading

    private func fetchCounts() {
        guard let url = Bundle.main.url(forResource: "design-system-counts", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            DSTypography.subhead3R.apply(to: statusLabel, text: "Components \u{00B7} Icons \u{00B7} Colors")
            return
        }

        var parts: [String] = []

        if let count = json["components"] as? Int {
            var text = "\(count) Component\(count == 1 ? "" : "s")"
            if let time = shortRelativeTime(from: json["components_updated"] as? String) {
                text += " (\(time))"
            }
            parts.append(text)
        }

        if let count = json["icons"] as? Int {
            var text = "\(count) Icons"
            if let time = shortRelativeTime(from: json["icons_updated"] as? String) {
                text += " (\(time))"
            }
            parts.append(text)
        }

        if let count = json["colors"] as? Int {
            var text = "\(count) Colors"
            if let time = shortRelativeTime(from: json["colors_updated"] as? String) {
                text += " (\(time))"
            }
            parts.append(text)
        }

        DSTypography.subhead3R.apply(to: statusLabel, text: parts.joined(separator: "  \u{00B7}  "))
    }

    private func shortRelativeTime(from isoString: String?) -> String? {
        guard let isoString = isoString else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        guard let date = formatter.date(from: isoString) else { return nil }

        let seconds = Int(Date().timeIntervalSince(date))
        let minutes = seconds / 60
        let hours = minutes / 60
        let days = hours / 24

        if days > 0 { return "\(days)d" }
        if hours > 0 { return "\(hours)h" }
        if minutes > 0 { return "\(minutes)m" }
        return "now"
    }
}

// MARK: - Brand Circle (green logo badge)

private final class BrandCircleView: UIView {

    init(size: CGFloat, iconName: String, iconSize: CGFloat) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = DSColors.successDefault
        layer.cornerRadius = size / 2

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: size),
            heightAnchor.constraint(equalToConstant: size)
        ])

        if let icon = DSIcon.named(iconName, size: iconSize) {
            let iv = UIImageView(image: icon)
            iv.tintColor = DSColors.white100
            iv.translatesAutoresizingMaskIntoConstraints = false
            iv.contentMode = .center
            addSubview(iv)
            NSLayoutConstraint.activate([
                iv.centerXAnchor.constraint(equalTo: centerXAnchor),
                iv.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
        }
    }

    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Search Bar (decorative)

private final class SearchBarView: UIView {

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = DSColors.backgroundSecond
        layer.cornerRadius = DSCornerRadius.inputField
        heightAnchor.constraint(equalToConstant: 48).isActive = true

        let iconView = UIImageView()
        if let icon = DSIcon.named("search", size: 20) {
            iconView.image = icon
        }
        iconView.tintColor = DSColors.textTertiary
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .center

        let label = UILabel()
        label.font = DSTypography.body1R.font
        label.text = "Search components\u{2026}"
        label.textColor = DSColors.textTertiary
        label.translatesAutoresizingMaskIntoConstraints = false

        addSubview(iconView)
        addSubview(label)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),

            label.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -14)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Component Card (Wise-style)

private final class ComponentCard: UIView {

    private var onTap: (() -> Void)?

    init(name: String, description: String, iconName: String, onTap: @escaping () -> Void) {
        self.onTap = onTap
        super.init(frame: .zero)

        backgroundColor = DSColors.backgroundSecond
        layer.cornerRadius = DSCornerRadius.card

        // --- Icon circle (white circle on gray card, like Wise) ---
        let circleSize: CGFloat = 52
        let iconCircle = UIView()
        iconCircle.backgroundColor = DSColors.backgroundBase
        iconCircle.layer.cornerRadius = circleSize / 2
        iconCircle.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconCircle.widthAnchor.constraint(equalToConstant: circleSize),
            iconCircle.heightAnchor.constraint(equalToConstant: circleSize)
        ])

        if let icon = DSIcon.named(iconName, size: 24) {
            let iv = UIImageView(image: icon)
            iv.tintColor = DSColors.textPrimary
            iv.translatesAutoresizingMaskIntoConstraints = false
            iv.contentMode = .center
            iconCircle.addSubview(iv)
            NSLayoutConstraint.activate([
                iv.centerXAnchor.constraint(equalTo: iconCircle.centerXAnchor),
                iv.centerYAnchor.constraint(equalTo: iconCircle.centerYAnchor)
            ])
        }

        // --- Text stack ---
        let nameLabel = UILabel()
        DSTypography.subtitle1M.apply(to: nameLabel, text: name)
        nameLabel.textColor = DSColors.textPrimary

        let descLabel = UILabel()
        descLabel.font = DSTypography.subhead2R.font
        descLabel.text = description
        descLabel.textColor = DSColors.textSecondary
        descLabel.numberOfLines = 2

        let textStack = UIStackView(arrangedSubviews: [nameLabel, descLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        // --- Chevron ---
        let chevron = UIImageView()
        if let arrow = DSIcon.named("arrow-right-s", size: 20) {
            chevron.image = arrow
        }
        chevron.tintColor = DSColors.textTertiary
        chevron.contentMode = .center
        chevron.setContentHuggingPriority(.required, for: .horizontal)
        chevron.setContentCompressionResistancePriority(.required, for: .horizontal)

        // --- Horizontal layout ---
        let hStack = UIStackView(arrangedSubviews: [iconCircle, textStack, chevron])
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.spacing = 16
        hStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(hStack)
        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            hStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            hStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            hStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
    }

    required init?(coder: NSCoder) { fatalError() }

    @objc private func handleTap() {
        UIView.animate(withDuration: 0.08, animations: {
            self.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        }) { _ in
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: []) {
                self.transform = .identity
            }
            self.onTap?()
        }
    }
}
