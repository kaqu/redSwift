import UIKit
import Module

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    let root: Root.Module = Root.instantiate(with: Root.State(), in: Root.Context(presenter: Root.Presenter.init()), using: InstantExecutor())
    
    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        root.perform(.prepareDashboard)
        return true
    }
}
