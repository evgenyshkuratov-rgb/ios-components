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
        sv.spacing = DSSpacing.verticalSection
        sv.alignment = .leading
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = DSColors.backgroundBase
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

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: DSSpacing.verticalSection),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: DSSpacing.horizontalPadding),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -DSSpacing.horizontalPadding),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -DSSpacing.verticalSection),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -DSSpacing.horizontalPadding * 2)
        ])
    }

    private func addChipSections() {
        // Section: Default State
        let defaultSection = makeSectionStack(title: "Default State")

        let defaultSmall = ChipsView()
        defaultSmall.configure(
            text: "Filter option",
            icon: DSIcon.named("user-2"),
            state: .default,
            size: .small
        )
        defaultSection.addArrangedSubview(defaultSmall)

        let defaultMedium = ChipsView()
        defaultMedium.configure(
            text: "Filter option",
            icon: DSIcon.named("user-2"),
            state: .default,
            size: .medium
        )
        defaultSection.addArrangedSubview(defaultMedium)

        // Section: Active State
        let activeSection = makeSectionStack(title: "Active State")

        let activeSmall = ChipsView()
        activeSmall.configure(
            text: "Filter option",
            icon: DSIcon.named("user-2"),
            state: .active,
            size: .small
        )
        activeSection.addArrangedSubview(activeSmall)

        let activeMedium = ChipsView()
        activeMedium.configure(
            text: "Filter option",
            icon: DSIcon.named("user-2"),
            state: .active,
            size: .medium
        )
        activeSection.addArrangedSubview(activeMedium)

        // Section: Avatar State
        let avatarSection = makeSectionStack(title: "Avatar State")

        let avatarSmall = ChipsView()
        avatarSmall.configureAvatar(
            name: "Имя",
            avatarImage: createPlaceholderAvatar(size: 24),
            size: .small
        )
        avatarSmall.onClose = { print("Close tapped on small avatar chip") }
        avatarSection.addArrangedSubview(avatarSmall)

        let avatarMedium = ChipsView()
        avatarMedium.configureAvatar(
            name: "Имя",
            avatarImage: createPlaceholderAvatar(size: 32),
            size: .medium
        )
        avatarMedium.onClose = { print("Close tapped on medium avatar chip") }
        avatarSection.addArrangedSubview(avatarMedium)

        // Section: Without Icon
        let noIconSection = makeSectionStack(title: "Without Icon")

        let noIconSmall = ChipsView()
        noIconSmall.configure(
            text: "No icon chip",
            icon: nil,
            state: .default,
            size: .small
        )
        noIconSection.addArrangedSubview(noIconSmall)
    }

    private func makeSectionStack(title: String) -> UIStackView {
        let label = UILabel()
        label.text = title
        label.font = DSTypography.sectionLabel
        label.textColor = DSColors.textSecondary

        let inner = UIStackView(arrangedSubviews: [label])
        inner.axis = .vertical
        inner.spacing = DSSpacing.chipGap
        inner.alignment = .leading

        stackView.addArrangedSubview(inner)
        return inner
    }

    private func createPlaceholderAvatar(size: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { context in
            DSColors.backgroundSecond.setFill()
            context.fill(CGRect(origin: .zero, size: CGSize(width: size, height: size)))

            if let personIcon = DSIcon.named("user", size: size * 0.6) {
                let tintedIcon = personIcon.withTintColor(DSColors.textTertiary, renderingMode: .alwaysOriginal)
                let iconSize = size * 0.6
                let iconRect = CGRect(
                    x: (size - iconSize) / 2,
                    y: (size - iconSize) / 2,
                    width: iconSize,
                    height: iconSize
                )
                tintedIcon.draw(in: iconRect)
            }
        }
    }
}
