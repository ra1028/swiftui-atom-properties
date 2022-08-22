/// A loader protocol that represents an actual implementation of `ValueAtom`.
public struct ValueAtomLoader<T>: AtomLoader {
    /// A type of value to provide.
    public typealias Value = T

    private let getValue: @MainActor (AtomTransactionContext) -> T

    internal init(getValue: @MainActor @escaping (AtomTransactionContext) -> T) {
        self.getValue = getValue
    }

    /// Returns a new value for the corresponding atom.
    public func get(context: Context) -> T {
        context.transaction(getValue)
    }

    /// Handles updates or cancellation of the passed value.
    public func handle(context: Context, with value: T) -> T {
        value
    }
}
