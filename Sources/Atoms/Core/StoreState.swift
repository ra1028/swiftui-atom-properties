@MainActor
internal struct StoreState {
    var atomStates = [AtomKey: AtomState]()
    var subscriptions = [AtomKey: [SubscriptionKey: Subscription]]()
    var transactions = [AtomKey: Transaction]()

    nonisolated init() {}
}
