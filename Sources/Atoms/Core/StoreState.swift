internal struct StoreState {
    var caches = [AtomKey: any AtomCacheProtocol]()
    var states = [AtomKey: any AtomStateProtocol]()
    var subscriptions = [AtomKey: [SubscriptionKey: Subscription]]()
}
