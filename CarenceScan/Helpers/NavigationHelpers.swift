import UIKit

enum NavigationHelpers {
    static func popToRoot(animated: Bool = true) {
        guard let controller = rootNavigationController() else { return }
        controller.popToRootViewController(animated: animated)
    }

    private static func rootNavigationController() -> UINavigationController? {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
        for scene in scenes {
            for window in scene.windows where window.isKeyWindow {
                return findNavigationController(in: window.rootViewController)
            }
        }
        return nil
    }

    private static func findNavigationController(in controller: UIViewController?) -> UINavigationController? {
        if let nav = controller as? UINavigationController { return nav }
        for child in controller?.children ?? [] {
            if let nav = findNavigationController(in: child) { return nav }
        }
        return controller?.navigationController
    }
}
