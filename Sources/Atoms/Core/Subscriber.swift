@usableFromInline
@MainActor
internal struct Subscriber {
    private weak var state: SubscriberState?

    let key: SubscriberKey

    init(_ state: SubscriberState) {
        self.state = state
        self.key = state.token.key
    }

    var subscribing: Set<AtomKey> {
        get { state?.subscribing ?? [] }
        nonmutating set { state?.subscribing = newValue }
    }

    var unsubscribe: (@MainActor (Set<AtomKey>) -> Void)? {
        get { state?.unsubscribe }
        nonmutating set { state?.unsubscribe = newValue }
    }
}
