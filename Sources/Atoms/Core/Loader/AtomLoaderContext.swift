/// The context structure that to interact with an atom store.
@MainActor
public struct AtomLoaderContext<Value, Coordinator> {
    internal let _store: StoreContext
    internal let _transaction: Transaction
    internal let _coordinator: Coordinator
    internal let _update: @MainActor (Value, Bool) -> Void

    internal init(
        store: StoreContext,
        transaction: Transaction,
        coordinator: Coordinator,
        update: @escaping @MainActor (Value, Bool) -> Void
    ) {
        _store = store
        _transaction = transaction
        _coordinator = coordinator
        _update = update
    }

    internal var modifierContext: AtomModifierContext<Value> {
        AtomModifierContext(transaction: _transaction) { value in
            update(with: value)
        }
    }

    internal func update(with value: Value, needsEnsureValueUpdate: Bool = false) {
        _update(value, needsEnsureValueUpdate)
    }

    internal func addTermination(_ termination: @MainActor @escaping () -> Void) {
        _transaction.addTermination(termination)
    }

    internal func transaction<T>(_ body: @MainActor (AtomTransactionContext<Coordinator>) -> T) -> T {
        let context = AtomTransactionContext(store: _store, transaction: _transaction, coordinator: _coordinator)
        defer { _transaction.commit() }
        return body(context)
    }

    internal func transaction<T>(_ body: @MainActor (AtomTransactionContext<Coordinator>) async throws -> T) async rethrows -> T {
        let context = AtomTransactionContext(store: _store, transaction: _transaction, coordinator: _coordinator)
        defer { _transaction.commit() }
        return try await body(context)
    }
}
