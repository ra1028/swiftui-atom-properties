@MainActor
public protocol AtomValue {
    associatedtype Value

    typealias Context = AtomValueContext<Value>

    func get(context: Context) -> Value

    func handleUpdates(context: Context, with value: Value)

    /// Returns a boolean value that determines whether it should notify the value update to
    /// watchers with comparing the given old value and the new value.
    ///
    /// - Parameters:
    ///   - newValue: The new value after update.
    ///   - oldValue: The old value before update.
    ///
    /// - Returns: A boolean value that determines whether it should notify the value update
    ///            to watchers.
    func shouldNotifyUpdate(newValue: Value, oldValue: Value) -> Bool
}

public extension AtomValue {
    func handleUpdates(context: Context, with value: Value) {}

    func shouldNotifyUpdate(newValue: Value, oldValue: Value) -> Bool {
        true
    }
}

public protocol RefreshableAtomValue: AtomValue {
    func refresh(context: Context) -> AsyncStream<Value>

    func refresh(context: Context, with value: Value) -> AsyncStream<Value>
}

public protocol TaskAtomValue: RefreshableAtomValue where Value == Task<Success, Failure> {
    associatedtype Success
    associatedtype Failure: Error
}
