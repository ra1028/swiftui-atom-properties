@MainActor
final class SubscriberState {
    let token = SubscriberKey.Token()
    var subscribingKeys = Set<AtomKey>()
    var unsubscribe: ((Set<AtomKey>) -> Void)?

    init() {}

    deinit {
        unsubscribe?(subscribingKeys)
    }
}
