@MainActor
public protocol AtomState: AnyObject {
    typealias Context = AtomStateContext
    associatedtype Value

    func value(context: Context) -> Value
    func terminate()
    func override(context: Context, with value: Value)
}

public protocol RefreshableAtomState: AtomState {
    func refresh(context: Context) async -> Value
    func refreshOverride(context: Context, with value: Value) async -> Value
}
