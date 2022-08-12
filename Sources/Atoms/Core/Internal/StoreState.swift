@MainActor
internal struct StoreState {
    var atomStates = [AtomKey: AtomStateBase]()
    var subscriptions = [AtomKey: [SubscriptionKey: Subscription]]()

    nonisolated init() {}
}
