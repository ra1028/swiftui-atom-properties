/// A loader protocol that represents an actual implementation of the corresponding atom.
@MainActor
public protocol AtomLoader {
    /// A type of value to provide.
    associatedtype Value

    /// A type to coordinate with the atom.
    associatedtype Coordinator

    /// The context structure that to interact with an atom store.
    typealias Context = AtomLoaderContext<Value, Coordinator>

    /// Returns a new value for the corresponding atom.
    func value(context: Context) -> Value

    /// Associates given value and handle updates and cancellations.
    func associateOverridden(value: Value, context: Context) -> Value

    /// Returns a boolean value indicating whether it should notify updates to downstream
    /// by checking the equivalence of the given old value and new value.
    func shouldUpdate(newValue: Value, oldValue: Value) -> Bool
}

public extension AtomLoader {
    func shouldUpdate(newValue: Value, oldValue: Value) -> Bool {
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
    func refreshOverridden(value: Value, context: Context) async -> Value
}

/// A loader protocol that represents an actual implementation of the corresponding atom
/// that provides a refreshable value.
public protocol AsyncAtomLoader: RefreshableAtomLoader where Value == Task<Success, Failure> {
    /// A type of success value.
    associatedtype Success
    /// A type of failure value.
    associatedtype Failure: Error
}
