import Combine
import Testing

@testable import Atoms

struct StoreContextTests {
    @MainActor
    @Test
    func testRead() {
        let store = AtomStore()
        let atom = TestAtom(value: 0)
        let key = AtomKey(atom)
        var snapshots = [Snapshot]()
        let observer = Observer { snapshots.append($0) }
        let rootScopeToken = ScopeKey.Token()
        let context = StoreContext.root(
            store: store,
            scopeKey: rootScopeToken.key,
            observers: [observer],
            overrideContainer: OverrideContainer()
        )

        #expect(context.read(atom) == 0)
        #expect(store.caches[key] == nil)
        #expect(snapshots.isEmpty)

        snapshots.removeAll()
        store.children[key] = [AtomKey(TestAtom(value: 1))]
        #expect(context.read(atom) == 0)
        #expect(snapshots.isEmpty)

        snapshots.removeAll()
        store.caches[key] = AtomCache(atom: atom, value: 1)
        #expect(context.read(atom) == 1)
        #expect(snapshots.isEmpty)
    }

    @MainActor
    @Test
    func testSet() {
        let store = AtomStore()
        let subscriberToken = SubscriberKey.Token()
        let atom = TestStateAtom(defaultValue: 0)
        let key = AtomKey(atom)
        var updateCount = 0
        var snapshots = [Snapshot]()
        let observer = Observer { snapshots.append($0) }
        let rootScopeToken = ScopeKey.Token()
        let context = StoreContext.root(
            store: store,
            scopeKey: rootScopeToken.key,
            observers: [observer],
            overrideContainer: OverrideContainer()
        )

        context.set(1, for: atom)
        #expect(updateCount == 0)
        #expect(store.states[key] == nil)
        #expect(store.caches[key] == nil)
        #expect(snapshots.isEmpty)

        snapshots.removeAll()
        store.caches[key] = AtomCache(atom: atom, value: 0)
        store.states[key] = AtomState(effect: TestEffect())
        store.subscriptions[key, default: [:]][subscriberToken.key] = Subscription(
            location: SourceLocation(),
            update: { updateCount += 1 }
        )
        context.set(2, for: atom)
        #expect(snapshots.map { $0.caches.mapValues { $0.value as? Int } } == [[key: 2]])
        #expect(updateCount == 1)
        #expect(store.states[key]?.transactionState == nil)
        #expect((store.caches[key] as? AtomCache<TestStateAtom<Int>>)?.value == 2)

        snapshots.removeAll()
        context.set(3, for: atom)
        #expect(updateCount == 2)
        #expect(store.states[key] != nil)
        #expect(store.states[key]?.transactionState == nil)
        #expect((store.caches[key] as? AtomCache<TestStateAtom<Int>>)?.value == 3)
        #expect(snapshots.map { $0.caches.mapValues { $0.value as? Int } } == [[key: 3]])
    }

    @MainActor
    @Test
    func testModify() {
        let store = AtomStore()
        let subscriberToken = SubscriberKey.Token()
        var updateCount = 0
        let atom = TestStateAtom(defaultValue: 0)
        let key = AtomKey(atom)
        var snapshots = [Snapshot]()
        let observer = Observer { snapshots.append($0) }
        let rootScopeToken = ScopeKey.Token()
        let context = StoreContext.root(
            store: store,
            scopeKey: rootScopeToken.key,
            observers: [observer],
            overrideContainer: OverrideContainer()
        )

        context.modify(atom) { $0 = 1 }
        #expect(updateCount == 0)
        #expect(store.states[key] == nil)
        #expect(store.caches[key] == nil)
        #expect(snapshots.isEmpty)

        snapshots.removeAll()
        store.caches[key] = AtomCache(atom: atom, value: 0)
        store.states[key] = AtomState(effect: TestEffect())
        store.subscriptions[key, default: [:]][subscriberToken.key] = Subscription(
            location: SourceLocation(),
            update: { updateCount += 1 }
        )
        context.modify(atom) { $0 = 2 }
        #expect(updateCount == 1)
        #expect(store.states[key]?.transactionState == nil)
        #expect((store.caches[key] as? AtomCache<TestStateAtom<Int>>)?.value == 2)
        #expect(snapshots.map { $0.caches.mapValues { $0.value as? Int } } == [[key: 2]])

        snapshots.removeAll()
        context.modify(atom) { $0 = 3 }
        #expect(updateCount == 2)
        #expect(store.states[key] != nil)
        #expect(store.states[key]?.transactionState == nil)
        #expect((store.caches[key] as? AtomCache<TestStateAtom<Int>>)?.value == 3)
        #expect(snapshots.map { $0.caches.mapValues { $0.value as? Int } } == [[key: 3]])
    }

    @MainActor
    @Test
    func testWatch() {
        let store = AtomStore()
        let atom = TestAtom(value: 0)
        let dependency0 = TestStateAtom(defaultValue: 0)
        let dependency1 = TestAtom(value: 1)
        let key = AtomKey(atom)
        let dependency0Key = AtomKey(dependency0)
        let dependency1Key = AtomKey(dependency1)
        let transactionState = TransactionState(key: key)
        var snapshots = [Snapshot]()
        let observer = Observer { snapshots.append($0) }
        let rootScopeToken = ScopeKey.Token()
        let context = StoreContext.root(
            store: store,
            scopeKey: rootScopeToken.key,
            observers: [observer],
            overrideContainer: OverrideContainer()
        )

        #expect(context.watch(dependency0, in: transactionState) == 0)
        #expect(store.dependencies == [key: [dependency0Key]])
        #expect(store.children == [dependency0Key: [key]])
        #expect((store.caches[dependency0Key] as? AtomCache<TestStateAtom<Int>>)?.value == 0)
        #expect(store.states[dependency0Key] != nil)
        #expect(snapshots.flatMap(\.caches).isEmpty)

        transactionState.terminate()

        #expect(context.watch(dependency1, in: transactionState) == 1)
        #expect(store.dependencies == [key: [dependency0Key]])
        #expect(store.children == [dependency0Key: [key]])
        #expect(store.caches[dependency1Key] == nil)
        #expect(store.states[dependency1Key] == nil)
        #expect(snapshots.isEmpty)
    }

    @MainActor
    @Test
    func testWatchFromView() {
        struct DependencyAtom: StateAtom, Hashable {
            func defaultValue(context: Context) -> Int {
                0
            }
        }

        struct TestAtom: ValueAtom, Hashable {
            func value(context: Context) -> Int {
                context.watch(DependencyAtom())
            }
        }

        let store = AtomStore()
        var subscriberState: SubscriberState? = SubscriberState()
        let subscriber = Subscriber(subscriberState!)
        let atom = TestAtom()
        let dependency = DependencyAtom()
        let key = AtomKey(atom)
        let dependencyKey = AtomKey(dependency)
        var snapshots = [Snapshot]()
        let observer = Observer { snapshots.append($0) }
        let rootScopeToken = ScopeKey.Token()
        let context = StoreContext.root(
            store: store,
            scopeKey: rootScopeToken.key,
            observers: [observer],
            overrideContainer: OverrideContainer()
        )

        var updateCount = 0
        let initialValue = context.watch(
            atom,
            subscriber: subscriber,
            subscription: Subscription {
                updateCount += 1
            }
        )

        #expect(initialValue == 0)
        #expect(store.subscribes[subscriber.key]?.contains(key) ?? false)
        #expect(store.subscriptions[key]?[subscriber.key] != nil)
        #expect((store.caches[key] as? AtomCache<TestAtom>)?.value == 0)
        #expect((store.caches[dependencyKey] as? AtomCache<DependencyAtom>)?.value == 0)
        #expect(snapshots.map { $0.caches.mapValues { $0.value as? Int } } == [[key: 0, dependencyKey: 0]])

        snapshots.removeAll()
        store.subscriptions[key]?[subscriber.key]?.update()
        subscriberState = nil

        #expect(updateCount == 1)
        #expect(store.subscribes[subscriber.key] == nil)
        #expect(store.caches[key] == nil)
        #expect(store.states[key] == nil)
        #expect(store.subscriptions[key] == nil)
        #expect(store.caches[dependencyKey] == nil)
        #expect(store.states[dependencyKey] == nil)
        #expect(store.subscriptions[dependencyKey] == nil)
        #expect(snapshots.map { $0.caches.mapValues { $0.value as? Int } } == [[:]])
    }

