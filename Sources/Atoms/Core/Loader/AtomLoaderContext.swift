/// The context structure that to interact with an atom store.
@MainActor
public struct AtomLoaderContext<Value, Coordinator> {
    @usableFromInline
    internal let _store: StoreContext
    @usableFromInline
    internal let _transaction: Transaction
    @usableFromInline
    internal let _coordinator: Coordinator
    @usableFromInline
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

    internal func update(with value: Value, updatesChildrenOnNextRunLoop: Bool = false) {
        _update(value, updatesChildrenOnNextRunLoop)
    }

    internal func addTermination(_ termination: @MainActor @escaping () -> Void) {
        _transaction.addTermination(Termination(termination))
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
