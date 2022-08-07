@MainActor
public protocol AtomState: AnyObject {
    typealias Context = AtomStateContext
    associatedtype Value

    func value(context: Context) -> Value
    func override(context: Context, with value: Value)
}

public protocol AtomRefreshableState: AtomState {
    func refresh(context: Context) async -> Value
    func refreshOverride(context: Context, with value: Value) async -> Value
}
