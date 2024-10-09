@MainActor
internal struct AtomProducerContext<Value> {
    private let store: StoreContext
    private let transactionState: TransactionState
    private let update: @MainActor (Value) -> Void

    init(
        store: StoreContext,
        transactionState: TransactionState,
        update: @escaping @MainActor (Value) -> Void
    ) {
        self.store = store
        self.transactionState = transactionState
        self.update = update
    }

    var isTerminated: Bool {
        transactionState.isTerminated
    }

    var onTermination: (@MainActor () -> Void)? {
        get { transactionState.onTermination }
        nonmutating set { transactionState.onTermination = newValue }
    }

    func update(with value: Value) {
        update(value)
    }

    func transaction<T>(_ body: @MainActor (AtomTransactionContext) -> T) -> T {
        transactionState.begin()
        let context = AtomTransactionContext(store: store, transactionState: transactionState)
        defer { transactionState.commit() }
        return body(context)
    }

    #if compiler(>=6)
        func transaction<T, E: Error>(_ body: @MainActor (AtomTransactionContext) async throws(E) -> T) async throws(E) -> T {
            transactionState.begin()
            let context = AtomTransactionContext(store: store, transactionState: transactionState)
            defer { transactionState.commit() }
            return try await body(context)
        }
    #else
        func transaction<T>(_ body: @MainActor (AtomTransactionContext) async throws -> T) async rethrows -> T {
            transactionState.begin()
            let context = AtomTransactionContext(store: store, transactionState: transactionState)
            defer { transactionState.commit() }
            return try await body(context)
        }
    #endif
}
