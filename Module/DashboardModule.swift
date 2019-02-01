//
//  DashboardModule.swift
//  Module
//
//  Created by Kacper Kaliński on 01/02/2019.
//  Copyright © 2019 Miquido. All rights reserved.
//

import UIKit

public enum Dashboard: ModuleDescription {
    public struct State {
        fileprivate var detailController: Detail.Controller?
        public init() {}
    }

    public enum Change {
        case present(UIViewController)
        case dismissViewController
    }

    public enum Task {
        case prepareDetail(Detail.State)
    }

    public enum Message {
        case showDetail
        case setupDetail(Detail.Controller)
        case backFromDetail
    }

    public struct Context {
        var parentHandle: (Root.Message) -> Void
        public init(parentHandle: @escaping (Root.Message) -> Void) {
            self.parentHandle = parentHandle
        }
    }

    public static func presenterFactory() -> Presenter {
        final class ViewController: UIViewController {
            public func present(change: Dashboard.Change) {
                switch change {
                    case let .present(viewController):
                        present(viewController, animated: true, completion: nil)
                    case .dismissViewController:
                        dismiss(animated: true, completion: nil)
                }
            }

            weak var controller: Dashboard.Controller?

            public func setup(with controller: Dashboard.Controller) {
                self.controller = controller
            }

            public typealias Module = Dashboard

            public override func loadView() {
                super.loadView()
                view.backgroundColor = .white
                let button = UIButton()
                button.translatesAutoresizingMaskIntoConstraints = false
                button.setTitle("Present", for: .normal)
                button.setTitleColor(.blue, for: .normal)
                button.addTarget(self, action: #selector(buttonTap), for: .touchUpInside)
                view.addSubview(button)
                NSLayoutConstraint.activate([
                    button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                    button.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                ])
            }

            @objc
            func buttonTap() {
                controller?.handle(.showDetail)
            }
        }
        let viewController = ViewController()
        return .init(setup: viewController.setup(with:),
                     present: viewController.present(change:),
                     uiViewController: { viewController })
    }

    public static func initialize(state _: Dashboard.State) -> (changes: [Dashboard.Change], tasks: [Dashboard.Task]) {
        return (changes: [], tasks: [])
    }

    public static func workerFactory(context _: Dashboard.Context) -> (@escaping (Dashboard.Message) -> Void, Dashboard.Task) -> Void {
        return { handle, task in
            switch task {
                case let .prepareDetail(state):
                    let controller = Detail.build(context: Detail.Context(parentHandle: handle), initialState: state)
                    handle(.setupDetail(controller))
            }
        }
    }

    public static func dispatcher(state: inout Dashboard.State, message: Dashboard.Message) -> (changes: [Dashboard.Change], tasks: [Dashboard.Task]) {
        switch message {
            case .showDetail:
                return (changes: [], tasks: [.prepareDetail(Detail.State())])
            case let .setupDetail(controller):
                state.detailController = controller
                if let viewController = controller.uiViewController {
                    return (changes: [.present(viewController)], tasks: [])
                } else { fatalError() }
            case .backFromDetail:
                state.detailController = nil
                return (changes: [.dismissViewController], tasks: [])
        }
    }
}
