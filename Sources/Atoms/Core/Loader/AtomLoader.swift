/// A loader protocol that represents an actual implementation of the corresponding atom.
@MainActor
public protocol AtomLoader {
    /// A type of value to provide.
    associatedtype Value

    /// The context structure that to interact with an atom store.
    typealias Context = AtomLoaderContext<Value>

    /// Returns a new value for the corresponding atom.
    func get(context: Context) -> Value

    /// Handles updates or cancellation of the passed value.
    func handle(context: Context, with value: Value) -> Value

    /// Returns a boolean value indicating whether it should notify updates to downstream
    /// by checking the equivalence of the given old value and new value.
    func shouldNotifyUpdate(newValue: Value, oldValue: Value) -> Bool
}

public extension AtomLoader {
    func shouldNotifyUpdate(newValue: Value, oldValue: Value) -> Bool {
        true
    }
}

/// A loader protocol that represents an actual implementation of the corresponding atom
/// that provides values asynchronously.
public protocol RefreshableAtomLoader: AtomLoader {
    /// Refreshes and awaits until the asynchronous is finished and returns a final value.
    func refresh(context: Context) async -> Value

    /// Refreshes and awaits for the passed value to be finished to yield values
    /// and returns a final value.
    func refresh(context: Context, with value: Value) async -> Value
}

/// A loader protocol that represents an actual implementation of the corresponding atom
/// that provides a refreshable value.
public protocol AsyncAtomLoader: RefreshableAtomLoader where Value == Task<Success, Failure> {
    /// A type of success value.
    associatedtype Success
    /// A type of failure value.
    associatedtype Failure: Error
}
