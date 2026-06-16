import Combine
import Testing

@testable import Atoms

struct AtomViewContextTests {
    @MainActor
    @Test
    func testRead() {
        let atom = TestValueAtom(value: 100)
        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let subscriberState = SubscriberState()
        let context = AtomViewContext(
            store: .root(store: store, scopeKey: rootScopeToken.key),
            subscriber: Subscriber(subscriberState),
            subscription: Subscription()
        )

        #expect(context.read(atom) == 100)
    }

    @MainActor
    @Test
    func testSet() {
        let atom = TestStateAtom(defaultValue: 100)
        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let subscriberState = SubscriberState()
        let context = AtomViewContext(
            store: .root(store: store, scopeKey: rootScopeToken.key),
            subscriber: Subscriber(subscriberState),
            subscription: Subscription()
        )

        #expect(context.watch(atom) == 100)

        context.set(200, for: atom)

        #expect(context.watch(atom) == 200)
    }

    @MainActor
    @Test
    func testRefresh() async {
        let atom = TestPublisherAtom { Just(100) }
        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let subscriberState = SubscriberState()
        let context = AtomViewContext(
            store: .root(store: store, scopeKey: rootScopeToken.key),
            subscriber: Subscriber(subscriberState),
            subscription: Subscription()
        )

        #expect(context.watch(atom).isSuspending)

        let value = await context.refresh(atom).value

        #expect(value == 100)
        #expect(context.watch(atom).value == 100)
    }

    @MainActor
    @Test
    func testReset() {
        let atom = TestStateAtom(defaultValue: 0)
        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let subscriberState = SubscriberState()
        let context = AtomViewContext(
            store: .root(store: store, scopeKey: rootScopeToken.key),
            subscriber: Subscriber(subscriberState),
            subscription: Subscription()
        )

        #expect(context.watch(atom) == 0)

        context[atom] = 100

        #expect(context.watch(atom) == 100)

        context.reset(atom)

        #expect(context.read(atom) == 0)
    }

    @MainActor
    @Test
    func testWatch() {
        let atom = TestStateAtom(defaultValue: 100)
        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let subscriberState = SubscriberState()
        let context = AtomViewContext(
            store: .root(store: store, scopeKey: rootScopeToken.key),
            subscriber: Subscriber(subscriberState),
            subscription: Subscription()
        )

        #expect(context.watch(atom) == 100)

        context[atom] = 200

        #expect(context.watch(atom) == 200)
    }

    @MainActor
    @Test
    func testBinding() {
        let atom = TestStateAtom(defaultValue: 0)
        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let subscriberState = SubscriberState()
        let context = AtomViewContext(
            store: .root(store: store, scopeKey: rootScopeToken.key),
            subscriber: Subscriber(subscriberState),
            subscription: Subscription()
        )

        let binding = context.binding(atom)

        #expect(context.read(atom) == 0)

        binding.wrappedValue = 100

        #expect(binding.wrappedValue == 100)
        #expect(context.read(atom) == 100)
    }

    @MainActor
    @Test
    func testSnapshot() {
        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let subscriberState = SubscriberState()
        let context = AtomViewContext(
            store: .root(store: store, scopeKey: rootScopeToken.key),
            subscriber: Subscriber(subscriberState),
            subscription: Subscription()
        )
        let atom0 = TestAtom(value: 0)
        let atom1 = TestAtom(value: 1)
        let atom2 = TestAtom(value: 2)
        let key0 = AtomKey(atom0)
        let key1 = AtomKey(atom1)
        let key2 = AtomKey(atom2)

        let dependencies: [AtomKey: Set<AtomKey>] = [key0: [key1, key2]]
        let children: [AtomKey: Set<AtomKey>] = [key1: [key0], key2: [key0]]
        let caches = [
            key0: AtomCache(atom: atom0, value: 0),
            key1: AtomCache(atom: atom1, value: 1),
            key2: AtomCache(atom: atom2, value: 2),
        ]

        store.dependencies = dependencies
        store.children = children
        store.caches = caches

        let snapshot = context.snapshot()

        #expect(snapshot.dependencies == dependencies)
        #expect(snapshot.children == children)
        #expect(snapshot.caches.mapValues { $0 as? AtomCache<TestAtom<Int>> } == caches)
    }

    @MainActor
    @Test
    func testUnsubscription() {
        let atom = TestValueAtom(value: 100)
        let key = AtomKey(atom)
        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        var subscriberState: SubscriberState? = SubscriberState()
        let context = AtomViewContext(
            store: .root(store: store, scopeKey: rootScopeToken.key),
            subscriber: Subscriber(subscriberState!),
            subscription: Subscription()
        )

        context.watch(atom)
        #expect(store.caches[key] != nil)

        subscriberState = nil
        #expect(store.caches[key] == nil)
    }
}
