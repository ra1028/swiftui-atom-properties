@MainActor
public protocol AtomValue {
    associatedtype Value

    typealias Context = AtomValueContext<Value>

    func get(context: Context) -> Value

    func startUpdating(context: Context, with value: Value)
}

public extension AtomValue {
    func startUpdating(context: Context, with value: Value) {}
}

public protocol RefreshableAtomValue: AtomValue {
    func refresh(context: Context) -> AsyncStream<Value>

    func refresh(context: Context, with value: Value) -> AsyncStream<Value>
}

public protocol TaskAtomValue: RefreshableAtomValue where Value == Task<Success, Failure> {
    associatedtype Success
    associatedtype Failure: Error
}