    @MainActor
    @Test
    func testRefresh() async {
        let store = AtomStore()
        let subscriberState = SubscriberState()
        let subscriber = Subscriber(subscriberState)
        let atom = TestPublisherAtom { Just(0) }
        let key = AtomKey(atom)
        var snapshots = [Snapshot]()
        let observer = Observer { snapshots.append($0) }
        let rootScopeToken = ScopeKey.Token()
        let context = StoreContext.root(
            store: store,
            scopeKey: rootScopeToken.key,
            observers: [observer],
            overrideContainer: OverrideContainer()
        )

        let phase0 = await context.refresh(atom)
        #expect(phase0.value == 0)
        #expect(store.caches[key] == nil)
        #expect(store.states[key] == nil)
        #expect(snapshots.isEmpty)

        var updateCount = 0
        let phase1 = context.watch(
            atom,
            subscriber: subscriber,
            subscription: Subscription {
                updateCount += 1
            }
        )

        #expect(phase1.isSuspending)

        snapshots.removeAll()

        let phase2 = await context.refresh(atom)
        #expect(phase2.value == 0)
        #expect(store.states[key] != nil)
        #expect((store.caches[key] as? AtomCache<TestPublisherAtom<Just<Int>>>)?.value == .success(0))
        #expect(updateCount == 1)
        #expect(snapshots.map { $0.caches.mapValues { $0.value as? AsyncPhase<Int, Never> } } == [[key: .success(0)]])

        let scopeToken = ScopeKey.Token()
        let overrideAtomKey = AtomKey(atom, scopeKey: scopeToken.key)
        let scopedContext = context.scoped(
            scopeID: ScopeID(DefaultScopeID()),
            scopeKey: scopeToken.key,
            observers: [],
            overrideContainer: OverrideContainer()
                .addingOverride(for: atom) { _ in
                    .success(1)
                }
        )

        let phase3 = scopedContext.watch(atom, subscriber: subscriber, subscription: Subscription())
        #expect(phase3.value == 1)

        let phase4 = await scopedContext.refresh(atom)
        #expect(phase4.value == 1)
        #expect(store.states[overrideAtomKey] != nil)
        #expect((store.caches[overrideAtomKey] as? AtomCache<TestPublisherAtom<Just<Int>>>)?.value == .success(1))
    }

    @MainActor
    @Test
    func testRefreshNotCached() async {
        let store = AtomStore()
        let atom = TestAsyncPhaseAtom<Int, Never> { .success(0) }
        let rootScopeToken = ScopeKey.Token()
        let scopeToken = ScopeKey.Token()
        let scopedContext =
            StoreContext
            .root(store: store, scopeKey: rootScopeToken.key)
            .scoped(
                scopeID: ScopeID(DefaultScopeID()),
                scopeKey: scopeToken.key,
                observers: [],
                overrideContainer: OverrideContainer()
                    .addingOverride(for: atom) { _ in
                        .success(1)
                    }
            )

        let phase = await scopedContext.refresh(atom)
        #expect(phase.value == 1)
    }

    @MainActor
    @Test
    func testReset() {
        let store = AtomStore()
        let subscriberState = SubscriberState()
        let subscriber = Subscriber(subscriberState)
        let atom = TestStateAtom(defaultValue: 0)
        let key = AtomKey(atom)
        var snapshots = [Snapshot]()
        let observer = Observer { snapshots.append($0) }
        let rootScopeToken = ScopeKey.Token()
        let context = StoreContext.root(
            store: store,
            scopeKey: rootScopeToken.key,
            observers: [observer],
            overrideContainer: OverrideContainer()
        )

        context.reset(atom)
        #expect(store.caches[key] == nil)
        #expect(store.states[key] == nil)
        #expect(snapshots.isEmpty)

        var updateCount = 0

        _ = context.watch(
            atom,
            subscriber: subscriber,
            subscription: Subscription {
                updateCount += 1
            }
        )
        snapshots.removeAll()
        context.set(1, for: atom)
        #expect(updateCount == 1)
        #expect(snapshots.map { $0.caches.mapValues { $0.value as? Int } } == [[key: 1]])

        snapshots.removeAll()
        context.reset(atom)
        #expect(updateCount == 2)
        #expect(snapshots.map { $0.caches.mapValues { $0.value as? Int } } == [[key: 0]])
    }

    @MainActor
    @Test
    func testUnwatch() {
        let store = AtomStore()
        let subscriberState = SubscriberState()
        let subscriber = Subscriber(subscriberState)
        let atom = TestStateAtom(defaultValue: 0)
        let rootScopeToken = ScopeKey.Token()
        let context = StoreContext.root(store: store, scopeKey: rootScopeToken.key)

        _ = context.watch(atom, subscriber: subscriber, subscription: Subscription())

        #expect(store.caches.mapValues { $0.value as? Int } == [AtomKey(atom): 0])

        #expect(store.subscribes == [subscriber.key: [AtomKey(atom)]])

        context.unwatch(atom, subscriber: subscriber)

        #expect(store.caches.mapValues { $0.value as? Int } == [:])

        #expect(store.subscribes == [subscriber.key: []])
    }

    @MainActor
    @Test
    func testSnapshotAndRestore() {
        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let subscriberToken = SubscriberKey.Token()
        let context = StoreContext.root(store: store, scopeKey: rootScopeToken.key)
        let atom0 = TestAtom(value: 0)
        let atom1 = TestAtom(value: 1)
        let key0 = AtomKey(atom0)
        let key1 = AtomKey(atom1)
        let dependencies: [AtomKey: Set<AtomKey>] = [key0: [key1]]
        let children: [AtomKey: Set<AtomKey>] = [key1: [key0]]
        let caches = [
            key0: AtomCache(atom: atom0, value: 0),
            key1: AtomCache(atom: atom1, value: 1),
        ]
        let subscription = Subscription()

        store.dependencies = dependencies
        store.children = children
        store.caches = caches
        store.subscriptions[key0, default: [:]][subscriberToken.key] = subscription
        store.subscriptions[key1, default: [:]][subscriberToken.key] = subscription

        let snapshot = context.snapshot()

        #expect(snapshot.dependencies == dependencies)
        #expect(snapshot.children == children)
        #expect(snapshot.caches.mapValues { $0 as? AtomCache<TestAtom<Int>> } == caches)
    }

