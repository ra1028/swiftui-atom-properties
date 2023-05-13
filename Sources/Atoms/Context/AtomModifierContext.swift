/// A context structure for notifying modifier value updates.
@MainActor
public struct AtomModifierContext<Value> {
    internal let _transaction: Transaction
    internal let _update: @MainActor (Value) -> Void

    internal init(
        transaction: Transaction,
        update: @escaping @MainActor (Value) -> Void
    ) {
        _transaction = transaction
        _update = update
    }

    /// Notifies value updates.
    ///
    /// - Parameter value: An updated value.
    public func update(with value: Value) {
        _update(value)
    }

    /// Add a termination action to be performed when atom value is updated or released.
    ///
    /// - Parameter termination: A termination action.
    public func addTermination(_ termination: @MainActor @escaping () -> Void) {
        _transaction.addTermination(termination)
    }
}
