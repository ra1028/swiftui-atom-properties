@MainActor
public protocol AtomLoader {
    associatedtype Value

    typealias Context = AtomLoaderContext<Value>

    func get(context: Context) -> Value

    func handle(context: Context, with value: Value) -> Value

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

public extension AtomLoader {
    func shouldNotifyUpdate(newValue: Value, oldValue: Value) -> Bool {
        true
    }
}

public protocol RefreshableAtomLoader: AtomLoader {
    func refresh(context: Context) async -> Value

    func refresh(context: Context, with value: Value) async -> Value
}

public protocol AsyncAtomLoader: RefreshableAtomLoader where Value == Task<Success, Failure> {
    associatedtype Success
    associatedtype Failure: Error
}
