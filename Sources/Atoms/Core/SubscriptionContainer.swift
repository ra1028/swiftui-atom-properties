@usableFromInline
@MainActor
internal final class SubscriptionContainer {
    private var subscriptions = [AtomKey: Subscription]()
    private var unsubscribe: (([AtomKey]) -> Void)?
    private let token = SubscriptionKey.Token()

    nonisolated init() {}

    deinit {
        unsubscribe?(Array(subscriptions.keys))
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

        var unsubscribe: (([AtomKey]) -> Void)? {
            get { container?.unsubscribe }
            nonmutating set { container?.unsubscribe = newValue }
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
