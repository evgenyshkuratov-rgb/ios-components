import UIKit

final class ComponentListVC: UIViewController {

    private let components: [(name: String, description: String, viewController: () -> UIViewController)] = [
        ("ChipsView", "Filter chips with Default, Active, and Avatar states", { ChipsViewPreviewVC() })
    ]

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = DSTypography.caption2R.font
        label.textColor = DSColors.textTertiary
        return label
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
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    private func buildContent() {
        // Status row
        stackView.addArrangedSubview(spacer(DSSpacing.listItemSpacing))

        let statusWrapper = padded(statusLabel)
        stackView.addArrangedSubview(statusWrapper)
        statusLabel.text = "Loading\u{2026}"

        // Title
        stackView.addArrangedSubview(spacer(DSSpacing.listItemSpacing))

        let titleLabel = UILabel()
        titleLabel.text = "Components"
        titleLabel.font = DSTypography.title1B.font
        titleLabel.textColor = DSColors.textPrimary
        stackView.addArrangedSubview(padded(titleLabel))

        // Cards
        stackView.addArrangedSubview(spacer(DSSpacing.verticalSection))

        for (index, component) in components.enumerated() {
            let card = ComponentCardView(name: component.name, description: component.description) { [weak self] in
                self?.navigateToComponent(at: index)
            }
            stackView.addArrangedSubview(padded(card))

            if index < components.count - 1 {
                stackView.addArrangedSubview(spacer(DSSpacing.listItemSpacing))
            }
        }

        stackView.addArrangedSubview(spacer(DSSpacing.verticalSection))
    }

    // MARK: - Helpers

    private func spacer(_ height: CGFloat) -> UIView {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: height).isActive = true
        return v
    }

    private func padded(_ view: UIView) -> UIView {
        let wrapper = UIView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        view.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: wrapper.topAnchor),
            view.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: DSSpacing.horizontalPadding),
            view.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: -DSSpacing.horizontalPadding)
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
            statusLabel.text = "Components \u{00B7} Icons \u{00B7} Colors"
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

        statusLabel.text = parts.joined(separator: "  \u{00B7}  ")
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

// MARK: - ComponentCardView

private final class ComponentCardView: UIView {

    private var onTap: (() -> Void)?

    init(name: String, description: String, onTap: @escaping () -> Void) {
        self.onTap = onTap
        super.init(frame: .zero)

        backgroundColor = DSColors.backgroundSecond
        layer.cornerRadius = DSCornerRadius.card

        let nameLabel = UILabel()
        nameLabel.text = name
        nameLabel.font = DSTypography.title5B.font
        nameLabel.textColor = DSColors.textPrimary

        let descLabel = UILabel()
        descLabel.text = description
        descLabel.font = DSTypography.subhead2R.font
        descLabel.textColor = DSColors.textSecondary
        descLabel.numberOfLines = 2

        let textStack = UIStackView(arrangedSubviews: [nameLabel, descLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        let arrowView = UIImageView()
        if let arrow = DSIcon.named("arrow-right-s", size: 20) {
            arrowView.image = arrow
        }
        arrowView.tintColor = DSColors.textTertiary
        arrowView.contentMode = .center
        arrowView.setContentHuggingPriority(.required, for: .horizontal)
        arrowView.setContentCompressionResistancePriority(.required, for: .horizontal)

        let hStack = UIStackView(arrangedSubviews: [textStack, arrowView])
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.spacing = DSSpacing.chipGap
        hStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(hStack)
        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: topAnchor, constant: DSSpacing.innerCardPadding),
            hStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -DSSpacing.innerCardPadding),
            hStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DSSpacing.innerCardPadding),
            hStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DSSpacing.innerCardPadding)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) { fatalError() }

    @objc private func handleTap() {
        UIView.animate(withDuration: 0.1, animations: {
            self.alpha = 0.7
        }) { _ in
            UIView.animate(withDuration: 0.15) {
                self.alpha = 1.0
            }
            self.onTap?()
        }
    }
}
