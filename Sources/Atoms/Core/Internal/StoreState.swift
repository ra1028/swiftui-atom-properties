internal struct StoreState {
    /// Cached atom values.
    var values = [AtomKey: Any]() // TODO: Stop using Any.

    /// Termination processes.
    var terminations = [AtomKey: ContiguousArray<Termination>]()

    /// Update subscriptions from view.
    var subscriptions = [AtomKey: [SubscriptionKey: Subscription]]()
}
