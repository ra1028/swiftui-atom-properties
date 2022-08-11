internal struct Subscription {
    /// Notify atom update to the view.
    let notifyUpdate: () -> Void

    /// Cleanup all subscriptions from a container maintained at view.
    let containerCleanup: () -> Void

    /// Unsubscribe from the store.
    let unsubscribe: () -> Void
}
