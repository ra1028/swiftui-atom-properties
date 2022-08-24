@MainActor
internal struct StoreState {
    var atomStates = [AtomKey: AtomState]()
    var subscriptions = [AtomKey: [SubscriptionKey: Subscription]]()
    var transactions = [AtomKey: Transaction]()
    #warning("TODO: Avoid using Any")
    var coordinators = [AtomKey: Any]()

    nonisolated init() {}
}
