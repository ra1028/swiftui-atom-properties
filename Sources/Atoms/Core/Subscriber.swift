@usableFromInline
@MainActor
internal struct Subscriber {
    private weak var state: SubscriberState?

    let key: SubscriberKey

    init(_ state: SubscriberState) {
        self.state = state
        self.key = SubscriberKey(token: state.token)
    }

    var subscribingKeys: Set<AtomKey> {
        get { state?.subscribingKeys ?? [] }
        nonmutating set { state?.subscribingKeys = newValue }
    }

    var unsubscribe: ((Set<AtomKey>) -> Void)? {
        get { state?.unsubscribe }
        nonmutating set { state?.unsubscribe = newValue }
    }
}
