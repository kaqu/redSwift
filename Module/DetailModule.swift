//
//  DetailModule.swift
//  Module
//
//  Created by Kacper Kaliński on 01/02/2019.
//  Copyright © 2019 Miquido. All rights reserved.
//

import UIKit

public enum Detail: ModuleDescription {
    public struct State {
        public init() {}
    }

    public enum Change {}

    public enum Task {
        case goBack
    }

    public enum Message {
        case goBack
    }

    public struct Context {
        var parentHandle: (Dashboard.Message) -> Void
        public init(parentHandle: @escaping (Dashboard.Message) -> Void) {
            self.parentHandle = parentHandle
        }
    }

    public static func presenterFactory() -> Presenter {
        final class ViewController: UIViewController {
            public func present(change: Detail.Change) {
                switch change {}
            }

            public typealias Module = Detail

            weak var controller: Detail.Controller?

            public func setup(with controller: Detail.Controller) {
                self.controller = controller
            }

            public override func loadView() {
                super.loadView()
                view.backgroundColor = UIColor.lightGray
                let button = UIButton()
                button.translatesAutoresizingMaskIntoConstraints = false
                button.setTitle("Back", for: .normal)
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
                controller?.handle(.goBack)
            }
        }

        let viewController = ViewController()
        return .init(setup: viewController.setup(with:),
                     present: viewController.present(change:),
                     uiViewController: { viewController })
    }

    public static func initialize(state _: Detail.State) -> (changes: [Detail.Change], tasks: [Detail.Task]) {
        return (changes: [], tasks: [])
    }

    public static func workerFactory(context: Detail.Context) -> (@escaping (Detail.Message) -> Void, Detail.Task) -> Void {
        return { _, task in
            switch task {
                case .goBack:
                    context.parentHandle(.backFromDetail)
            }
        }
    }

    public static func dispatcher(state _: inout Detail.State, message: Detail.Message) -> (changes: [Detail.Change], tasks: [Detail.Task]) {
        switch message {
            case .goBack:
                return (changes: [], tasks: [.goBack])
        }
    }
}
