@MainActor
internal final class StoreState {
    var caches = [AtomKey: any AtomCacheProtocol]()
    var states = [AtomKey: any AtomStateProtocol]()
    var subscriptions = [AtomKey: [SubscriberKey: Subscription]]()
    var scopes = [ScopeKey: Scope]()

    nonisolated init() {}
}
