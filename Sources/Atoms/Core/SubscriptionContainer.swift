@usableFromInline
@MainActor
internal final class SubscriptionContainer {
    private var subscribingKeys = Set<AtomKey>()
    private var unsubscribe: ((Set<AtomKey>) -> Void)?
    private let token = SubscriptionKey.Token()

    nonisolated init() {}

    deinit {
        unsubscribe?(subscribingKeys)
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

        var subscribingKeys: Set<AtomKey> {
            get { container?.subscribingKeys ?? [] }
            nonmutating set { container?.subscribingKeys = newValue }
        }

        var unsubscribe: ((Set<AtomKey>) -> Void)? {
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
