@usableFromInline
@MainActor
internal final class SubscriptionContainer {
    private var subscriptions = [AtomKey: Subscription]()
    private let token = SubscriptionKey.Token()

    nonisolated init() {}

    deinit {
        for subscription in ContiguousArray(subscriptions.values) {
            subscription.unsubscribe()
        }
    }

    func wrapper(location: SourceLocation) -> Wrapper {
        Wrapper(self, token: token, location: location)
    }
}

internal extension SubscriptionContainer {
    @usableFromInline
    @MainActor
    struct Wrapper {
        private weak var container: SubscriptionContainer?

        let key: SubscriptionKey
        let location: SourceLocation

        var subscriptions: [AtomKey: Subscription] {
            get { container?.subscriptions ?? [:] }
            nonmutating set { container?.subscriptions = newValue }
        }

        init(
            _ container: SubscriptionContainer,
            token: SubscriptionKey.Token,
            location: SourceLocation
        ) {
            self.container = container
            self.key = SubscriptionKey(token: token)
            self.location = location
        }
    }
}
