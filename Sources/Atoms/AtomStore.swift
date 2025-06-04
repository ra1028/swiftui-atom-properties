/// An object that stores the state of atoms and its dependency graph.
@MainActor
public final class AtomStore {
    internal var dependencies = [AtomKey: Set<AtomKey>]()
    internal var children = [AtomKey: Set<AtomKey>]()
    internal var caches = [AtomKey: any AtomCacheProtocol]()
    internal var states = [AtomKey: any AtomStateProtocol]()
    internal var subscriptions = [AtomKey: [SubscriberKey: Subscription]]()
    internal var subscribes = [SubscriberKey: Set<AtomKey>]()
    internal var scopes = [ScopeKey: Scope]()

    /// Creates a new store.
    public nonisolated init() {}
}
