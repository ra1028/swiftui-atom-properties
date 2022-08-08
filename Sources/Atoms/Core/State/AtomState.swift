/// A state protocol that represents an actual implementation of the corresponding atom.
@MainActor
public protocol AtomState: AnyObject {
    /// A type of value to provide.
    associatedtype Value

    /// A type of the context structure that to interact with an atom store.
    typealias Context = AtomStateContext

    /// Returns a value with initiating the update process and caches the value for
    /// the next access.
    func value(context: Context) -> Value

    /// Overrides the value with an arbitrary value.
    func override(with value: Value, context: Context)
}

/// A state protocol that represents an actual implementation of the corresponding atom
/// that provides a refreshable value.
public protocol RefreshableAtomState: AtomState {
    /// Refreshes and awaits until the asynchronous value to be updated.
    func refresh(context: Context) async -> Value

    /// Overrides with the given value and awaits until the value to be updated.
    func refreshOverride(with value: Value, context: Context) async -> Value
}

/// A state protocol that represents an actual implementation of the corresponding atom
/// that handles asynchronous process.
public protocol AsyncAtomState: RefreshableAtomState where Value == Task<Success, Failure> {
    /// A type of success value.
    associatedtype Success

    /// A type of failure value.
    associatedtype Failure: Error

    /// Returns a task with initiating the update process and caches the task for the next access.
    func value(context: Context) -> Task<Success, Failure>
}
