@MainActor
public struct AtomLoaderContext<Value> {
    @usableFromInline
    internal let _store: RootAtomStore
    @usableFromInline
    internal let _transaction: Transaction
    @usableFromInline
    internal let _update: @MainActor (Value, Bool) -> Void
    @usableFromInline
    internal let _commitTransaction: @MainActor (Transaction) -> Void

    internal init(
        store: RootAtomStore,
        transaction: Transaction,
        update: @escaping @MainActor (Value, Bool) -> Void,
        commitTransaction: @escaping @MainActor (Transaction) -> Void
    ) {
        _store = store
        _transaction = transaction
        _update = update
        _commitTransaction = commitTransaction
    }

    internal func update(with value: Value, updatesDependentsOnNextRunLoop: Bool = false) {
        _update(value, updatesDependentsOnNextRunLoop)
    }

    internal func addTermination(_ termination: @MainActor @escaping () -> Void) {
        _transaction.terminations.append(Termination(termination))
    }

    internal func transaction<T>(_ body: @MainActor (AtomNodeContext) -> T) -> T {
        let context = AtomNodeContext(store: _store, transaction: _transaction)
        defer { _commitTransaction(_transaction) }
        return body(context)
    }

    internal func transaction<T>(_ body: @MainActor (AtomNodeContext) async throws -> T) async rethrows -> T {
        let context = AtomNodeContext(store: _store, transaction: _transaction)
        defer { _commitTransaction(_transaction) }
        return try await body(context)
    }
}
