@usableFromInline
@MainActor
internal final class SubscriptionContainer {
    private var subscriptions = [AtomKey: Subscription]()

    var wrapper: Wrapper {
        Wrapper(container: self, key: SubscriptionKey(self))
    }

    deinit {
        for subscription in subscriptions.values {
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

        init(container: SubscriptionContainer, key: SubscriptionKey) {
            self.container = container
            self.key = key
        }

        func assign(subscription: Subscription, for key: AtomKey) {
            container?.subscriptions[key] = subscription
        }

        func unassign(for key: AtomKey) {
            container?.subscriptions.removeValue(forKey: key)
        }

        func cleanup() {
            container?.subscriptions.removeAll()
        }
    }
}
