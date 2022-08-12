@MainActor
internal struct Subscription {
    /// Notify atom update to the view.
    let notifyUpdate: () -> Void

    /// Unsubscribe from the store.
    let unsubscribe: () -> Void
}
