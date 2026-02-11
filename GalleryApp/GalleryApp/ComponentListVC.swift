import UIKit

final class ComponentListVC: UIViewController {

    private let components: [(name: String, description: String, viewController: () -> UIViewController)] = [
        ("ChipsView", "Filter chips with Default, Active, and Avatar states", { ChipsViewPreviewVC() }),
        ("CheckboxView", "Checkbox with Square and Circle shapes, animated toggle", { CheckboxViewPreviewVC() })
    ]

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.alwaysBounceVertical = true
        sv.keyboardDismissMode = .onDrag
        return sv
    }()

    private let contentStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let cardsContainer: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = DSSpacing.listItemSpacing
        return sv
    }()

    private let statusLabel = UILabel()
    private var componentCardWrappers: [UIView] = []
    private let themeSegment: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Light", "Dark"])
        sc.selectedSegmentIndex = 0
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()

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
        contentStack.addArrangedSubview(spacer(28))
        contentStack.addArrangedSubview(makeLogoRow())
        contentStack.addArrangedSubview(spacer(20))

        let (titleView, statusView) = makeStatusSection()
        contentStack.addArrangedSubview(titleView)
        contentStack.addArrangedSubview(spacer(6))
        contentStack.addArrangedSubview(statusView)

        contentStack.addArrangedSubview(spacer(24))
        contentStack.addArrangedSubview(padded(makeSearchBar()))

        // --- Component cards ---
        contentStack.addArrangedSubview(spacer(28))

        cardsContainer.translatesAutoresizingMaskIntoConstraints = false
        for (index, component) in components.enumerated() {
            let card = ComponentCard(
                name: component.name,
                description: component.description
            ) { [weak self] in
                self?.navigateToComponent(at: index)
            }
            let wrapper = padded(card)
            componentCardWrappers.append(wrapper)
            cardsContainer.addArrangedSubview(wrapper)
        }
        contentStack.addArrangedSubview(cardsContainer)

        contentStack.addArrangedSubview(spacer(48))
    }

    private func makeLogoRow() -> UIView {
        let pad: CGFloat = DSSpacing.horizontalPadding
        let logoRow = UIView()
        logoRow.translatesAutoresizingMaskIntoConstraints = false

        if let logo = DSIcon.coloredNamed("frisbee-logo", height: 44) {
            let logoView = UIImageView(image: logo)
            logoView.contentMode = .scaleAspectFit
            logoView.translatesAutoresizingMaskIntoConstraints = false
            logoRow.addSubview(logoView)
            NSLayoutConstraint.activate([
                logoView.leadingAnchor.constraint(equalTo: logoRow.leadingAnchor, constant: pad),
                logoView.centerYAnchor.constraint(equalTo: logoRow.centerYAnchor),
                logoView.topAnchor.constraint(equalTo: logoRow.topAnchor),
                logoView.bottomAnchor.constraint(equalTo: logoRow.bottomAnchor)
            ])
        }

        themeSegment.setTitleTextAttributes([
            .font: DSTypography.subhead4M.font,
            .foregroundColor: DSColors.textSecondary
        ], for: .normal)
        themeSegment.setTitleTextAttributes([
            .font: DSTypography.subhead4M.font,
            .foregroundColor: DSColors.textPrimary
        ], for: .selected)
        themeSegment.selectedSegmentTintColor = DSColors.backgroundSecond
        themeSegment.backgroundColor = DSColors.chipBackground
        themeSegment.addTarget(self, action: #selector(themeChanged), for: .valueChanged)

        logoRow.addSubview(themeSegment)
        NSLayoutConstraint.activate([
            themeSegment.trailingAnchor.constraint(equalTo: logoRow.trailingAnchor, constant: -pad),
            themeSegment.centerYAnchor.constraint(equalTo: logoRow.centerYAnchor)
        ])

        return logoRow
    }

    private func makeStatusSection() -> (title: UIView, status: UIView) {
        let titleLabel = UILabel()
        DSTypography.title1B.apply(to: titleLabel, text: "Components Library")
        titleLabel.textColor = DSColors.textPrimary

        DSTypography.subhead3R.apply(to: statusLabel, text: "Loading\u{2026}")
        statusLabel.textColor = DSColors.textTertiary

        return (padded(titleLabel), padded(statusLabel))
    }

    private func makeSearchBar() -> SearchBarView {
        let search = SearchBarView()
        search.onTextChanged = { [weak self] query in
            self?.filterComponents(query: query)
        }
        return search
    }

    // MARK: - Search

    private func filterComponents(query: String) {
        let q = query.lowercased().trimmingCharacters(in: .whitespaces)
        for (index, wrapper) in componentCardWrappers.enumerated() {
            let matches = q.isEmpty || components[index].name.lowercased().contains(q)
            wrapper.isHidden = !matches
        }
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

    // MARK: - Theme

    @objc private func themeChanged() {
        let style: UIUserInterfaceStyle = themeSegment.selectedSegmentIndex == 0 ? .light : .dark
        view.window?.overrideUserInterfaceStyle = style
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

// MARK: - Search Bar

private final class SearchBarView: UIView, UITextFieldDelegate {

    var onTextChanged: ((String) -> Void)?

    private let textField: UITextField = {
        let tf = UITextField()
        tf.font = DSTypography.body1R.font
        tf.textColor = DSColors.textPrimary
        tf.clearButtonMode = .whileEditing
        tf.autocorrectionType = .no
        tf.returnKeyType = .search
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = DSColors.backgroundSecond
        layer.cornerRadius = DSCornerRadius.inputField
        heightAnchor.constraint(equalToConstant: 48).isActive = true

        textField.attributedPlaceholder = NSAttributedString(
            string: "Search components\u{2026}",
            attributes: [
                .foregroundColor: DSColors.textTertiary,
                .font: DSTypography.body1R.font
            ]
        )
        textField.delegate = self

        let iconView = UIImageView()
        if let icon = DSIcon.named("search", size: 20) {
            iconView.image = icon
        }
        iconView.tintColor = DSColors.textTertiary
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .center

        addSubview(iconView)
        addSubview(textField)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),

            textField.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            textField.centerYAnchor.constraint(equalTo: centerYAnchor),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14)
        ])

        textField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
    }

    required init?(coder: NSCoder) { fatalError() }

    @objc private func textDidChange() {
        onTextChanged?(textField.text ?? "")
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - Component Card

private final class ComponentCard: UIView {

    private var onTap: (() -> Void)?

    init(name: String, description: String, onTap: @escaping () -> Void) {
        self.onTap = onTap
        super.init(frame: .zero)

        backgroundColor = DSColors.backgroundSecond
        layer.cornerRadius = DSCornerRadius.card

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
        let hStack = UIStackView(arrangedSubviews: [textStack, chevron])
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

    }

    required init?(coder: NSCoder) { fatalError() }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        UIView.animate(withDuration: 0.15, delay: 0, options: [.curveEaseIn, .allowUserInteraction]) {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: [.allowUserInteraction]) {
            self.transform = .identity
        }
        if let touch = touches.first, bounds.contains(touch.location(in: self)) {
            onTap?()
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: [.allowUserInteraction]) {
            self.transform = .identity
        }
    }
}
