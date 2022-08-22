@MainActor
internal struct Subscription {
    let notifyUpdate: () -> Void
    let unsubscribe: () -> Void
}
