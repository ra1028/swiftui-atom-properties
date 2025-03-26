@usableFromInline
@MainActor
internal struct Subscriber {
    private weak var state: SubscriberState?

    let key: SubscriberKey

    init(_ state: SubscriberState) {
        self.state = state
        self.key = state.token.key
    }

    var unsubscribe: (@MainActor () -> Void)? {
        get { state?.unsubscribe }
        nonmutating set { state?.unsubscribe = newValue }
    }
}
