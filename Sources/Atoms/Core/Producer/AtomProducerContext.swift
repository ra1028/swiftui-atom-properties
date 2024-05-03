@MainActor
internal struct AtomProducerContext<Value, Coordinator> {
    private let store: StoreContext
    private let transaction: Transaction
    private let coordinator: Coordinator
    private let update: @MainActor (Value) -> Void

    init(
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

    var isTerminated: Bool {
        transaction.isTerminated
    }

    var modifierContext: AtomModifierContext<Value> {
        AtomModifierContext(transaction: transaction, update: update)
    }

    var onTermination: (@MainActor () -> Void)? {
        get { transaction.onTermination }
        nonmutating set { transaction.onTermination = newValue }
    }

    func update(with value: Value) {
        update(value)
    }

    func transaction<T>(_ body: @MainActor (AtomTransactionContext<Coordinator>) -> T) -> T {
        transaction.begin()
        let context = AtomTransactionContext(store: store, transaction: transaction, coordinator: coordinator)
        defer { transaction.commit() }
        return body(context)
    }

    func transaction<T>(_ body: @MainActor (AtomTransactionContext<Coordinator>) async throws -> T) async rethrows -> T {
        transaction.begin()
        let context = AtomTransactionContext(store: store, transaction: transaction, coordinator: coordinator)
        defer { transaction.commit() }
        return try await body(context)
    }
}
