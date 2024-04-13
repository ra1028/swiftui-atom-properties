@usableFromInline
@MainActor
internal struct Subscriber {
    private weak var state: SubscriberState?

    let key: SubscriberKey
    let location: SourceLocation

    init(_ state: SubscriberState, location: SourceLocation) {
        self.state = state
        self.key = SubscriberKey(token: state.token)
        self.location = location
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
