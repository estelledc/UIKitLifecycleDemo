import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else {
            return
        }

        // App 的第一个页面：导航控制器包住列表页，方便观察 push / pop 生命周期。
        let listViewController = ReminderListViewController()
        let navigationController: UINavigationController
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--showcase-guide") {
            _ = listViewController.view
            navigationController = UINavigationController(rootViewController: GuidedExperimentViewController())
        } else if arguments.contains("--showcase-logs") {
            _ = listViewController.view
            navigationController = UINavigationController(rootViewController: DemoLogPanelViewController())
        } else {
            navigationController = UINavigationController(rootViewController: listViewController)
        }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = navigationController
        self.window = window
        window.makeKeyAndVisible()
    }
}
