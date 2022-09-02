@MainActor
internal struct StoreState {
    var atomCaches = [AtomKey: AtomCacheBase]()
    var atomStates = [AtomKey: AtomStateBase]()
    var subscriptions = [AtomKey: [SubscriptionKey: Subscription]]()

    nonisolated init() {}
}
