import UIKit
import Components

final class ChipsViewPreviewVC: UIViewController {

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 24
        sv.alignment = .leading
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupLayout()
        addChipSections()
    }

    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
    }

    private func addChipSections() {
        // Section: Default State
        addSection(title: "Default State")

        let defaultSmall = ChipsView()
        defaultSmall.configure(
            text: "Filter option",
            icon: UIImage(systemName: "person.2.fill"),
            state: .default,
            size: .small
        )
        stackView.addArrangedSubview(defaultSmall)

        let defaultMedium = ChipsView()
        defaultMedium.configure(
            text: "Filter option",
            icon: UIImage(systemName: "person.2.fill"),
            state: .default,
            size: .medium
        )
        stackView.addArrangedSubview(defaultMedium)

        // Section: Active State
        addSection(title: "Active State")

        let activeSmall = ChipsView()
        activeSmall.configure(
            text: "Filter option",
            icon: UIImage(systemName: "person.2.fill"),
            state: .active,
            size: .small
        )
        stackView.addArrangedSubview(activeSmall)

        let activeMedium = ChipsView()
        activeMedium.configure(
            text: "Filter option",
            icon: UIImage(systemName: "person.2.fill"),
            state: .active,
            size: .medium
        )
        stackView.addArrangedSubview(activeMedium)

        // Section: Avatar State
        addSection(title: "Avatar State")

        let avatarSmall = ChipsView()
        avatarSmall.configureAvatar(
            name: "Имя",
            avatarImage: createPlaceholderAvatar(size: 24),
            size: .small
        )
        avatarSmall.onClose = { print("Close tapped on small avatar chip") }
        stackView.addArrangedSubview(avatarSmall)

        let avatarMedium = ChipsView()
        avatarMedium.configureAvatar(
            name: "Имя",
            avatarImage: createPlaceholderAvatar(size: 32),
            size: .medium
        )
        avatarMedium.onClose = { print("Close tapped on medium avatar chip") }
        stackView.addArrangedSubview(avatarMedium)

        // Section: Without Icon
        addSection(title: "Without Icon")

        let noIconSmall = ChipsView()
        noIconSmall.configure(
            text: "No icon chip",
            icon: nil,
            state: .default,
            size: .small
        )
        stackView.addArrangedSubview(noIconSmall)
    }

    private func addSection(title: String) {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false

        // Add spacing before section (except first)
        if stackView.arrangedSubviews.count > 0 {
            let spacer = UIView()
            spacer.translatesAutoresizingMaskIntoConstraints = false
            spacer.heightAnchor.constraint(equalToConstant: 8).isActive = true
            stackView.addArrangedSubview(spacer)
        }

        stackView.addArrangedSubview(label)
    }

    private func createPlaceholderAvatar(size: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { context in
            UIColor.systemGray4.setFill()
            context.fill(CGRect(origin: .zero, size: CGSize(width: size, height: size)))

            let personIcon = UIImage(systemName: "person.fill")?.withTintColor(.systemGray2, renderingMode: .alwaysOriginal)
            let iconSize = size * 0.6
            let iconRect = CGRect(
                x: (size - iconSize) / 2,
                y: (size - iconSize) / 2,
                width: iconSize,
                height: iconSize
            )
            personIcon?.draw(in: iconRect)
        }
    }
}