    @MainActor
    @Test
    func testOverride() {
        let store = AtomStore()
        let atom0 = TestAtom(value: 0)
        let atom1 = TestAtom(value: 1)
        let subscriberState = SubscriberState()
        let subscriber = Subscriber(subscriberState)
        let rootScopeToken = ScopeKey.Token()
        let scope1Token = ScopeKey.Token()
        let scope2Token = ScopeKey.Token()
        let context = StoreContext.root(
            store: store,
            scopeKey: rootScopeToken.key,
            observers: [],
            overrideContainer: OverrideContainer()
                .addingOverride(for: atom0) { _ in
                    10
                }
        )
        let scoped1Context = context.scoped(
            scopeID: ScopeID(DefaultScopeID()),
            scopeKey: scope1Token.key,
            observers: [],
            overrideContainer: OverrideContainer()
                .addingOverride(for: atom1) { _ in
                    20
                }
        )
        let scoped2Context = scoped1Context.scoped(
            scopeID: ScopeID(DefaultScopeID()),
            scopeKey: scope2Token.key,
            observers: [],
            overrideContainer: OverrideContainer()
                .addingOverride(for: TestAtom<Int>.self) { _ in
                    30
                }
        )

        #expect(scoped1Context.watch(atom0, subscriber: subscriber, subscription: Subscription()) == 10)
        #expect(scoped1Context.watch(atom1, subscriber: subscriber, subscription: Subscription()) == 20)
        #expect(scoped2Context.watch(atom0, subscriber: subscriber, subscription: Subscription()) == 30)
        #expect(scoped2Context.watch(atom1, subscriber: subscriber, subscription: Subscription()) == 30)
        #expect(
            store.caches.compactMapValues { $0 as? AtomCache<TestAtom<Int>> } == [
                AtomKey(atom0): AtomCache(atom: atom0, value: 10),
                AtomKey(atom1, scopeKey: scope1Token.key): AtomCache(atom: atom1, value: 20),
                AtomKey(atom0, scopeKey: scope2Token.key): AtomCache(atom: atom0, value: 30),
                AtomKey(atom1, scopeKey: scope2Token.key): AtomCache(atom: atom1, value: 30),
            ]
        )
    }

    @MainActor
    @Test
    func testScopedOverride() async {
        struct TestDependency1Atom: StateAtom, Hashable {
            func defaultValue(context: Context) -> Int {
                1
            }
        }

        struct TestDependency2Atom: StateAtom, Hashable {
            func defaultValue(context: Context) -> Int {
                2
            }
        }

        struct TestTransactionAtom: ValueAtom, Hashable {
            func value(context: Context) -> Int {
                3
            }
        }

        struct TestPublisherAtom: PublisherAtom, Hashable {
            func publisher(context: Context) -> Just<Int> {
                let value1 = context.watch(TestDependency1Atom())
                let value2 = context.watch(TestDependency2Atom())
                return Just(value1 + value2)
            }
        }

        struct TestAtom: ValueAtom, Hashable {
            func value(context: Context) -> Int {
                let value1 = context.watch(TestDependency1Atom())
                let value2 = context.watch(TestDependency2Atom())
                return value1 + value2
            }
        }

        let atom = TestAtom()
        let publisherAtom = TestPublisherAtom()
        let dependency1Atom = TestDependency1Atom()
        let dependency2Atom = TestDependency2Atom()
        let transactionAtom = TestTransactionAtom()
        let subscriberState = SubscriberState()
        let subscriber = Subscriber(subscriberState)
        let transactionState = TransactionState(key: AtomKey(transactionAtom))
        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let scope1Token = ScopeKey.Token()
        let scope2Token = ScopeKey.Token()
        let context = StoreContext.root(store: store, scopeKey: rootScopeToken.key)
        let scoped1Context = context.scoped(
            scopeID: ScopeID(DefaultScopeID()),
            scopeKey: scope1Token.key,
            observers: [],
            overrideContainer: OverrideContainer()
                .addingOverride(for: dependency1Atom) { _ in
                    10
                }
        )
        let scoped2Context = scoped1Context.scoped(
            scopeID: ScopeID(DefaultScopeID()),
            scopeKey: scope2Token.key,
            observers: [],
            overrideContainer: OverrideContainer()
                .addingOverride(for: dependency2Atom) { _ in
                    20
                }
        )

        // Should return default values in the scope that atoms are not overridden.
        #expect(context.watch(dependency1Atom, subscriber: subscriber, subscription: Subscription()) == 1)
        #expect(context.watch(dependency2Atom, subscriber: subscriber, subscription: Subscription()) == 2)
        #expect(scoped1Context.watch(dependency1Atom, subscriber: subscriber, subscription: Subscription()) == 10)
        #expect(scoped2Context.watch(dependency2Atom, subscriber: subscriber, subscription: Subscription()) == 20)

        // Shouldn't set the value in the scope that atoms are not overridden.
        scoped1Context.set(100, for: dependency1Atom)
        #expect(context.read(dependency1Atom) == 1)

        // Shouldn't modify the value in the scope that atoms are not overridden.
        scoped1Context.modify(dependency1Atom) { $0 = 1000 }
        #expect(context.read(dependency1Atom) == 1)

        // Shouldn't reset the value in the scope that atoms are not overridden.
        context.reset(dependency1Atom)
        #expect(scoped1Context.read(dependency1Atom) == 1000)

        context.unwatch(dependency1Atom, subscriber: subscriber)
        context.unwatch(dependency2Atom, subscriber: subscriber)
        scoped1Context.unwatch(dependency1Atom, subscriber: subscriber)
        scoped2Context.unwatch(dependency2Atom, subscriber: subscriber)

        // Override for `scoped1Context` shouldn't inherited to `scoped2Context`.
        #expect(scoped2Context.watch(atom, subscriber: subscriber, subscription: Subscription()) == 21)
        #expect(scoped2Context.watch(publisherAtom, subscriber: subscriber, subscription: Subscription()) == .suspending)

        // Should set the value and then update the dependent atoms transitively.
        scoped2Context.set(20, for: dependency1Atom)

        // Should set the value because the atom depends on the shared `dependency1Atom`.
        context.set(30, for: dependency1Atom)

        // Should return overridden values.
        #expect(scoped2Context.read(atom) == 50)
        #expect(scoped2Context.read(dependency1Atom) == 30)
        #expect(scoped2Context.read(dependency2Atom) == 20)

        // Should return the value cached when accessed via the `scoped2Context` as it's cached as a shared value.
        #expect(context.read(atom) == 50)

        // Should modify the value because the `atom` depends on the shared `dependency1Atom`
        // and the `dependency1Atom` is scoped for `scoped2Context`.
        scoped2Context.modify(dependency1Atom) { $0 = 40 }
        #expect(scoped2Context.read(dependency1Atom) == 40)

        // Shouldn't modify the value because `dependency2Atom` is scoped for `scoped2Context`.
        context.modify(dependency2Atom) { $0 = 50 }
        #expect(scoped2Context.read(dependency2Atom) == 20)
        #expect(scoped2Context.read(atom) == 60)

        do {
            let phase = await scoped2Context.refresh(publisherAtom)
            #expect(phase == .success(60))
        }

        // Should reset the value.
        scoped2Context.reset(dependency1Atom)
        #expect(scoped2Context.read(dependency1Atom) == 1)
        #expect(scoped2Context.read(atom) == 21)

        do {
            let phase = await scoped2Context.refresh(publisherAtom)
            #expect(phase == .success(21))
        }

        // Should add 'atom' as a dependency of `transactionAtom`.
        #expect(scoped2Context.watch(atom, in: transactionState) == 21)

        #expect(
            store.dependencies == [
                AtomKey(transactionAtom): [
                    AtomKey(atom)
                ],
                AtomKey(atom): [
                    AtomKey(dependency1Atom),
                    AtomKey(dependency2Atom, scopeKey: scope2Token.key),
                ],
                AtomKey(publisherAtom): [
                    AtomKey(dependency1Atom),
                    AtomKey(dependency2Atom, scopeKey: scope2Token.key),
                ],
            ]
        )
        #expect(
            store.children == [
                AtomKey(atom): [
                    AtomKey(transactionAtom)
                ],
                AtomKey(dependency1Atom): [
                    AtomKey(atom),
                    AtomKey(publisherAtom),
                ],
                AtomKey(dependency2Atom, scopeKey: scope2Token.key): [
                    AtomKey(atom),
                    AtomKey(publisherAtom),
                ],
            ]
        )
        #expect(
            store.caches.mapValues { $0 as? AtomCache<TestAtom> } == [
                AtomKey(publisherAtom): nil,
                AtomKey(atom): AtomCache(atom: atom, value: 21),
                AtomKey(dependency1Atom): nil,
                AtomKey(dependency2Atom, scopeKey: scope2Token.key): nil,
            ]
        )
        #expect(
            store.caches.mapValues { $0 as? AtomCache<TestPublisherAtom> } == [
                AtomKey(publisherAtom): AtomCache(atom: publisherAtom, value: .success(21)),
                AtomKey(atom): nil,
                AtomKey(dependency1Atom): nil,
                AtomKey(dependency2Atom, scopeKey: scope2Token.key): nil,
            ]
        )
        #expect(
            store.caches.mapValues { $0 as? AtomCache<TestDependency1Atom> } == [
                AtomKey(publisherAtom): nil,
                AtomKey(atom): nil,
                AtomKey(dependency1Atom): AtomCache(atom: dependency1Atom, value: 1),
                AtomKey(dependency2Atom, scopeKey: scope2Token.key): nil,
            ]
        )
        #expect(
            store.caches.mapValues { $0 as? AtomCache<TestDependency2Atom> } == [
                AtomKey(publisherAtom): nil,
                AtomKey(atom): nil,
                AtomKey(dependency1Atom): nil,
                AtomKey(dependency2Atom, scopeKey: scope2Token.key): AtomCache(atom: dependency2Atom, value: 20),
            ]
        )

        #expect(
            store.subscribes == [
                subscriber.key: [
                    AtomKey(atom),
                    AtomKey(publisherAtom),
                ]
            ]
        )
    }

    @MainActor
    @Test
    func testOverrideCrossScopeBoundary() async {
        struct TestDependency1Atom: StateAtom, Hashable {
            func defaultValue(context: Context) -> Int {
                1
            }
        }

        struct TestDependency2Atom: StateAtom, Hashable {
            func defaultValue(context: Context) -> Int {
                2
            }
        }

        struct TestDependency3Atom: StateAtom, Scoped, Hashable {
            func defaultValue(context: Context) -> Int {
                3
            }
        }

        struct TestDependency4Atom: AsyncPhaseAtom, Hashable {
            func value(context: Context) async -> Int {
                4
            }
        }

        struct TestAtom: ValueAtom, Hashable {
            func value(context: Context) -> Int {
                let value1 = context.watch(TestDependency1Atom())
                let value2 = context.watch(TestDependency2Atom())
                let value3 = context.watch(TestDependency3Atom())
                let value4 = context.watch(TestDependency4Atom()).value ?? 0
                return value1 + value2 + value3 + value4
            }
        }

        let subscriberState = SubscriberState()
        let subscriber = Subscriber(subscriberState)
        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let scopeToken = ScopeKey.Token()
        let context = StoreContext.root(store: store, scopeKey: rootScopeToken.key)
        let scopedContext = context.scoped(
            scopeID: ScopeID(DefaultScopeID()),
            scopeKey: scopeToken.key,
            observers: [],
            overrideContainer: OverrideContainer()
                .addingOverride(for: TestDependency2Atom()) { _ in
                    20
                }
        )

        // Pre initialize some of dependencies.
        _ = context.watch(TestDependency4Atom(), subscriber: subscriber, subscription: Subscription())

        // Initialize the atom state in the scoped context.
        #expect(scopedContext.watch(TestAtom(), subscriber: subscriber, subscription: Subscription()) == 24)

        await Task.yield {
            context.read(TestDependency4Atom()).isSuccess
        }

        // The updated value should reflect the scoped overrides.
        #expect(scopedContext.watch(TestAtom(), subscriber: subscriber, subscription: Subscription()) == 28)

        // Update one of the dependency atoms from non-scoped context.
        context.set(10, for: TestDependency1Atom())

        await Task.yield {
            scopedContext.watch(TestDependency4Atom(), subscriber: subscriber, subscription: Subscription()).isSuccess
        }

        // The updated value should reflect the scoped overrides.
        #expect(scopedContext.watch(TestAtom(), subscriber: subscriber, subscription: Subscription()) == 37)
    }

    @MainActor
    @Test
    func testRelease() {
        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let context = StoreContext.root(store: store, scopeKey: rootScopeToken.key)

        let atom = TestAtom(value: 0)
        let key = AtomKey(atom)
        let subscriberState = SubscriberState()
        let subscriber = Subscriber(subscriberState)

        _ = context.watch(atom, subscriber: subscriber, subscription: Subscription())
        #expect(store.caches[key] != nil)

        context.unwatch(atom, subscriber: subscriber)
        #expect(store.caches[key] == nil)
    }

    @MainActor
    @Test
    func testObservers() {
        let subscriberState = SubscriberState()
        let subscriber = Subscriber(subscriberState)
        let atom0 = TestAtom(value: 0)
        let atom1 = TestAtom(value: 1)
        let atom2 = TestAtom(value: 2)
        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let scope1Token = ScopeKey.Token()
        let scope2Token = ScopeKey.Token()
        var snapshots = [Snapshot]()
        var scopedSnapshots = [Snapshot]()
        let context = StoreContext.root(
            store: store,
            scopeKey: rootScopeToken.key,
            observers: [Observer { snapshots.append($0) }],
            overrideContainer: OverrideContainer()
        )
        let scoped1Context = context.scoped(
            scopeID: ScopeID(DefaultScopeID()),
            scopeKey: scope1Token.key
        )
        let scoped2Context = scoped1Context.scoped(
            scopeID: ScopeID(DefaultScopeID()),
            scopeKey: scope2Token.key,
            observers: [Observer { scopedSnapshots.append($0) }],
            overrideContainer: OverrideContainer()
                .addingOverride(for: atom1) { _ in
                    100
                }
        )

        // New value

        _ = scoped2Context.watch(atom0, subscriber: subscriber, subscription: Subscription())
        _ = scoped2Context.watch(atom1, subscriber: subscriber, subscription: Subscription())
        _ = context.watch(atom0, subscriber: subscriber, subscription: Subscription())
        _ = context.watch(atom1, subscriber: subscriber, subscription: Subscription())
        _ = context.watch(atom2, subscriber: subscriber, subscription: Subscription())

        #expect(
            snapshots.map { $0.caches.mapValues { $0 as? AtomCache<TestAtom<Int>> } } == [
                [
                    AtomKey(atom0): AtomCache(atom: atom0, value: 0)
                ],
                [
                    AtomKey(atom0): AtomCache(atom: atom0, value: 0),
                    AtomKey(atom1, scopeKey: scope2Token.key): AtomCache(atom: atom1, value: 100),
                ],
                [
                    AtomKey(atom0): AtomCache(atom: atom0, value: 0),
                    AtomKey(atom1, scopeKey: scope2Token.key): AtomCache(atom: atom1, value: 100),
                    AtomKey(atom1): AtomCache(atom: atom1, value: 1),
                ],
                [
                    AtomKey(atom0): AtomCache(atom: atom0, value: 0),
                    AtomKey(atom1, scopeKey: scope2Token.key): AtomCache(atom: atom1, value: 100),
                    AtomKey(atom1): AtomCache(atom: atom1, value: 1),
                    AtomKey(atom2): AtomCache(atom: atom2, value: 2),
                ],
            ]
        )
        #expect(
            scopedSnapshots.map { $0.caches.mapValues { $0 as? AtomCache<TestAtom<Int>> } } == [
                [
                    AtomKey(atom0): AtomCache(atom: atom0, value: 0)
                ],
                [
                    AtomKey(atom0): AtomCache(atom: atom0, value: 0),
                    AtomKey(atom1, scopeKey: scope2Token.key): AtomCache(atom: atom1, value: 100),
                ],
            ]
        )

        // Update

        snapshots.removeAll()
        scopedSnapshots.removeAll()
        scoped2Context.reset(atom0)
        scoped2Context.reset(atom1)
        context.reset(atom2)

        #expect(
            snapshots.map { $0.caches.mapValues { $0 as? AtomCache<TestAtom<Int>> } } == [
                [
                    AtomKey(atom0): AtomCache(atom: atom0, value: 0),
                    AtomKey(atom1, scopeKey: scope2Token.key): AtomCache(atom: atom1, value: 100),
                    AtomKey(atom1): AtomCache(atom: atom1, value: 1),
                    AtomKey(atom2): AtomCache(atom: atom2, value: 2),
                ],
                [
                    AtomKey(atom0): AtomCache(atom: atom0, value: 0),
                    AtomKey(atom1, scopeKey: scope2Token.key): AtomCache(atom: atom1, value: 100),
                    AtomKey(atom1): AtomCache(atom: atom1, value: 1),
                    AtomKey(atom2): AtomCache(atom: atom2, value: 2),
                ],
                [
                    AtomKey(atom0): AtomCache(atom: atom0, value: 0),
                    AtomKey(atom1, scopeKey: scope2Token.key): AtomCache(atom: atom1, value: 100),
                    AtomKey(atom1): AtomCache(atom: atom1, value: 1),
                    AtomKey(atom2): AtomCache(atom: atom2, value: 2),
                ],
            ]
        )
        #expect(
            scopedSnapshots.map { $0.caches.mapValues { $0 as? AtomCache<TestAtom<Int>> } } == [
                [
                    AtomKey(atom0): AtomCache(atom: atom0, value: 0),
                    AtomKey(atom1, scopeKey: scope2Token.key): AtomCache(atom: atom1, value: 100),
                    AtomKey(atom1): AtomCache(atom: atom1, value: 1),
                    AtomKey(atom2): AtomCache(atom: atom2, value: 2),
                ],
                [
                    AtomKey(atom0): AtomCache(atom: atom0, value: 0),
                    AtomKey(atom1, scopeKey: scope2Token.key): AtomCache(atom: atom1, value: 100),
                    AtomKey(atom1): AtomCache(atom: atom1, value: 1),
                    AtomKey(atom2): AtomCache(atom: atom2, value: 2),
                ],
            ]
        )

        // Release

        snapshots.removeAll()
        scopedSnapshots.removeAll()
        context.unwatch(atom0, subscriber: subscriber)
        scoped2Context.unwatch(atom1, subscriber: subscriber)
        context.unwatch(atom2, subscriber: subscriber)

        #expect(
            snapshots.map { $0.caches.mapValues { $0 as? AtomCache<TestAtom<Int>> } } == [
                [
                    AtomKey(atom1, scopeKey: scope2Token.key): AtomCache(atom: atom1, value: 100),
                    AtomKey(atom1): AtomCache(atom: atom1, value: 1),
                    AtomKey(atom2): AtomCache(atom: atom2, value: 2),
                ],
                [

                    AtomKey(atom1): AtomCache(atom: atom1, value: 1),
                    AtomKey(atom2): AtomCache(atom: atom2, value: 2),
                ],
                [

                    AtomKey(atom1): AtomCache(atom: atom1, value: 1)
                ],
            ]
        )
        #expect(
            scopedSnapshots.map { $0.caches.mapValues { $0 as? AtomCache<TestAtom<Int>> } } == [
                [

                    AtomKey(atom1): AtomCache(atom: atom1, value: 1),
                    AtomKey(atom2): AtomCache(atom: atom2, value: 2),
                ]
            ]
        )
    }

    @MainActor
    @Test
    func testObserversCrossScopeBoundary() async {
        struct TestDependency1Atom: StateAtom, Hashable {
            func defaultValue(context: Context) -> Int {
                1
            }
        }

        struct TestDependency2Atom: StateAtom, Hashable {
            func defaultValue(context: Context) -> Int {
                2
            }
        }

        struct TestDependency3Atom: StateAtom, Scoped, Hashable {
            func defaultValue(context: Context) -> Int {
                3
            }
        }

        struct TestAtom: ValueAtom, Hashable {
            func value(context: Context) -> Int {
                let value1 = context.watch(TestDependency1Atom())
                let value2 = context.watch(TestDependency2Atom())
                let value3 = context.watch(TestDependency3Atom())
                return value1 + value2 + value3
            }
        }

        let atom = TestAtom()
        let subscriberState = SubscriberState()
        let subscriber = Subscriber(subscriberState)
        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let scopeToken = ScopeKey.Token()
        let context = StoreContext.root(store: store, scopeKey: rootScopeToken.key)
        var snapshots = [Snapshot]()
        let scopedContext = context.scoped(
            scopeID: ScopeID(DefaultScopeID()),
            scopeKey: scopeToken.key,
            observers: [
                Observer { snapshot in
                    snapshots.append(snapshot)
                }
            ],
            overrideContainer: OverrideContainer()
        )

        let expectedDependencies: [AtomKey: Set<AtomKey>] = [
            AtomKey(TestAtom()): [
                AtomKey(TestDependency1Atom()),
                AtomKey(TestDependency2Atom()),
                AtomKey(TestDependency3Atom(), scopeKey: scopeToken.key),
            ]
        ]
        let expectedChildren: [AtomKey: Set<AtomKey>] = [
            AtomKey(TestDependency1Atom()): [AtomKey(TestAtom())],
            AtomKey(TestDependency2Atom()): [AtomKey(TestAtom())],
            AtomKey(TestDependency3Atom(), scopeKey: scopeToken.key): [AtomKey(TestAtom())],
        ]

        // Initialize the atom state in the scoped context.
        _ = scopedContext.watch(atom, subscriber: subscriber, subscription: Subscription())

        // The scoped observer should receive the update event.
        #expect(snapshots.map(\.dependencies) == [expectedDependencies])
        #expect(snapshots.map(\.children) == [expectedChildren])

        context.set(20, for: TestDependency2Atom())

        // The scoped observer should receive the update event.
        #expect(snapshots.map(\.dependencies) == [expectedDependencies, expectedDependencies])
        #expect(snapshots.map(\.children) == [expectedChildren, expectedChildren])
    }

    @MainActor
    @Test
    func testRestore() {
        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let context = StoreContext.root(store: store, scopeKey: rootScopeToken.key)
        let atom0 = TestAtom(value: 0)
        let atom1 = TestAtom(value: 1)
        let atom2 = TestAtom(value: 2)
        let location = SourceLocation()
        let subscriberToken = SubscriberKey.Token()

        store.dependencies = [AtomKey(atom0): [AtomKey(atom1)]]
        store.children = [AtomKey(atom1): [AtomKey(atom0)]]
        store.caches = [
            AtomKey(atom0): AtomCache(atom: atom0, value: 0),
            AtomKey(atom1): AtomCache(atom: atom1, value: 1),
        ]

        let snapshot = context.snapshot()

        store.dependencies = [:]
        store.children = [:]
        store.caches = [
            AtomKey(atom2): AtomCache(atom: atom2, value: 2)
        ]

        var updated = Set<AtomKey>()
        let subscription0 = Subscription(location: location) { updated.insert(AtomKey(atom0)) }
        let subscription1 = Subscription(location: location) { updated.insert(AtomKey(atom1)) }
        let subscription2 = Subscription(location: location) { updated.insert(AtomKey(atom2)) }

        store.subscriptions = [
            AtomKey(atom0): [subscriberToken.key: subscription0],
            AtomKey(atom1): [subscriberToken.key: subscription1],
            AtomKey(atom2): [subscriberToken.key: subscription2],
        ]

        context.restore(snapshot)

        // Notifies updated only for the subscriptions of the atoms that are restored.
        #expect(updated == [AtomKey(atom0), AtomKey(atom1)])
        #expect(store.dependencies == [AtomKey(atom0): [AtomKey(atom1)]])
        #expect(store.children == [AtomKey(atom1): [AtomKey(atom0)]])

        // Do not delete caches added after the snapshot was taken.
        #expect(
            store.caches.mapValues { $0 as? AtomCache<TestAtom<Int>> } == [
                AtomKey(atom0): AtomCache(atom: atom0, value: 0),
                AtomKey(atom1): AtomCache(atom: atom1, value: 1),
                AtomKey(atom2): AtomCache(atom: atom2, value: 2),
            ]
        )

        // Restore with no subscriptions.
        store.subscriptions.removeAll()
        context.restore(snapshot)

        #expect(store.dependencies == [:])
        #expect(store.children == [:])

        // Caches added after the snapshot was taken are not forcibly released by restore,
        // but this is not a problem since the cache should originally be released
        // when the subscription is released.
        #expect(
            store.caches.mapValues { $0 as? AtomCache<TestAtom<Int>> } == [
                AtomKey(atom2): AtomCache(atom: atom2, value: 2)
            ]
        )
    }

    @MainActor
    @Test
    func testEffect() {
        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let context = StoreContext.root(store: store, scopeKey: rootScopeToken.key)
        let subscriberState = SubscriberState()
        let subscriber = Subscriber(subscriberState)
        let effect = TestEffect()
        let atom = TestStateAtom(defaultValue: 0, effect: effect)
        let upstreamAtom = TestStateAtom(defaultValue: "")
        let key = AtomKey(atom)

        _ = context.watch(atom, subscriber: subscriber, subscription: Subscription())
        _ = context.watch(upstreamAtom, in: TransactionState(key: key))

        #expect((store.states[key]?.effect as? TestEffect) === effect)
        #expect(effect.initializingCount == 1)
        #expect(effect.initializedCount == 1)
        #expect(effect.updatedCount == 0)
        #expect(effect.releasedCount == 0)

        context.set(1, for: atom)

        #expect((store.states[key]?.effect as? TestEffect) === effect)
        #expect(effect.initializingCount == 1)
        #expect(effect.initializedCount == 1)
        #expect(effect.updatedCount == 1)
        #expect(effect.releasedCount == 0)

        context.set(2, for: atom)
        context.set(3, for: atom)
        context.set(4, for: atom)

        #expect((store.states[key]?.effect as? TestEffect) === effect)
        #expect(effect.initializingCount == 1)
        #expect(effect.initializedCount == 1)
        #expect(effect.updatedCount == 4)
        #expect(effect.releasedCount == 0)

        context.set("Updated", for: upstreamAtom)

        #expect((store.states[key]?.effect as? TestEffect) === effect)
        #expect(effect.initializingCount == 1)
        #expect(effect.initializedCount == 1)
        #expect(effect.updatedCount == 5)
        #expect(effect.releasedCount == 0)

        context.unwatch(atom, subscriber: subscriber)

        #expect(store.states[key] == nil)
        #expect(effect.initializingCount == 1)
        #expect(effect.initializedCount == 1)
        #expect(effect.updatedCount == 5)
        #expect(effect.releasedCount == 1)

        context.set(5, for: atom)

        #expect(store.states[key] == nil)
        #expect(effect.initializingCount == 1)
        #expect(effect.initializedCount == 1)
        #expect(effect.updatedCount == 5)
        #expect(effect.releasedCount == 1)
    }

    @MainActor
    @Test
    func testEffectCrossScopeBoundary() async {
        struct TestDependencyAtom: ValueAtom, Hashable {
            func value(context: Context) -> Int {
                1
            }
        }

        struct TestAtom: StateAtom {
            let testEffect: TestEffect

            var key: UniqueKey {
                UniqueKey()
            }

            func defaultValue(context: Context) -> Int {
                context.read(TestDependencyAtom())
            }

            func effect(context: CurrentContext) -> some AtomEffect {
                testEffect.initContext = context
                return testEffect
            }
        }

        struct TestAsyncAtom: AsyncPhaseAtom {
            let testEffect: TestEffect

            var key: UniqueKey {
                UniqueKey()
            }

            func value(context: Context) async -> Int {
                context.read(TestDependencyAtom())
            }

            func effect(context: CurrentContext) -> some AtomEffect {
                testEffect.initContext = context
                return testEffect
            }
        }

        final class TestEffect: AtomEffect {
            var initContext: AtomCurrentContext?
            var value1: Int?
            var value2: Int?

            func updateValues(context: Context) {
                value1 = context.read(TestDependencyAtom())
                value2 = initContext?.read(TestDependencyAtom())
            }

            func initialized(context: Context) {
                updateValues(context: context)
            }

            func updated(context: Context) {
                updateValues(context: context)
            }

            func released(context: Context) {
                updateValues(context: context)
            }
        }

        let subscriberState = SubscriberState()
        let subscriber = Subscriber(subscriberState)
        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let scopeToken = ScopeKey.Token()
        let context = StoreContext.root(store: store, scopeKey: rootScopeToken.key)
        let scopedContext = context.scoped(
            scopeID: ScopeID(DefaultScopeID()),
            scopeKey: scopeToken.key,
            observers: [],
            overrideContainer: OverrideContainer()
                .addingOverride(for: TestDependencyAtom()) { _ in
                    2
                }
        )
        let testEffect = TestEffect()
        let testAtom = TestAtom(testEffect: testEffect)
        let testAsyncAtom = TestAsyncAtom(testEffect: testEffect)

        func assert(sourceLocation: Testing.SourceLocation = #_sourceLocation) {
            #expect(testEffect.value1 == 1, sourceLocation: sourceLocation)
            #expect(testEffect.value2 == 1, sourceLocation: sourceLocation)
        }

        let value0 = context.read(testAtom)
        assert()
        #expect(value0 == 1)

        let value1 = context.watch(testAtom, subscriber: subscriber, subscription: Subscription())
        assert()
        #expect(value1 == 1)

        let value2 = context.watch(testAsyncAtom, subscriber: subscriber, subscription: Subscription())
        assert()
        #expect(value2 == .suspending)

        scopedContext.set(1, for: testAtom)
        assert()

        scopedContext.modify(testAtom) { $0 = 1 }
        assert()

        let value3 = await scopedContext.refresh(testAsyncAtom)
        assert()
        #expect(value3 == .success(1))

        scopedContext.reset(testAsyncAtom)
        assert()

        scopedContext.unwatch(testAtom, subscriber: subscriber)
        assert()
    }

    @MainActor
    @Test
    func testUpdateInTopologicalOrder() {
        struct TestAtom1: StateAtom, Hashable {
            func defaultValue(context: Context) -> Int {
                0
            }
        }

        struct TestAtom2: ValueAtom, Hashable {
            func value(context: Context) -> Int {
                context.watch(TestAtom1()) * 2
            }
        }

        struct TestAtom3: ValueAtom, Hashable {
            func value(context: Context) -> Int {
                context.watch(TestAtom1()) * 3
            }
        }

        struct TestAtom4: ValueAtom, Hashable {
            func value(context: Context) -> Int {
                let value1 = context.watch(TestAtom1())
                let value2 = context.watch(TestAtom2())
                let value3 = context.watch(TestAtom3())
                return value1 + value2 + value3
            }
        }

        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let context = StoreContext.root(store: store, scopeKey: rootScopeToken.key)
        let subscriberState = SubscriberState()
        let subscriber = Subscriber(subscriberState)

        var updateCount = 0
        let value0 = context.watch(
            TestAtom4(),
            subscriber: subscriber,
            subscription: Subscription {
                updateCount += 1
            }
        )

        #expect(value0 == 0)
        #expect(updateCount == 0)

        context.set(1, for: TestAtom1())
        let value1 = context.read(TestAtom4())

        #expect(value1 == 6)
        #expect(updateCount == 1)
    }

    @MainActor
    @Test
    func testUpdatePropagation() {
        struct TestAtom1: StateAtom, Hashable {
            func defaultValue(context: Context) -> Int {
                0
            }
        }

        struct TestAtom2: ValueAtom, Hashable {
            func value(context: Context) -> Int {
                context.watch(TestAtom1().changes)
            }
        }

        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let context = StoreContext.root(store: store, scopeKey: rootScopeToken.key)
        let subscriberState = SubscriberState()
        let subscriber = Subscriber(subscriberState)

        var updateCount = 0
        let value0 = context.watch(
            TestAtom2(),
            subscriber: subscriber,
            subscription: Subscription {
                updateCount += 1
            }
        )

        #expect(value0 == 0)
        #expect(updateCount == 0)

        context.set(1, for: TestAtom1())
        let value1 = context.read(TestAtom2())

        #expect(value1 == 1)
        #expect(updateCount == 1)

        context.set(1, for: TestAtom1())
        let value2 = context.read(TestAtom2())

        #expect(value2 == 1)
        #expect(updateCount == 1)
    }

    @MainActor
    @Test
    func testUpdateSkipping() {
        struct TestAtom1: StateAtom, Hashable {
            func defaultValue(context: Context) -> Int {
                0
            }
        }

        struct TestAtom2: ValueAtom, Hashable {
            func value(context: Context) -> Int {
                context.watch(TestAtom1())
            }
        }

        struct TestAtom3: ValueAtom, Hashable {
            func value(context: Context) -> Int {
                context.watch(TestAtom1())
            }
        }

        struct TestAtom4: ValueAtom, Hashable {
            func value(context: Context) -> Int {
                context.watch(TestAtom1())
            }
        }

        // Scenario:
        // If multiple atoms with the same update source are subscribed to and
        // a transitive update from one of them is skipped, from other will take effect.
        // Flaky.
        for _ in 0..<100 {
            let store = AtomStore()
            let rootScopeToken = ScopeKey.Token()
            let context = StoreContext.root(store: store, scopeKey: rootScopeToken.key)
            let subscriberState = SubscriberState()
            let subscriber = Subscriber(subscriberState)

            var updateCount = 0
            let value0 = context.watch(
                TestAtom2().changes,
                subscriber: subscriber,
                subscription: Subscription {
                    updateCount += 1
                }
            )
            let value1 = context.watch(
                TestAtom3().changes,
                subscriber: subscriber,
                subscription: Subscription {
                    updateCount += 1
                }
            )
            let value2 = context.watch(
                TestAtom4(),
                subscriber: subscriber,
                subscription: Subscription {
                    updateCount += 1
                }
            )

            #expect(value0 == 0)
            #expect(value1 == 0)
            #expect(value2 == 0)
            #expect(updateCount == 0)

            context.set(1, for: TestAtom1())
            let value3 = context.read(TestAtom2().changes)
            let value4 = context.read(TestAtom3().changes)
            let value5 = context.read(TestAtom4())

            #expect(value3 == 1)
            #expect(value4 == 1)
            #expect(value5 == 1)
            #expect(updateCount == 1)

            context.set(1, for: TestAtom1())
            let value6 = context.read(TestAtom2().changes)
            let value7 = context.read(TestAtom3().changes)
            let value8 = context.read(TestAtom4())

            #expect(value6 == 1)
            #expect(value7 == 1)
            #expect(value8 == 1)
            #expect(updateCount == 2)
        }
    }

    @MainActor
    @Test
    func testUpdateSkipping2() {
        struct TestAtom1: StateAtom, Hashable {
            func defaultValue(context: Context) -> Int {
                0
            }
        }

        struct TestAtom2: ValueAtom, Hashable {
            func value(context: Context) -> Int {
                context.watch(TestAtom1())
            }
        }

        struct TestAtom3: ValueAtom, Hashable {
            func value(context: Context) -> Int {
                context.watch(TestAtom1())
            }
        }

        struct TestAtom4: ValueAtom, Hashable {
            func value(context: Context) -> Int {
                context.watch(TestAtom3().changes) * 2
            }
        }

        // Scenario:
        // When all subscribing atoms skip transitive updates somewhere in their
        // dependencies, the subscriber will not receive updates.
        // Flaky.
        for _ in 0..<100 {
            let store = AtomStore()
            let rootScopeToken = ScopeKey.Token()
            let context = StoreContext.root(store: store, scopeKey: rootScopeToken.key)
            let subscriberState = SubscriberState()
            let subscriber = Subscriber(subscriberState)

            var updateCount = 0
            let value0 = context.watch(
                TestAtom2().changes,
                subscriber: subscriber,
                subscription: Subscription {
                    updateCount += 1
                }
            )
            let value1 = context.watch(
                TestAtom3().changes,
                subscriber: subscriber,
                subscription: Subscription {
                    updateCount += 1
                }
            )
            let value2 = context.watch(
                TestAtom4(),
                subscriber: subscriber,
                subscription: Subscription {
                    updateCount += 1
                }
            )

            #expect(value0 == 0)
            #expect(value1 == 0)
            #expect(value2 == 0)
            #expect(updateCount == 0)

            context.set(1, for: TestAtom1())
            let value3 = context.read(TestAtom2().changes)
            let value4 = context.read(TestAtom3().changes)
            let value5 = context.read(TestAtom4())

            #expect(value3 == 1)
            #expect(value4 == 1)
            #expect(value5 == 2)
            #expect(updateCount == 1)

            context.set(1, for: TestAtom1())
            let value6 = context.read(TestAtom2().changes)
            let value7 = context.read(TestAtom3().changes)
            let value8 = context.read(TestAtom4())

            #expect(value6 == 1)
            #expect(value7 == 1)
            #expect(value8 == 2)
            #expect(updateCount == 1)
        }
    }

    @MainActor
    @Test
    func testUnsubscribeOnBackgroundThread() async {
        struct TestAtom1: StateAtom, Hashable {
            func defaultValue(context: Context) -> Int {
                0
            }
        }

        struct TestAtom2: ValueAtom, Hashable {
            func value(context: Context) -> Int {
                context.watch(TestAtom1())
            }
        }

        final class SubscriberHost: @unchecked Sendable {
            var subscriberState: SubscriberState?
        }

        // Flaky.
        for _ in 0..<100 {
            let store = AtomStore()
            let rootScopeToken = ScopeKey.Token()
            let context = StoreContext.root(store: store, scopeKey: rootScopeToken.key)
            let host = SubscriberHost()
            host.subscriberState = SubscriberState()

            let subscriber = Subscriber(host.subscriberState!)

            _ = context.watch(
                TestAtom2(),
                subscriber: subscriber,
                subscription: Subscription()
            )

            // Release the subscriber state on the detached background thread.
            let releaseTask = Task.detached {
                host.subscriberState = nil
            }

            // Set a new value to the root atom concurrently.
            // This causes data race in the internal mechanism
            // if main actor isolation is not working correctly.
            let setTask = Task {
                context.set(100, for: TestAtom1())
            }

            _ = await (releaseTask.value, setTask.value)

            // Waits until unsubscription is performed.
            await Task.yield(until: { context.lookup(TestAtom1()) == nil })

            #expect(context.lookup(TestAtom1()) == nil)
            #expect(context.lookup(TestAtom2()) == nil)
            #expect(store.subscriptions.isEmpty)
        }
    }

    @MainActor
    @Test
    func testComplexDependencies() async {
        enum Phase {
            case first
            case second
            case third
        }

        struct PhaseAtom: StateAtom, Hashable {
            func defaultValue(context: Context) -> Phase {
                .first
            }
        }

        struct AAtom: StateAtom, Hashable {
            func defaultValue(context: Context) -> Int {
                0
            }
        }

        struct BAtom: StateAtom, Hashable {
            func defaultValue(context: Context) -> Int {
                0
            }
        }

        struct CAtom: StateAtom, Hashable {
            func defaultValue(context: Context) -> Int {
                0
            }
        }

        struct DAtom: StateAtom, Hashable {
            func defaultValue(context: Context) -> Int {
                0
            }
        }

        struct TestAtom: TaskAtom {
            let pipe: AsyncThrowingStreamPipe<Void>

            var key: UniqueKey {
                UniqueKey()
            }

            func value(context: Context) async -> Int {
                let phase = context.watch(PhaseAtom())
                // - Dependencies (`|` means a suspention point)
                //   - first:  [A, B, C |]
                //   - second: [A, D | B]
                //   - third:  [B, D | C]
                switch phase {
                case .first:
                    let a = context.watch(AAtom())
                    let b = context.watch(BAtom())
                    let c = context.watch(CAtom())

                    pipe.continuation.yield()
                    await pipe.stream.next()

                    return a + b + c

                case .second:
                    let a = context.watch(AAtom())
                    let d = context.watch(DAtom())

                    pipe.continuation.yield()
                    await pipe.stream.next()

                    let b = context.watch(BAtom())
                    return a + d + b

                case .third:
                    let b = context.watch(BAtom())
                    let d = context.watch(DAtom())

                    pipe.continuation.yield()
                    await pipe.stream.next()

                    let c = context.watch(CAtom())
                    return b + c + d
                }
            }
        }

        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let atomStore = StoreContext.root(store: store, scopeKey: rootScopeToken.key)
        var subscriberState: SubscriberState? = SubscriberState()
        let subscriber = Subscriber(subscriberState!)
        let pipe = AsyncThrowingStreamPipe<Void>()
        let atom = TestAtom(pipe: pipe)
        let a = AAtom()
        let b = BAtom()
        let c = CAtom()
        let d = DAtom()
        let phase = PhaseAtom()

        do {
            // first

            Task {
                await pipe.stream.next()
                pipe.continuation.yield()
            }

            let value = await atomStore.watch(atom, subscriber: subscriber, subscription: Subscription()).value

            #expect(value == 0)
            #expect(store.children[AtomKey(d)] == nil)
            #expect(store.dependencies[AtomKey(atom)] == [AtomKey(phase), AtomKey(a), AtomKey(b), AtomKey(c)])

            let state = store.states[AtomKey(atom)]

            // TestAtom's Task cancellation
            #expect(state?.transactionState?.onTermination != nil)
        }

        do {
            // second

            Task {
                await pipe.stream.next()
                atomStore.set(1, for: d)
                pipe.continuation.yield()
            }

            pipe.reset()
            atomStore.set(.second, for: phase)

            let before = await atomStore.watch(atom, subscriber: subscriber, subscription: Subscription()).value
            let after = await atomStore.watch(atom, subscriber: subscriber, subscription: Subscription()).value

            #expect(before == 0)
            #expect(after == 1)
            #expect(store.children[AtomKey(c)] == nil)
            #expect(store.dependencies[AtomKey(atom)] == [AtomKey(phase), AtomKey(a), AtomKey(d), AtomKey(b)])

            let state = store.states[AtomKey(atom)]

            // TestAtom's Task cancellation
            #expect(state?.transactionState?.onTermination != nil)
        }

        do {
            // third

            Task {
                await pipe.stream.next()
                atomStore.set(2, for: b)
                pipe.continuation.yield()
            }

            pipe.reset()
            atomStore.set(.third, for: phase)
            let before = await atomStore.watch(atom, subscriber: subscriber, subscription: Subscription()).value
            let after = await atomStore.watch(atom, subscriber: subscriber, subscription: Subscription()).value

            #expect(before == 1)
            #expect(after == 3)
            #expect(store.children[AtomKey(a)] == nil)
            #expect(store.dependencies[AtomKey(atom)] == [AtomKey(phase), AtomKey(b), AtomKey(c), AtomKey(d)])

            let state = store.states[AtomKey(atom)]

            // TestAtom's Task cancellation
            #expect(state?.transactionState?.onTermination != nil)
        }

        do {
            subscriberState = nil
            let key = AtomKey(atom)

            #expect(store.caches[key] == nil)
            #expect(store.states[key] == nil)
        }
    }
}

private extension AsyncSequence {
    func next() async -> Element? {
        var iterator = makeAsyncIterator()
        return try? await iterator.next()
    }
}
