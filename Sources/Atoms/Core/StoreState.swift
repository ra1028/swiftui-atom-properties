@MainActor
internal struct StoreState {
    var atomStates = [AtomKey: AtomState]()
    var subscriptions = [AtomKey: [SubscriptionKey: Subscription]]()
    var currentTransaction = [AtomKey: Transaction]()

    nonisolated init() {}
}
