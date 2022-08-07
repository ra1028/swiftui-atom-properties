@MainActor
public protocol AtomStateProtocol: AnyObject {
    typealias Context = AtomStateContext
    associatedtype Value

    func value(context: Context) -> Value
    func terminate()
    func override(context: Context, with value: Value)
}

public protocol RefreshableAtomStateProtocol: AtomStateProtocol {
    func refresh(context: Context) async -> Value
    func refreshOverride(context: Context, with value: Value) async -> Value
}

public protocol TaskAtomStateProtocol: AtomStateProtocol where Value == Task<Success, Failure> {
    associatedtype Success
    associatedtype Failure: Error

    func value(context: Context) -> Task<Success, Failure>
}
