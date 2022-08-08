@MainActor
public protocol AtomState: AnyObject {
    typealias Context = AtomStateContext
    associatedtype Value

    func value(context: Context) -> Value
    func override(context: Context, with value: Value)
}

public protocol RefreshableAtomState: AtomState {
    func refresh(context: Context) async -> Value
    func refreshOverride(context: Context, with value: Value) async -> Value
}

public protocol AsyncAtomState: RefreshableAtomState where Value == Task<Success, Failure> {
    associatedtype Success
    associatedtype Failure: Error

    func value(context: Context) -> Task<Success, Failure>
}
