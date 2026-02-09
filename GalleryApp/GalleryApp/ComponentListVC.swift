import UIKit

final class ComponentListVC: UITableViewController {

    private let components: [(name: String, description: String, viewController: () -> UIViewController)] = [
        ("ChipsView", "Filter chips with Default, Active, and Avatar states", { ChipsViewPreviewVC() })
    ]

    private var componentsCountLabel: UILabel!
    private var iconsCountLabel: UILabel!
    private var colorsCountLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Components"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ComponentCell")
        setupHeaderView()
        fetchCounts()
    }

    // MARK: - Header

    private func makePill(icon: String, text: String) -> (view: UIView, label: UILabel) {
        let imageView = UIImageView(image: UIImage(systemName: icon))
        imageView.tintColor = .secondaryLabel
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 14),
            imageView.heightAnchor.constraint(equalToConstant: 14)
        ])

        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel

        let stack = UIStackView(arrangedSubviews: [imageView, label])
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center

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

        return (pill, label)
    }

    private func setupHeaderView() {
        let componentsPill = makePill(icon: "square.stack.3d.up", text: "Components: ...")
        let iconsPill = makePill(icon: "paintbrush", text: "Icons: ...")
        let colorsPill = makePill(icon: "paintpalette", text: "Colors: ...")

        componentsCountLabel = componentsPill.label
        iconsCountLabel = iconsPill.label
        colorsCountLabel = colorsPill.label

        let pillStack = UIStackView(arrangedSubviews: [
            componentsPill.view, iconsPill.view, colorsPill.view
        ])
        pillStack.axis = .horizontal
        pillStack.spacing = 8
        pillStack.translatesAutoresizingMaskIntoConstraints = false

        let header = UIView()
        header.addSubview(pillStack)
        NSLayoutConstraint.activate([
            pillStack.topAnchor.constraint(equalTo: header.topAnchor, constant: 12),
            pillStack.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),
            pillStack.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -12)
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
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Int] else {
            componentsCountLabel.text = "Components: —"
            iconsCountLabel.text = "Icons: —"
            colorsCountLabel.text = "Colors: —"
            return
        }
        if let count = json["components"] { componentsCountLabel.text = "Components: \(count)" }
        if let count = json["icons"] { iconsCountLabel.text = "Icons: \(count)" }
        if let count = json["colors"] { colorsCountLabel.text = "Colors: \(count)" }
        sizeHeaderToFit()
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
