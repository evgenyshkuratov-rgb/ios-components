import UIKit

final class ComponentListVC: UITableViewController {

    private let components: [(name: String, description: String, viewController: () -> UIViewController)] = [
        ("ChipsView", "Filter chips with Default, Active, and Avatar states", { ChipsViewPreviewVC() })
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Components"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ComponentCell")
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
