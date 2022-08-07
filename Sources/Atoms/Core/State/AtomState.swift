@MainActor
public protocol AtomState: AnyObject {
    typealias Context = AtomStateContext
    associatedtype Value

    func value(context: Context) -> Value
    func terminate()
}
