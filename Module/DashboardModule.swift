import UIKit

public enum Dashboard: ModuleDescription {
    public final class View: UIViewController {
        internal var interactor: ((Operation) -> Void)?
        
        public override func loadView() {
            super.loadView()
            view.backgroundColor = .white
            
            let button = UIButton()
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setTitle("Show detail", for: .normal)
            button.setTitleColor(.blue, for: .normal)
            button.addTarget(self, action: #selector(buttonTap), for: .touchUpInside)
            view.addSubview(button)
            NSLayoutConstraint.activate([
                button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                button.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                ])
        }
        
        @objc private func buttonTap() {
            interactor?(.prepareDetail)
        }
    }
    
    public struct Presenter {
        fileprivate let showViewController: (UIViewController) -> Void
        fileprivate let backToSelf: () -> Void
        
        public init(showViewController: @escaping (UIViewController) -> Void, backToSelf: @escaping () -> Void) {
            self.showViewController = showViewController
            self.backToSelf = backToSelf
        }
        
        public init(dashboardView: Dashboard.View) {
            self.showViewController = {
                dashboardView.show($0, sender: nil)
            }
            self.backToSelf = {
                if dashboardView.presentedViewController != nil {
                    dashboardView.dismiss(animated: true, completion: nil)
                } else {
                    dashboardView.navigationController?.popToViewController(dashboardView, animated: true)
                }
            }
        }
    }
    
    public struct State {
        fileprivate var detailModule: Detail.Module?
        public init() {}
    }
    
    public struct Context {
        fileprivate let presenter: Presenter
        public init(presenter: Presenter) {
            self.presenter = presenter
        }
    }
    
    public enum Operation {
        case prepareDetail
        case setupDetail(Detail.Module, view: Detail.View)
        case backFromDetail
    }
    
    public enum Work {
        case present(Presentation)
        public enum Presentation {
            case show(viewController: UIViewController)
            case backToSelf
        }
        
        case perform(Task)
        public enum Task {
            case buildDetail(Detail.State)
        }
    }
}

extension Dashboard.Operation: ModuleOperation {
    public typealias Module = Dashboard
    public var action: Dashboard.Action {
        return { state in
            switch self {
            case .prepareDetail:
                return [.perform(.buildDetail(Detail.State()))]
            case let .setupDetail(module, view):
                state.detailModule = module
                return [.present(.show(viewController: view))]
            case .backFromDetail:
                state.detailModule = nil
                return [.present(.backToSelf)]
            }
        }
    }
}

extension Dashboard.Work: ModuleWork {
    public typealias Module = Dashboard
    public var task: Dashboard.Task {
        return { context, callback in
            switch self {
            case let .present(presentation):
                DispatchQueue.main.async {
                    switch presentation {
                    case let .show(viewController):
                        context.presenter.showViewController(viewController)
                    case .backToSelf:
                        context.presenter.backToSelf()
                    }
                }
            case let .perform(task):
                switch task {
                case let .buildDetail(state):
                    let detailView: Detail.View = .init()
                    let detailModule: Detail.Module
                        = Detail.instantiate(with: state,
                                             in: Detail.Context(presenter: Detail.Presenter(detailView: detailView),
                                                                parentInteractor: callback))
                    detailView.interactor = detailModule.weakPerform()
                    callback(.setupDetail(detailModule, view: detailView))
                }
            }
        }
    }
}
