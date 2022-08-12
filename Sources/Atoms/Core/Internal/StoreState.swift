internal struct StoreState {
    var atomStates = [AtomKey: AtomState]()
    var subscriptions = [AtomKey: [SubscriptionKey: Subscription]]()
}

internal struct AtomState {
    var value: Any?  // TODO: Stop using Any.
    var terminations = ContiguousArray<Termination>()
}
