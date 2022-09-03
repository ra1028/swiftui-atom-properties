@MainActor
internal struct StoreState {
    var caches = [AtomKey: AtomCacheBase]()
    var states = [AtomKey: AtomStateBase]()
    var subscriptions = [AtomKey: [SubscriptionKey: Subscription]]()

    nonisolated init() {}
}
