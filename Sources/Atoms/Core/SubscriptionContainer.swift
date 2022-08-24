@usableFromInline
@MainActor
internal final class SubscriptionContainer {
    private var subscriptions = [AtomKey: Subscription]()

    var wrapper: Wrapper {
        Wrapper(self)
    }

    nonisolated init() {}

    deinit {
        for subscription in ContiguousArray(subscriptions.values) {
            subscription.unsubscribe()
        }
    }
}

internal extension SubscriptionContainer {
    @usableFromInline
    @MainActor
    struct Wrapper {
        private weak var container: SubscriptionContainer?

        let key: SubscriptionKey

        var subscriptions: [AtomKey: Subscription] {
            get { container?.subscriptions ?? [:] }
            nonmutating set { container?.subscriptions = newValue }
        }

        init(_ container: SubscriptionContainer) {
            self.container = container
            self.key = SubscriptionKey(container)
        }
    }
}
