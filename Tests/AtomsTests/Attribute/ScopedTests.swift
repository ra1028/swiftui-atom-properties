import Testing

@testable import Atoms

struct ScopedTests {
    struct ScopedAtom<ID: Hashable, T: Hashable>: ValueAtom, Scoped, Equatable, @unchecked Sendable {
        let key = UniqueKey()
        let scopeID: ID
        let value: T

        func value(context: Context) -> T {
            value
        }
    }

    @Test
    @MainActor
    func testScopedAtomsShouldBeScoped() {
        let scope1Token = ScopeKey.Token()
        let scope2Token = ScopeKey.Token()
        let subscriberState = SubscriberState()
        let subscriber = Subscriber(subscriberState)
        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let context = StoreContext.root(store: store, scopeKey: rootScopeToken.key)
        let scoped1Context = context.scoped(
            scopeID: ScopeID(DefaultScopeID()),
            scopeKey: scope1Token.key
        )
        let scoped2Context = scoped1Context.scoped(
            scopeID: ScopeID(DefaultScopeID()),
            scopeKey: scope2Token.key
        )
        let atom = ScopedAtom(scopeID: DefaultScopeID(), value: 0)
        let scoped1AtomKey = AtomKey(atom, scopeKey: scope1Token.key)
        let scoped2AtomKey = AtomKey(atom, scopeKey: scope2Token.key)

        #expect(scoped1Context.watch(atom, subscriber: subscriber, subscription: Subscription()) == 0)
        #expect(store.caches[scoped1AtomKey] as? AtomCache<ScopedAtom<DefaultScopeID, Int>> == AtomCache(atom: atom, value: 0))
        #expect(store.caches[scoped2AtomKey] == nil)

        scoped1Context.unwatch(atom, subscriber: subscriber)
        #expect(store.caches[scoped1AtomKey] == nil)

        #expect(scoped2Context.watch(atom, subscriber: subscriber, subscription: Subscription()) == 0)
        #expect(store.caches[scoped2AtomKey] as? AtomCache<ScopedAtom<DefaultScopeID, Int>> == AtomCache(atom: atom, value: 0))

        scoped2Context.unwatch(atom, subscriber: subscriber)
        #expect(store.caches[scoped2AtomKey] == nil)
    }

    @Test
    @MainActor
    func testScopedAtomsShouldBeScopedInParticularScope() {
        let scope1Token = ScopeKey.Token()
        let scope2Token = ScopeKey.Token()
        let subscriberState = SubscriberState()
        let subscriber = Subscriber(subscriberState)
        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let context = StoreContext.root(store: store, scopeKey: rootScopeToken.key)
        let scopeID = "Scope 1"
        let scoped1Context = context.scoped(
            scopeID: ScopeID(scopeID),
            scopeKey: scope1Token.key
        )
        let scoped2Context = scoped1Context.scoped(
            scopeID: ScopeID(DefaultScopeID()),
            scopeKey: scope2Token.key
        )
        let atom = ScopedAtom(scopeID: scopeID, value: 0)
        let scoped1AtomKey = AtomKey(atom, scopeKey: scope1Token.key)
        let scoped2AtomKey = AtomKey(atom, scopeKey: scope2Token.key)

        #expect(scoped2Context.watch(atom, subscriber: subscriber, subscription: Subscription()) == 0)
        #expect(store.caches[scoped1AtomKey] as? AtomCache<ScopedAtom<String, Int>> == AtomCache(atom: atom, value: 0))
        #expect(store.caches[scoped2AtomKey] == nil)

        scoped2Context.unwatch(atom, subscriber: subscriber)
        #expect(store.caches[scoped1AtomKey] == nil)
    }

    @Test
    @MainActor
    func testScopedAtomsModifiedAtomsShouldAlsoBeScoped() {
        let scope1Token = ScopeKey.Token()
        let scope2Token = ScopeKey.Token()
        let subscriberState = SubscriberState()
        let subscriber = Subscriber(subscriberState)
        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let context = StoreContext.root(store: store, scopeKey: rootScopeToken.key)
        let scopeID = "Scope 1"
        let scoped1Context = context.scoped(
            scopeID: ScopeID(scopeID),
            scopeKey: scope1Token.key
        )
        let scoped2Context = scoped1Context.scoped(
            scopeID: ScopeID(DefaultScopeID()),
            scopeKey: scope2Token.key
        )
        let baseAtom = ScopedAtom(scopeID: scopeID, value: 0)
        let atom = baseAtom.changes
        let baseAtomKey = AtomKey(baseAtom, scopeKey: nil)
        let atomKey = AtomKey(atom, scopeKey: nil)
        let scoped1BaseAtomKey = AtomKey(baseAtom, scopeKey: scope1Token.key)
        let scoped1AtomKey = AtomKey(atom, scopeKey: scope1Token.key)
        let scoped2BaseAtomKey = AtomKey(baseAtom, scopeKey: scope2Token.key)
        let scoped2AtomKey = AtomKey(atom, scopeKey: scope2Token.key)

        #expect(scoped2Context.watch(atom, subscriber: subscriber, subscription: Subscription()) == 0)
        #expect((store.caches[scoped1BaseAtomKey] as? AtomCache<ScopedAtom<String, Int>>)?.value == 0)
        #expect((store.caches[scoped1AtomKey] as? AtomCache<ModifiedAtom<ScopedAtom<String, Int>, ChangesModifier<Int>>>)?.value == 0)
        #expect(store.caches[scoped2BaseAtomKey] == nil)
        #expect(store.caches[scoped2AtomKey] == nil)
        #expect(store.caches[baseAtomKey] == nil)
        #expect(store.caches[atomKey] == nil)

        scoped2Context.unwatch(atom, subscriber: subscriber)
        #expect(store.caches[scoped1BaseAtomKey] == nil)
        #expect(store.caches[scoped1AtomKey] == nil)
    }
}
