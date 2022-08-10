internal struct StoreState {
    /// Cached atom values.
    var values = [AtomKey: Any]()

    /// Termination processes.
    var terminations = [AtomKey: ContiguousArray<Termination>]()

    /// Key mapping for subscriptions from view.
    var subscriptions = [AtomKey: [SubscriptionKey: Subscription]]()
}
