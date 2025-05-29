@MainActor
internal final class StoreState {
    var caches = [AtomKey: any AtomCacheProtocol]()
    var states = [AtomKey: any AtomStateProtocol]()
    var subscriptions = [AtomKey: [SubscriberKey: Subscription]]()
    var subscribed = [SubscriberKey: Set<AtomKey>]()
    var scopes = [ScopeKey: Scope]()

    nonisolated init() {}
}
