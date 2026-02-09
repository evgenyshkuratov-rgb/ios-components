import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        configureNavigationBarAppearance()

        let window = UIWindow(frame: UIScreen.main.bounds)
        let navController = UINavigationController(rootViewController: ComponentListVC())
        navController.navigationBar.prefersLargeTitles = true
        navController.navigationBar.tintColor = DSColors.textPrimary
        window.rootViewController = navController
        window.makeKeyAndVisible()
        self.window = window
        return true
    }

    private func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = DSColors.backgroundBase
        appearance.titleTextAttributes = [
            .foregroundColor: DSColors.textPrimary,
            .font: DSTypography.body3M.font
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: DSColors.textPrimary,
            .font: DSTypography.title1B.font
        ]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
}
