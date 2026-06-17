import Testing

@testable import Atoms

struct KeepAliveTests {
    struct KeepAliveAtom<T: Hashable & Sendable>: ValueAtom, KeepAlive, Hashable {
        let value: T

        func value(context: Context) -> T {
            value
        }
    }

    struct ScopedKeepAliveAtom<T: Hashable & Sendable>: ValueAtom, KeepAlive, Scoped, Hashable {
        let value: T

        func value(context: Context) -> T {
            value
        }
    }

    @MainActor
    @Test
    func testShouldNotBeReleased() {
        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let context = StoreContext.root(store: store, scopeKey: rootScopeToken.key)
        let atom = KeepAliveAtom(value: 0)
        let key = AtomKey(atom)
        let subscriberState = SubscriberState()
        let subscriber = Subscriber(subscriberState)

        _ = context.watch(atom, subscriber: subscriber, subscription: Subscription())
        #expect(store.caches[key] != nil)

        context.unwatch(atom, subscriber: subscriber)
        #expect(store.caches[key] != nil)
    }

    @MainActor
    @Test
    func testShouldNotBeReleasedWhenNotScoped() {
        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let context = StoreContext.root(store: store, scopeKey: rootScopeToken.key)
        let atom = ScopedKeepAliveAtom(value: 0)
        let key = AtomKey(atom, scopeKey: nil)
        let subscriberState = SubscriberState()
        let subscriber = Subscriber(subscriberState)

        _ = context.watch(atom, subscriber: subscriber, subscription: Subscription())
        #expect(store.caches[key] != nil)

        context.unwatch(atom, subscriber: subscriber)
        #expect(store.caches[key] != nil)
    }

    @MainActor
    @Test
    func testShouldNotBeReleasedUntilScopeIsReleasedWhenOverriddenInScope() {
        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let context = StoreContext.root(store: store, scopeKey: rootScopeToken.key)
        let atom = KeepAliveAtom(value: 0)
        var scopeState: ScopeState! = ScopeState()
        let key = AtomKey(atom, scopeKey: scopeState.token.key)
        let subscriberState = SubscriberState()
        let subscriber = Subscriber(subscriberState)
        let scopedContext = context.scoped(
            scopeID: ScopeID(DefaultScopeID()),
            scopeKey: scopeState.token.key,
            observers: [],
            overrideContainer: OverrideContainer()
                .addingOverride(for: atom) { _ in
                    10
                }
        )

        scopedContext.registerScope(state: scopeState)

        _ = scopedContext.watch(atom, subscriber: subscriber, subscription: Subscription())
        #expect(store.caches[key] != nil)

        scopedContext.unwatch(atom, subscriber: subscriber)
        #expect(store.caches[key] != nil)

        scopeState = nil
        #expect(store.caches[key] == nil)
    }

    @MainActor
    @Test
    func testShouldNotBeReleasedUntilScopeIsReleasedWhenScoped() {
        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let context = StoreContext.root(store: store, scopeKey: rootScopeToken.key)
        let atom = ScopedKeepAliveAtom(value: 0)
        var scopeState: ScopeState! = ScopeState()
        let key = AtomKey(atom, scopeKey: scopeState.token.key)
        let scopedContext = context.scoped(
            scopeID: ScopeID(DefaultScopeID()),
            scopeKey: scopeState.token.key
        )
        let subscriberState = SubscriberState()
        let subscriber = Subscriber(subscriberState)

        scopedContext.registerScope(state: scopeState)

        _ = scopedContext.watch(atom, subscriber: subscriber, subscription: Subscription())
        #expect(store.caches[key] != nil)

        scopedContext.unwatch(atom, subscriber: subscriber)
        #expect(store.caches[key] != nil)

        scopeState = nil
        #expect(store.caches[key] == nil)
    }

    @MainActor
    @Test
    func testShouldBeReleasedWhenScopeIsAlreadyReleasedWhenScoped() {
        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let context = StoreContext.root(store: store, scopeKey: rootScopeToken.key)
        let atom = ScopedKeepAliveAtom(value: 0)
        var scopeState: ScopeState! = ScopeState()
        let key = AtomKey(atom, scopeKey: scopeState.token.key)
        let scopedContext = context.scoped(
            scopeID: ScopeID(DefaultScopeID()),
            scopeKey: scopeState.token.key
        )
        let subscriberState = SubscriberState()
        let subscriber = Subscriber(subscriberState)

        scopedContext.registerScope(state: scopeState)
        scopeState = nil

        _ = scopedContext.watch(atom, subscriber: subscriber, subscription: Subscription())
        #expect(store.caches[key] != nil)

        scopedContext.unwatch(atom, subscriber: subscriber)
        #expect(store.caches[key] == nil)
    }
}
