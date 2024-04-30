/// The context structure to interact with an atom store.
@MainActor
public struct AtomLoaderContext<Value, Coordinator> {
    private let store: StoreContext
    private let transaction: Transaction
    private let coordinator: Coordinator
    private let update: @MainActor (Value) -> Void

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

    internal var isTerminated: Bool {
        transaction.isTerminated
    }

    internal var modifierContext: AtomModifierContext<Value> {
        AtomModifierContext(transaction: transaction, update: update)
    }

    internal var onTermination: (@MainActor () -> Void)? {
        get { transaction.onTermination }
        nonmutating set { transaction.onTermination = newValue }
    }

    internal func update(with value: Value) {
        update(value)
    }

    internal func transaction<T>(_ body: @MainActor (AtomTransactionContext<Coordinator>) -> T) -> T {
        transaction.begin()
        let context = AtomTransactionContext(store: store, transaction: transaction, coordinator: coordinator)
        defer { transaction.commit() }
        return body(context)
    }

    internal func transaction<T>(_ body: @MainActor (AtomTransactionContext<Coordinator>) async throws -> T) async rethrows -> T {
        transaction.begin()
        let context = AtomTransactionContext(store: store, transaction: transaction, coordinator: coordinator)
        defer { transaction.commit() }
        return try await body(context)
    }
}
