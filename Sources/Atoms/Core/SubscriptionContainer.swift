@usableFromInline
@MainActor
internal final class SubscriptionContainer {
    private var subscriptions = [AtomKey: Subscription]()

    nonisolated init() {}

    deinit {
        for subscription in ContiguousArray(subscriptions.values) {
            subscription.unsubscribe()
        }
    }

    func wrapper(location: SourceLocation) -> Wrapper {
        Wrapper(self, location: location)
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

        init(_ container: SubscriptionContainer, location: SourceLocation) {
            self.container = container
            self.key = SubscriptionKey(container, location: location)
        }
    }
}
