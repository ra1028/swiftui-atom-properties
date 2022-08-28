@MainActor
internal struct StoreState {
    var atomCaches = [AtomKey: AtomCache]()
    var subscriptions = [AtomKey: [SubscriptionKey: Subscription]]()
    var transactions = [AtomKey: Transaction]()
    #warning("TODO: Avoid using Any")
    var coordinators = [AtomKey: Any]()

    nonisolated init() {}
}
