//
//  RootModule.swift
//  Module
//
//  Created by Kacper Kaliński on 01/02/2019.
//  Copyright © 2019 Miquido. All rights reserved.
//

import UIKit

public enum Root: ModuleDescription {
    public static func presenterFactory() -> Presenter {
        let window: UIWindow = .init(frame: UIScreen.main.bounds)
        return .init(setup: { _ in },
                     present: { change in
                         switch change {
                             case let .rootView(viewController):
                                 window.rootViewController = viewController
                                 window.makeKeyAndVisible()
                         }
        })
    }

    public struct State {
        fileprivate var dashboardController: Dashboard.Controller?
        public init() {}
    }

    public enum Change {
        case rootView(UIViewController)
    }

    public enum Task {
        case makeDashboard
    }

    public enum Message {
        case setupDashboard(Dashboard.Controller)
    }

    public typealias Context = Void

    public static func initialize(state _: Root.State) -> (changes: [Root.Change], tasks: [Root.Task]) {
        return (changes: [], tasks: [.makeDashboard])
    }

    public static func workerFactory(context _: Root.Context) -> (@escaping (Root.Message) -> Void, Root.Task) -> Void {
        return { handle, task in
            switch task {
                case .makeDashboard:
                    let dashboardController = Dashboard.build(context: .init(parentHandle: handle), initialState: Dashboard.State())
                    handle(.setupDashboard(dashboardController))
            }
        }
    }

    public static func dispatcher(state: inout Root.State, message: Root.Message) -> (changes: [Root.Change], tasks: [Root.Task]) {
        switch message {
            case let .setupDashboard(controller):
                state.dashboardController = controller
                if let viewController = controller.uiViewController {
                    return (changes: [.rootView(viewController)], tasks: [])
                } else { fatalError() }
        }
    }
}
