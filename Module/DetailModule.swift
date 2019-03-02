import UIKit

public enum Detail: ModuleDescription {
    public final class View: UIViewController {
        internal var interactor: ((Operation) -> Void)?
        
        public override func loadView() {
            super.loadView()
            view.backgroundColor = .white
            
            let button = UIButton()
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setTitle("Bounce", for: .normal)
            button.setTitleColor(.blue, for: .normal)
            button.addTarget(self, action: #selector(buttonTap), for: .touchUpInside)
            view.addSubview(button)
            NSLayoutConstraint.activate([
                button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                button.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                ])
        }
        
        @objc private func buttonTap() {
            interactor?(.bounce)
        }
        
        public override func willMove(toParent parent: UIViewController?) {
            super.willMove(toParent: parent)
            guard parent == nil else { return }
            interactor?(.back)
        }
    }
    
    public struct Presenter {
        public init(detailView: Detail.View) {
        }
    }
    
    public struct State {
        public init() {}
    }
    
    public enum Operation {
        case bounce
        case back
    }
    
    public enum Work {
        case present(Presentation)
        public enum Presentation {}
        
        case perform(Task)
        public enum Task {
            case bounce
            case back
        }
    }
    
    public struct Context {
        fileprivate let presenter: Presenter
        fileprivate let parentInteractor: (Dashboard.Operation) -> Void
        public init(presenter: Presenter, parentInteractor: @escaping (Dashboard.Operation) -> Void) {
            self.presenter = presenter
            self.parentInteractor = parentInteractor
        }
    }
}

extension Detail.Operation: ModuleOperation {
    public typealias Module = Detail
    public var action: Detail.Action {
        return { _ in
            switch self {
            case .bounce:
                return [.perform(.bounce)]
            case .back:
                return [.perform(.back)]
            }
        }
    }
}

extension Detail.Work: ModuleWork {
    public typealias Module = Detail
    public var task: Detail.Task {
        return { context, _ in
            switch self {
            case let .present(presentation):
                DispatchQueue.main.async {
                    switch presentation {}
                }
            case let .perform(task):
                switch task {
                case .bounce:
                    context.parentInteractor(.backFromDetail)
                    context.parentInteractor(.prepareDetail)
                case .back:
                    context.parentInteractor(.backFromDetail)
                }
            }
        }
    }
}
