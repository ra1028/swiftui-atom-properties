/// The context structure to interact with an atom store.
@MainActor
public struct AtomLoaderContext<Value, Coordinator> {
    internal let store: StoreContext
    internal let transaction: Transaction
    internal let coordinator: Coordinator
    internal let update: @MainActor (Value) -> Void

    internal init(
        store: StoreContext,
        transaction: Transaction,
        coordinator: Coordinator,
        update: @escaping @MainActor (Value) -> Void
    ) {
        self.store = store
        self.transaction = transaction
        self.coordinator = coordinator
        self.update = update
    }

    internal var modifierContext: AtomModifierContext<Value> {
        AtomModifierContext(transaction: transaction) { value in
            update(with: value)
        }
    }

    internal func update(with value: Value) {
        update(value)
    }

    internal func addTermination(_ termination: @MainActor @escaping () -> Void) {
        transaction.addTermination(termination)
    }

    internal func transaction<T>(_ body: @MainActor (AtomTransactionContext<Coordinator>) -> T) -> T {
        let context = AtomTransactionContext(store: store, transaction: transaction, coordinator: coordinator)
        defer { transaction.commit() }
        return body(context)
    }

    internal func transaction<T>(_ body: @MainActor (AtomTransactionContext<Coordinator>) async throws -> T) async rethrows -> T {
        let context = AtomTransactionContext(store: store, transaction: transaction, coordinator: coordinator)
        defer { transaction.commit() }
        return try await body(context)
    }
}
