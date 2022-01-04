import UIKit

public class MVVMCModalNavigationAppCoordinator: NSObject, MVVMCAppCoordinator {
    private let model: MVVMCModelProtocol
    private let presentingViewController: UIViewController
    private var navigationController: UINavigationController?
    private var modules: [MVVMCModule]
    private var isStarted = false
    private var deferredDeepLink: (chain: [MVVMCNavigationRequest], tab: Int?, completion: (() -> Void)?)?

    required public init(model: MVVMCModelProtocol, presentingViewController: UIViewController, factory: MVVMCFactoryProtocol) {
        self.model = model
        self.presentingViewController = presentingViewController
        self.modules = []

        super.init()
        setupModule(for: factory)
    }

    public func start() {
        if let navigationController = navigationController {
            presentingViewController.present(navigationController, animated: true)
        }

        for module in modules {
            module.coordinator.start()
        }

        isStarted = true

        if let deferredDeepLink = deferredDeepLink {
            self.deepLink(chain: deferredDeepLink.chain, selectedTab: deferredDeepLink.tab, completion: deferredDeepLink.completion)
        }
    }

    private func setupModule(for factory: MVVMCFactoryProtocol) {
        let navigationController = setupNavigationController(prefersLargeTitles: factory.prefersLargeTitles)
        self.navigationController = navigationController
        let coordinator = MVVMCCoordinator(model: model, navigationController: navigationController, factory: factory)
        let module = MVVMCModule(factory: factory, navigationController: navigationController, coordinator: coordinator)
        modules.append(module)
    }

    private func setupNavigationController(prefersLargeTitles: Bool = true) -> UINavigationController {
        let navController = UINavigationController()
        navController.navigationBar.isTranslucent = false
        if #available(iOS 11.0, *) {
            navController.navigationBar.prefersLargeTitles = prefersLargeTitles
        }

        navController.view.backgroundColor = UIColor.white
        return navController
    }

    public func deepLink(chain: [MVVMCNavigationRequest], selectedTab: Int?, completion: (() -> Void)?) {
        guard isStarted else {
            deferredDeepLink = (chain, selectedTab, completion)
            return
        }

        guard let module = modules.first else { return }
        module.navigationController.dismiss(animated: false, completion: nil)
        module.navigationController.popToRootViewController(animated: false)
        var coordinator: MVVMCCoordinatorProtocol? = module.coordinator

        for request in chain {
            coordinator?.request(navigation: request, withData: [:], animated: false)
            coordinator = coordinator?.targetCoordinator
        }
        completion?()
    }

    public func display(request: MVVMCNavigationRequest, animated: Bool) {
        guard let module = modules.first else { return }
        module.coordinator.request(navigation: request, withData: nil, animated: animated)
    }
}
