internal struct StoreState {
    /// Cached atom values.
    var values = [AtomKey: Any]()

    /// Termination processes.
    var terminations = [AtomKey: ContiguousArray<Termination>]()

    /// Key mapping for subscriptions from view.
    /// TODO: Check performance of `[AtomKey: [SubscriptionKey: Subscription]]`.
    var subscriptionKeys = [AtomKey: Set<SubscriptionKey>]()

    /// Subscriptions from view.
    var subscriptions = [SubscriptionKey: Subscription]()
}
