/// A context structure for notifying modifier value updates.
@MainActor
public struct AtomModifierContext<Value> {
    private let transaction: Transaction
    private let update: @MainActor (Value) -> Void

    internal init(
        transaction: Transaction,
        update: @escaping @MainActor (Value) -> Void
    ) {
        self.transaction = transaction
        self.update = update
    }

    /// A callback to invoke when an atom is released or updated to a new value.
    public var onTermination: (@MainActor () -> Void)? {
        get { transaction.onTermination }
        nonmutating set { transaction.onTermination = newValue }
    }

    /// Notifies value updates.
    ///
    /// - Parameter value: An updated value.
    public func update(with value: Value) {
        self.update(value)
    }
}
