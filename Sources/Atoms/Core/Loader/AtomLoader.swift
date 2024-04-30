/// A loader protocol that represents an actual implementation of the corresponding atom.
@MainActor
public protocol AtomLoader {
    /// A type of value to provide.
    associatedtype Value

    /// A type to coordinate with the atom.
    associatedtype Coordinator

    /// The context structure to interact with an atom store.
    typealias Context = AtomLoaderContext<Value, Coordinator>

    /// Returns a new value for the corresponding atom.
    func value(context: Context) -> Value

    /// Manage given overridden value updates and cancellations.
    func manageOverridden(value: Value, context: Context) -> Value

    /// Returns a boolean value indicating whether it should notify updates downstream
    /// by checking the equivalence of the given old value and new value.
    func shouldUpdateTransitively(newValue: Value, oldValue: Value) -> Bool

    /// Performs transitive update for dependent atoms.
    func performTransitiveUpdate(_ body: () -> Void)
}

public extension AtomLoader {
    func shouldUpdateTransitively(newValue: Value, oldValue: Value) -> Bool {
        true
    }

    func performTransitiveUpdate(_ body: () -> Void) {
        body()
    }
}

/// A loader protocol that represents an actual implementation of the corresponding atom
/// that provides values asynchronously.
public protocol RefreshableAtomLoader: AtomLoader {
    /// Refreshes and waits until the asynchronous process is finished and returns a final value.
    func refresh(context: Context) async -> Value

    /// Refreshes and waits for the passed value to finish outputting values
    /// and returns a final value.
    func refresh(overridden value: Value, context: Context) async -> Value
}

/// A loader protocol that represents an actual implementation of the corresponding atom
/// that provides a refreshable value.
public protocol AsyncAtomLoader: RefreshableAtomLoader where Value == Task<Success, Failure> {
    /// A type of success value.
    associatedtype Success
    /// A type of failure value.
    associatedtype Failure: Error
}
