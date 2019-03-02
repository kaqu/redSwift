import Foundation

public protocol ModuleOperation {
    associatedtype Module: ModuleDescription where Module.Operation == Self
    var action: Module.Action { get }
}

public protocol ModuleWork {
    associatedtype Module: ModuleDescription where Module.Work == Self
    var task: Module.Task { get }
}

public protocol ModuleDescription {
    typealias Module = ModuleInstance<Self>
    
    associatedtype State
    associatedtype Context
    
    typealias Action = (inout State) -> [Work]
    associatedtype Operation: ModuleOperation where Operation.Module == Self
    
    typealias Callback = (Operation) -> Void
    typealias Task = (Context, @escaping Callback) -> Void
    associatedtype Work: ModuleWork where Work.Module == Self
    
    static var initialization: [Operation] { get }
    static func instantiate(with state: State, in context: Context, using executor: ModuleExecutor) -> ModuleInstance<Self>
}

extension ModuleDescription {
    public static var initialization: [Operation] { return [] }
    public static func instantiate(with state: State, in context: Context, using executor: ModuleExecutor = DispatchQueue(label: "\(Self.self) Executor")) -> ModuleInstance<Self> {
        return .init(state: state, context: context, executor: executor)
    }
}

public final class ModuleInstance<Description: ModuleDescription> {
    public typealias State = Description.State
    public typealias Context = Description.Context
    
    public typealias Action = Description.Action
    public typealias Operation = Description.Operation
    
    public typealias Callback = Description.Callback
    public typealias Work = Description.Work
    public typealias Task = Description.Task
    
    private var state: State
    private let context: Context
    private let executor: ModuleExecutor
    
    public init(state: State, context: Context, executor: ModuleExecutor) {
        self.state = state
        self.context = context
        self.executor = executor
        Description.initialization.forEach(perform)
    }
    
    public func perform(_ operation: Operation) {
        enqueue(operation.action)
    }
    
    public func weakPerform() -> (Operation) -> Void {
        return { [weak self] operation in
            self?.perform(operation)
        }
    }
    
    private let queueLock: NSRecursiveLock = .init()
    private var actionQueue: [Action] = []
    private func enqueue(_ action: @escaping Action) {
        queueLock.lock()
        defer { queueLock.unlock() }
        actionQueue.append(action)
        executeIfNeeded()
    }
    
    private let executionLock: NSRecursiveLock = .init()
    private var isExecuting: Bool = false
    private func executeIfNeeded() {
        executionLock.lock()
        guard !isExecuting else { return executionLock.unlock() }
        isExecuting = true
        executionLock.unlock()
        executor.execute {
            defer {
                self.executionLock.lock()
                self.isExecuting = false
                self.executionLock.unlock()
            }
            defer { self.queueLock.unlock() }
            while ({ () -> Bool in
                self.queueLock.lock()
                return !self.actionQueue.isEmpty
                }()) {
                    let action = self.actionQueue.removeFirst()
                    self.queueLock.unlock()
                    for work in action(&self.state) {
                        work.task(self.context, self.weakPerform())
                    }
            }
        }
    }
}

public protocol ModuleExecutor {
    func execute(_ closure: @escaping () -> Void)
}

public struct InstantExecutor: ModuleExecutor {
    public init() {}
    
    public func execute(_ closure: @escaping () -> Void) {
        closure()
    }
}

extension DispatchQueue: ModuleExecutor {
    public func execute(_ closure: @escaping () -> Void) {
        async(execute: closure)
    }
}

extension OperationQueue: ModuleExecutor {
    public func execute(_ closure: @escaping () -> Void) {
        if OperationQueue.current == self {
            closure()
        } else {
            addOperation(closure)
        }
    }
}
