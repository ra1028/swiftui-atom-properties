@MainActor
public struct AtomLoaderContext<Value> {
    @usableFromInline
    internal let _store: StoreContext
    @usableFromInline
    internal let _transaction: Transaction
    @usableFromInline
    internal let _update: @MainActor (Value, Bool) -> Void

    internal init(
        store: StoreContext,
        transaction: Transaction,
        update: @escaping @MainActor (Value, Bool) -> Void
    ) {
        _store = store
        _transaction = transaction
        _update = update
    }

    internal func update(with value: Value, updatesChildrenOnNextRunLoop: Bool = false) {
        _update(value, updatesChildrenOnNextRunLoop)
    }

    internal func addTermination(_ termination: @MainActor @escaping () -> Void) {
        _transaction.addTermination(Termination(termination))
    }

    internal func transaction<T>(_ body: @MainActor (AtomTransactionContext) -> T) -> T {
        let context = AtomTransactionContext(store: _store, transaction: _transaction)
        defer { _transaction.commit() }
        return body(context)
    }

    internal func transaction<T>(_ body: @MainActor (AtomTransactionContext) async throws -> T) async rethrows -> T {
        let context = AtomTransactionContext(store: _store, transaction: _transaction)
        defer { _transaction.commit() }
        return try await body(context)
    }
}
