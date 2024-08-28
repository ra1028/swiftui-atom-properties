internal final class SubscriberState {
    let token = SubscriberKey.Token()
    var subscribing = Set<AtomKey>()
    var unsubscribe: ((Set<AtomKey>) -> Void)?

    init() {}

    deinit {
        unsubscribe?(subscribing)
    }
}
