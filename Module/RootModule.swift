import UIKit

public enum Root: ModuleDescription {
    public typealias View = UIWindow
    
    public struct Presenter {
        fileprivate let setRootViewController: (UIViewController) -> Void
        
        public init(setRootViewController: @escaping (UIViewController) -> Void) {
            self.setRootViewController = setRootViewController
        }
        
        public init(window: UIWindow = .init(frame: UIScreen.main.bounds)) {
            self.setRootViewController = {
                window.rootViewController = $0
                window.makeKeyAndVisible()
            }
        }
    }
    
    public struct State {
        fileprivate var dashboardModule: Dashboard.Module?
        public init() {}
    }
    
    public struct Context {
        fileprivate let presenter: Presenter
        public init(presenter: Presenter) {
            self.presenter = presenter
        }
    }
    
    public enum Operation {
        case prepareDashboard
        case setupDashboard(Dashboard.Module, view: Dashboard.View)
    }
    
    public enum Work {
        case buildDashboard(Dashboard.State)
        case show(rootViewController: UIViewController)
    }
}

extension Root.Operation: ModuleOperation {
    public typealias Module = Root
    public var action: Root.Action {
        return { state in
            switch self {
            case .prepareDashboard:
                return [.buildDashboard(Dashboard.State())]
            case let .setupDashboard(module, view):
                state.dashboardModule = module
                return [.show(rootViewController: UINavigationController(rootViewController: view))]
            }
        }
    }
}

extension Root.Work: ModuleWork {
    public typealias Module = Root
    public var task: Root.Task {
        return { context, callback in
            switch self {
            case let .buildDashboard(state):
                let dashboardView: Dashboard.View = .init()
                let dashboardModule: Dashboard.Module
                    = Dashboard.instantiate(with: state,
                                            in: Dashboard.Context(presenter: Dashboard.Presenter(dashboardView: dashboardView)))
                dashboardView.interactor = dashboardModule.weakPerform()
                callback(.setupDashboard(dashboardModule, view: dashboardView))
            case let .show(viewController):
                context.presenter.setRootViewController(viewController)
            }
        }
    }
}
