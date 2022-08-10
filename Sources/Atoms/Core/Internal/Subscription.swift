internal struct Subscription {
    let notify: () -> Void
    let unsubscribe: () -> Void
}
