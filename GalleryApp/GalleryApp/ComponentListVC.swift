import UIKit

final class ComponentListVC: UITableViewController {

    private let components: [(name: String, description: String, viewController: () -> UIViewController)] = [
        ("ChipsView", "Filter chips with Default, Active, and Avatar states", { ChipsViewPreviewVC() })
    ]

    private var componentsCountLabel: UILabel!
    private var iconsCountLabel: UILabel!
    private var colorsCountLabel: UILabel!
    private var componentsTimeLabel: UILabel!
    private var iconsTimeLabel: UILabel!
    private var colorsTimeLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ComponentCell")
        setupHeaderView()
        fetchCounts()
    }

    // MARK: - Header

    private func makePill(text: String) -> (view: UIView, label: UILabel, timeLabel: UILabel) {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel

        let timeLabel = UILabel()
        timeLabel.font = .systemFont(ofSize: 10, weight: .regular)
        timeLabel.textColor = .tertiaryLabel

        let stack = UIStackView(arrangedSubviews: [label, timeLabel])
        stack.axis = .vertical
        stack.spacing = 2

        let pill = UIView()
        pill.backgroundColor = .secondarySystemBackground
        pill.layer.cornerRadius = 12
        pill.layoutMargins = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)

        stack.translatesAutoresizingMaskIntoConstraints = false
        pill.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: pill.layoutMarginsGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: pill.layoutMarginsGuide.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: pill.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: pill.layoutMarginsGuide.trailingAnchor)
        ])

        return (pill, label, timeLabel)
    }

    private func setupHeaderView() {
        let componentsPill = makePill(text: "Components: ...")
        let iconsPill = makePill(text: "Icons: ...")
        let colorsPill = makePill(text: "Colors: ...")

        componentsCountLabel = componentsPill.label
        iconsCountLabel = iconsPill.label
        colorsCountLabel = colorsPill.label
        componentsTimeLabel = componentsPill.timeLabel
        iconsTimeLabel = iconsPill.timeLabel
        colorsTimeLabel = colorsPill.timeLabel

        let pillStack = UIStackView(arrangedSubviews: [
            componentsPill.view, iconsPill.view, colorsPill.view
        ])
        pillStack.axis = .horizontal
        pillStack.spacing = 8
        pillStack.distribution = .fillEqually

        let titleLabel = UILabel()
        titleLabel.text = "Components"
        titleLabel.font = .systemFont(ofSize: 34, weight: .bold)

        let mainStack = UIStackView(arrangedSubviews: [pillStack, titleLabel])
        mainStack.axis = .vertical
        mainStack.spacing = 12
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        let header = UIView()
        header.addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: header.topAnchor, constant: 12),
            mainStack.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -8)
        ])

        tableView.tableHeaderView = header
        sizeHeaderToFit()
    }

    private func sizeHeaderToFit() {
        guard let header = tableView.tableHeaderView else { return }
        header.setNeedsLayout()
        header.layoutIfNeeded()
        header.frame.size.height = header.systemLayoutSizeFitting(
            UIView.layoutFittingCompressedSize
        ).height
        tableView.tableHeaderView = header
    }

    // MARK: - Data Loading

    private func fetchCounts() {
        guard let url = Bundle.main.url(forResource: "design-system-counts", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            componentsCountLabel.text = "Components: —"
            iconsCountLabel.text = "Icons: —"
            colorsCountLabel.text = "Colors: —"
            return
        }
        if let count = json["components"] as? Int { componentsCountLabel.text = "Components: \(count)" }
        if let count = json["icons"] as? Int { iconsCountLabel.text = "Icons: \(count)" }
        if let count = json["colors"] as? Int { colorsCountLabel.text = "Colors: \(count)" }

        componentsTimeLabel.text = relativeTime(from: json["components_updated"] as? String)
        iconsTimeLabel.text = relativeTime(from: json["icons_updated"] as? String)
        colorsTimeLabel.text = relativeTime(from: json["colors_updated"] as? String)

        sizeHeaderToFit()
    }

    private func relativeTime(from isoString: String?) -> String? {
        guard let isoString = isoString else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        guard let date = formatter.date(from: isoString) else { return nil }

        let seconds = Int(Date().timeIntervalSince(date))
        let minutes = seconds / 60
        let hours = minutes / 60
        let days = hours / 24

        if days > 0 { return "Updated \(days)d ago" }
        if hours > 0 { return "Updated \(hours)h ago" }
        if minutes > 0 { return "Updated \(minutes)m ago" }
        return "Updated just now"
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        components.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ComponentCell", for: indexPath)
        let component = components[indexPath.row]

        var config = cell.defaultContentConfiguration()
        config.text = component.name
        config.secondaryText = component.description
        config.secondaryTextProperties.color = .secondaryLabel
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let component = components[indexPath.row]
        let vc = component.viewController()
        vc.title = component.name
        navigationController?.pushViewController(vc, animated: true)
    }
}
