@usableFromInline
@MainActor
internal struct Subscriber {
    private weak var state: SubscriberState?

    let key: SubscriberKey

    init(_ state: SubscriberState) {
        self.state = state
        self.key = SubscriberKey(token: state.token)
    }

    var subscribing: Set<AtomKey> {
        get { state?.subscribing.value ?? [] }
        nonmutating set { state?.subscribing.value = newValue }
    }

    var unsubscribe: ((Set<AtomKey>) -> Void)? {
        get { state?.unsubscribe.value }
        nonmutating set { state?.unsubscribe.value = newValue }
    }
}
