@MainActor
public protocol AtomValue {
    associatedtype Value

    typealias Context = AtomValueContext<Value>

    func get(context: Context) -> Value

    // TODO: Override
}

public protocol RefreshableAtomValue: AtomValue {
    func refresh(context: Context) -> AsyncStream<Value>

    func refresh(context: Context, with value: Value) -> AsyncStream<Value>
}

public protocol TaskAtomValue: RefreshableAtomValue where Value == Task<Success, Failure> {
    associatedtype Success
    associatedtype Failure: Error
}
