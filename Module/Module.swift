//
//  Module.swift
//  Module
//
//  Created by Kacper Kaliński on 01/02/2019.
//  Copyright © 2019 Miquido. All rights reserved.
//

public protocol ModuleDescription {
    /// Controller of module based on its description
    /// Controlls and binds all parts of module
    typealias Controller = ModuleController<Self>

    /// State of module
    associatedtype State

    /// What changed internally (how to update view)
    associatedtype Change

    /// What needs to be done externally
    associatedtype Task

    /// What actions it allows
    associatedtype Message

    /// Context of existence in which module operates
    /// It may pass dependencies and services
    /// should not contain other controllers directly
    associatedtype Context

    /// View abstraction used to present changes
    typealias Presenter = ModulePresenter<Self>

    /// Tasks and display changes based on initial state
    /// Called once when module controller becomes initialized
    static func initialize(state: State) -> (changes: [Change], tasks: [Task])

    /// Factory of workers based on given context
    /// Worker executes Tasks generated in module
    static func workerFactory(context: Context) -> (@escaping (Message) -> Void, Task) -> Void
    
    /// Factory of presenters
    static func presenterFactory() -> Presenter

    /// Core logic of the module
    /// Consumes Message with given state that can be mutated
    /// and produces internal changes and external tasks
    static func dispatcher(state: inout State, message: Message) -> (changes: [Change], tasks: [Task])

    /// Factory method creating ModuleController
    /// based on its description, provided context and state
    static func build(context: Context, presenter: Presenter, initialState: State) -> Controller
}

public struct ModulePresenter<Module: ModuleDescription> {
    internal var present: (Module.Change) -> Void
    internal var setup: (Module.Controller) -> Void
    public var uiViewController: () -> UIViewController?
    public var uiView: () ->  UIView?
    
    public init(setup: @escaping (Module.Controller) -> Void,
                present: @escaping (Module.Change) -> Void,
                uiViewController: @escaping () -> UIViewController? = { return nil },
                uiView: @escaping () ->  UIView? = { return nil }) {
        self.setup = setup
        self.present = present
        self.uiViewController = uiViewController
        self.uiView = uiView
    }
}

extension ModuleDescription {
    public static func build(context: Context, presenter: Presenter = Self.presenterFactory(), initialState: State) -> Controller {
        return .init(state: initialState,
                     initialize: Self.initialize(state:),
                     dispatcher: Self.dispatcher(state:message:),
                     worker: Self.workerFactory(context: context),
                     presenter: presenter)
    }
}

public final class ModuleController<Module: ModuleDescription> {
    public var uiViewController: UIViewController? { return presenter.uiViewController() }
    public var uiView: UIView? { return presenter.uiView() }
    private var state: Module.State
    private let dispatcher: (inout Module.State, Module.Message) -> (changes: [Module.Change], tasks: [Module.Task])
    private let worker: (@escaping (Module.Message) -> Void, Module.Task) -> Void
    private var presenter: Module.Presenter

    public init(state: Module.State,
                initialize: (Module.State) -> (changes: [Module.Change], tasks: [Module.Task]),
                dispatcher: @escaping (inout Module.State, Module.Message) -> (changes: [Module.Change], tasks: [Module.Task]),
                worker: @escaping (@escaping (Module.Message) -> Void, Module.Task) -> Void,
                presenter: Module.Presenter) {
        self.state = state
        self.dispatcher = dispatcher
        self.worker = worker
        self.presenter = presenter
        presenter.setup(self)
        let (updates, tasks) = initialize(self.state)
        updates.forEach { presenter.present($0) }
        tasks.forEach { worker(self.handle, $0) }
    }

    /// Perform action based on given message
    public func handle(_ message: Module.Message) {
        let (changes, tasks) = dispatcher(&state, message)
        changes.forEach { presenter.present($0) }
        tasks.forEach { worker(self.handle, $0) }
    }
}
