import Combine
import XCTest

@testable import Atoms

final class StoreContextTests: XCTestCase {
    @MainActor
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

        XCTAssertEqual(context.read(atom), 0)
        XCTAssertNil(store.state.caches[key])
        XCTAssertTrue(snapshots.isEmpty)

        snapshots.removeAll()
        store.graph.children[key] = [AtomKey(TestAtom(value: 1))]
        XCTAssertEqual(context.read(atom), 0)
        XCTAssertTrue(snapshots.isEmpty)

        snapshots.removeAll()
        store.state.caches[key] = AtomCache(atom: atom, value: 1)
        XCTAssertEqual(context.read(atom), 1)
        XCTAssertTrue(snapshots.isEmpty)
    }

    @MainActor
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
        XCTAssertEqual(updateCount, 0)
        XCTAssertNil(store.state.states[key])
        XCTAssertNil(store.state.caches[key])
        XCTAssertTrue(snapshots.isEmpty)

        snapshots.removeAll()
        store.state.caches[key] = AtomCache(atom: atom, value: 0)
        store.state.states[key] = AtomState(effect: TestEffect())
        store.state.subscriptions[key, default: [:]][subscriberToken.key] = Subscription(
            location: SourceLocation(),
            update: { updateCount += 1 }
        )
        context.set(2, for: atom)
        XCTAssertEqual(
            snapshots.map { $0.caches.mapValues { $0.value as? Int } },
            [[key: 2]]
        )
        XCTAssertEqual(updateCount, 1)
        XCTAssertNil(store.state.states[key]?.transactionState)
        XCTAssertEqual((store.state.caches[key] as? AtomCache<TestStateAtom<Int>>)?.value, 2)

        snapshots.removeAll()
        context.set(3, for: atom)
        XCTAssertEqual(updateCount, 2)
        XCTAssertNotNil(store.state.states[key])
        XCTAssertNil(store.state.states[key]?.transactionState)
        XCTAssertEqual((store.state.caches[key] as? AtomCache<TestStateAtom<Int>>)?.value, 3)
        XCTAssertEqual(
            snapshots.map { $0.caches.mapValues { $0.value as? Int } },
            [[key: 3]]
        )
    }

    @MainActor
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
        XCTAssertEqual(updateCount, 0)
        XCTAssertNil(store.state.states[key])
        XCTAssertNil(store.state.caches[key])
        XCTAssertTrue(snapshots.isEmpty)

        snapshots.removeAll()
        store.state.caches[key] = AtomCache(atom: atom, value: 0)
        store.state.states[key] = AtomState(effect: TestEffect())
        store.state.subscriptions[key, default: [:]][subscriberToken.key] = Subscription(
            location: SourceLocation(),
            update: { updateCount += 1 }
        )
        context.modify(atom) { $0 = 2 }
        XCTAssertEqual(updateCount, 1)
        XCTAssertNil(store.state.states[key]?.transactionState)
        XCTAssertEqual((store.state.caches[key] as? AtomCache<TestStateAtom<Int>>)?.value, 2)
        XCTAssertEqual(
            snapshots.map { $0.caches.mapValues { $0.value as? Int } },
            [[key: 2]]
        )

        snapshots.removeAll()
        context.modify(atom) { $0 = 3 }
        XCTAssertEqual(updateCount, 2)
        XCTAssertNotNil(store.state.states[key])
        XCTAssertNil(store.state.states[key]?.transactionState)
        XCTAssertEqual((store.state.caches[key] as? AtomCache<TestStateAtom<Int>>)?.value, 3)
        XCTAssertEqual(
            snapshots.map { $0.caches.mapValues { $0.value as? Int } },
            [[key: 3]]
        )
    }

    @MainActor
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

        XCTAssertEqual(context.watch(dependency0, in: transactionState), 0)
        XCTAssertEqual(store.graph.dependencies, [key: [dependency0Key]])
        XCTAssertEqual(store.graph.children, [dependency0Key: [key]])
        XCTAssertEqual((store.state.caches[dependency0Key] as? AtomCache<TestStateAtom<Int>>)?.value, 0)
        XCTAssertNotNil(store.state.states[dependency0Key])
        XCTAssertTrue(snapshots.flatMap(\.caches).isEmpty)

        transactionState.terminate()

        XCTAssertEqual(context.watch(dependency1, in: transactionState), 1)
        XCTAssertEqual(store.graph.dependencies, [key: [dependency0Key]])
        XCTAssertEqual(store.graph.children, [dependency0Key: [key]])
        XCTAssertNil(store.state.caches[dependency1Key])
        XCTAssertNil(store.state.states[dependency1Key])
        XCTAssertTrue(snapshots.isEmpty)
    }

    @MainActor
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

        XCTAssertEqual(initialValue, 0)
        XCTAssertTrue(subscriber.subscribing.contains(key))
        XCTAssertNotNil(store.state.subscriptions[key]?[subscriber.key])
        XCTAssertEqual((store.state.caches[key] as? AtomCache<TestAtom>)?.value, 0)
        XCTAssertEqual((store.state.caches[dependencyKey] as? AtomCache<DependencyAtom>)?.value, 0)
        XCTAssertEqual(
            snapshots.map { $0.caches.mapValues { $0.value as? Int } },
            [[key: 0, dependencyKey: 0]]
        )

        snapshots.removeAll()
        store.state.subscriptions[key]?[subscriber.key]?.update()
        subscriberState = nil
        XCTAssertEqual(updateCount, 1)
        XCTAssertNil(store.state.caches[key])
        XCTAssertNil(store.state.states[key])
        XCTAssertNil(store.state.caches[dependencyKey])
        XCTAssertNil(store.state.states[dependencyKey])
        XCTAssertEqual(
            snapshots.map { $0.caches.mapValues { $0.value as? Int } },
            [[:]]
        )
    }

    @MainActor
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
        XCTAssertEqual(phase0.value, 0)
        XCTAssertNil(store.state.caches[key])
        XCTAssertNil(store.state.states[key])
        XCTAssertTrue(snapshots.isEmpty)

        var updateCount = 0
        let phase1 = context.watch(
            atom,
            subscriber: subscriber,
            subscription: Subscription {
                updateCount += 1
            }
        )

        XCTAssertTrue(phase1.isSuspending)

        snapshots.removeAll()

        let phase2 = await context.refresh(atom)
        XCTAssertEqual(phase2.value, 0)
        XCTAssertNotNil(store.state.states[key])
        XCTAssertEqual((store.state.caches[key] as? AtomCache<TestPublisherAtom<Just<Int>>>)?.value, .success(0))
        XCTAssertEqual(updateCount, 1)
        XCTAssertEqual(
            snapshots.map { $0.caches.mapValues { $0.value as? AsyncPhase<Int, Never> } },
            [[key: .success(0)]]
        )

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
        XCTAssertEqual(phase3.value, 1)

        let phase4 = await scopedContext.refresh(atom)
        XCTAssertEqual(phase4.value, 1)
        XCTAssertNotNil(store.state.states[overrideAtomKey])
        XCTAssertEqual(
            (store.state.caches[overrideAtomKey] as? AtomCache<TestPublisherAtom<Just<Int>>>)?.value,
            .success(1)
        )
    }

    @MainActor
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
        XCTAssertNil(store.state.caches[key])
        XCTAssertNil(store.state.states[key])
        XCTAssertTrue(snapshots.isEmpty)

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
        XCTAssertEqual(updateCount, 1)
        XCTAssertEqual(
            snapshots.map { $0.caches.mapValues { $0.value as? Int } },
            [[key: 1]]
        )

        snapshots.removeAll()
        context.reset(atom)
        XCTAssertEqual(updateCount, 2)
        XCTAssertEqual(
            snapshots.map { $0.caches.mapValues { $0.value as? Int } },
            [[key: 0]]
        )
    }

    @MainActor
    func testUnwatch() {
        let store = AtomStore()
        let subscriberState = SubscriberState()
        let subscriber = Subscriber(subscriberState)
        let atom = TestStateAtom(defaultValue: 0)
        var snapshots = [Snapshot]()
        let observer = Observer { snapshots.append($0) }
        let rootScopeToken = ScopeKey.Token()
        let context = StoreContext.root(
            store: store,
            scopeKey: rootScopeToken.key,
            observers: [observer],
            overrideContainer: OverrideContainer()
        )

        _ = context.watch(atom, subscriber: subscriber, subscription: Subscription())
        snapshots.removeAll()
        context.unwatch(atom, subscriber: subscriber)
        XCTAssertEqual(
            snapshots.map { $0.caches.mapValues { $0.value as? Int } },
            [[:]]
        )
    }

    @MainActor
    func testSnapshotAndRestore() {
        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let subscriberToken = SubscriberKey.Token()
        let context = StoreContext.root(store: store, scopeKey: rootScopeToken.key)
        let atom0 = TestAtom(value: 0)
        let atom1 = TestAtom(value: 1)
        let key0 = AtomKey(atom0)
        let key1 = AtomKey(atom1)
        let graph = Graph(
            dependencies: [key0: [key1]],
            children: [key1: [key0]]
        )
        let caches = [
            key0: AtomCache(atom: atom0, value: 0),
            key1: AtomCache(atom: atom1, value: 1),
        ]
        let subscription = Subscription()

        store.graph = graph
        store.state.caches = caches
        store.state.subscriptions[key0, default: [:]][subscriberToken.key] = subscription
        store.state.subscriptions[key1, default: [:]][subscriberToken.key] = subscription

        let snapshot = context.snapshot()

        XCTAssertEqual(snapshot.graph, graph)
        XCTAssertEqual(
            snapshot.caches.mapValues { $0 as? AtomCache<TestAtom<Int>> },
            caches
        )
    }

    @MainActor
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

        XCTAssertEqual(scoped1Context.watch(atom0, subscriber: subscriber, subscription: Subscription()), 10)
        XCTAssertEqual(scoped1Context.watch(atom1, subscriber: subscriber, subscription: Subscription()), 20)
        XCTAssertEqual(scoped2Context.watch(atom0, subscriber: subscriber, subscription: Subscription()), 30)
        XCTAssertEqual(scoped2Context.watch(atom1, subscriber: subscriber, subscription: Subscription()), 30)
        XCTAssertEqual(
            store.state.caches.compactMapValues { $0 as? AtomCache<TestAtom<Int>> },
            [
                AtomKey(atom0): AtomCache(atom: atom0, value: 10),
                AtomKey(atom1, scopeKey: scope1Token.key): AtomCache(atom: atom1, value: 20),
                AtomKey(atom0, scopeKey: scope2Token.key): AtomCache(atom: atom0, value: 30),
                AtomKey(atom1, scopeKey: scope2Token.key): AtomCache(atom: atom1, value: 30),
            ]
        )
    }

    @MainActor
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
        XCTAssertEqual(
            context.watch(dependency1Atom, subscriber: subscriber, subscription: Subscription()),
            1
        )
        XCTAssertEqual(
            context.watch(dependency2Atom, subscriber: subscriber, subscription: Subscription()),
            2
        )
        XCTAssertEqual(
            scoped1Context.watch(dependency1Atom, subscriber: subscriber, subscription: Subscription()),
            10
        )
        XCTAssertEqual(
            scoped2Context.watch(dependency2Atom, subscriber: subscriber, subscription: Subscription()),
            20
        )

        // Shouldn't set the value in the scope that atoms are not overridden.
        scoped1Context.set(100, for: dependency1Atom)
        XCTAssertEqual(context.read(dependency1Atom), 1)

        // Shouldn't modify the value in the scope that atoms are not overridden.
        scoped1Context.modify(dependency1Atom) { $0 = 1000 }
        XCTAssertEqual(context.read(dependency1Atom), 1)

        // Shouldn't reset the value in the scope that atoms are not overridden.
        context.reset(dependency1Atom)
        XCTAssertEqual(scoped1Context.read(dependency1Atom), 1000)

        context.unwatch(dependency1Atom, subscriber: subscriber)
        context.unwatch(dependency2Atom, subscriber: subscriber)
        scoped1Context.unwatch(dependency1Atom, subscriber: subscriber)
        scoped2Context.unwatch(dependency1Atom, subscriber: subscriber)

        // Override for `scoped1Context` shouldn't inherited to `scoped2Context`.
        XCTAssertEqual(scoped2Context.watch(atom, subscriber: subscriber, subscription: Subscription()), 21)
        XCTAssertEqual(scoped2Context.watch(publisherAtom, subscriber: subscriber, subscription: Subscription()), .suspending)

        // Should set the value and then update the dependent atoms transitively.
        scoped2Context.set(20, for: dependency1Atom)

        // Should set the value because the atom depends on the shared `dependency1Atom`.
        context.set(30, for: dependency1Atom)

        // Should return overridden values.
        XCTAssertEqual(scoped2Context.read(atom), 50)
        XCTAssertEqual(scoped2Context.read(dependency1Atom), 30)
        XCTAssertEqual(scoped2Context.read(dependency2Atom), 20)

        // Should return the value cached when accessed via the `scoped2Context` as it's cached as a shared value.
        XCTAssertEqual(context.read(atom), 50)

        // Should modify the value because the `atom` depends on the shared `dependency1Atom`
        // and the `dependency1Atom` is scoped for `scoped2Context`.
        scoped2Context.modify(dependency1Atom) { $0 = 40 }
        XCTAssertEqual(scoped2Context.read(dependency1Atom), 40)

        // Shouldn't modify the value because `dependency2Atom` is scoped for `scoped2Context`.
        context.modify(dependency2Atom) { $0 = 50 }
        XCTAssertEqual(scoped2Context.read(dependency2Atom), 20)
        XCTAssertEqual(scoped2Context.read(atom), 60)

        do {
            let phase = await scoped2Context.refresh(publisherAtom)
            XCTAssertEqual(phase, .success(60))
        }

        // Should reset the value.
        scoped2Context.reset(dependency1Atom)
        XCTAssertEqual(scoped2Context.read(dependency1Atom), 1)
        XCTAssertEqual(scoped2Context.read(atom), 21)

        do {
            let phase = await scoped2Context.refresh(publisherAtom)
            XCTAssertEqual(phase, .success(21))
        }

        // Should add 'atom' as a dependency of `transactionAtom`.
        XCTAssertEqual(scoped2Context.watch(atom, in: transactionState), 21)

        XCTAssertEqual(
            store.graph,
            Graph(
                dependencies: [
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
                ],
                children: [
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
        )

        XCTAssertEqual(
            store.state.caches.mapValues { $0 as? AtomCache<TestAtom> },
            [
                AtomKey(publisherAtom): nil,
                AtomKey(atom): AtomCache(atom: atom, value: 21),
                AtomKey(dependency1Atom): nil,
                AtomKey(dependency2Atom, scopeKey: scope2Token.key): nil,
            ]
        )
        XCTAssertEqual(
            store.state.caches.mapValues { $0 as? AtomCache<TestPublisherAtom> },
            [
                AtomKey(publisherAtom): AtomCache(atom: publisherAtom, value: .success(21)),
                AtomKey(atom): nil,
                AtomKey(dependency1Atom): nil,
                AtomKey(dependency2Atom, scopeKey: scope2Token.key): nil,
            ]
        )
        XCTAssertEqual(
            store.state.caches.mapValues { $0 as? AtomCache<TestDependency1Atom> },
            [
                AtomKey(publisherAtom): nil,
                AtomKey(atom): nil,
                AtomKey(dependency1Atom): AtomCache(atom: dependency1Atom, value: 1),
                AtomKey(dependency2Atom, scopeKey: scope2Token.key): nil,
            ]
        )
        XCTAssertEqual(
            store.state.caches.mapValues { $0 as? AtomCache<TestDependency2Atom> },
            [
                AtomKey(publisherAtom): nil,
                AtomKey(atom): nil,
                AtomKey(dependency1Atom): nil,
                AtomKey(dependency2Atom, scopeKey: scope2Token.key): AtomCache(atom: dependency2Atom, value: 20),
            ]
        )
    }

    @MainActor
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
        XCTAssertEqual(
            scopedContext.watch(TestAtom(), subscriber: subscriber, subscription: Subscription()),
            24
        )

        await Task.yield {
            context.read(TestDependency4Atom()).isSuccess
        }

        // The updated value should reflect the scoped overrides.
        XCTAssertEqual(
            scopedContext.watch(TestAtom(), subscriber: subscriber, subscription: Subscription()),
            28
        )

        // Update one of the dependency atoms from non-scoped context.
        context.set(10, for: TestDependency1Atom())

        await Task.yield {
            scopedContext.watch(TestDependency4Atom(), subscriber: subscriber, subscription: Subscription()).isSuccess
        }

        // The updated value should reflect the scoped overrides.
        XCTAssertEqual(
            scopedContext.watch(TestAtom(), subscriber: subscriber, subscription: Subscription()),
            37
        )
    }

    @MainActor
    func testRelease() {
        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let context = StoreContext.root(store: store, scopeKey: rootScopeToken.key)

        let atom = TestAtom(value: 0)
        let key = AtomKey(atom)
        let subscriberState = SubscriberState()
        let subscriber = Subscriber(subscriberState)

        _ = context.watch(atom, subscriber: subscriber, subscription: Subscription())
        XCTAssertNotNil(store.state.caches[key])

        context.unwatch(atom, subscriber: subscriber)
        XCTAssertNil(store.state.caches[key])
    }

    @MainActor
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

        XCTAssertEqual(
            snapshots.map { $0.caches.mapValues { $0 as? AtomCache<TestAtom<Int>> } },
            [
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
        XCTAssertEqual(
            scopedSnapshots.map { $0.caches.mapValues { $0 as? AtomCache<TestAtom<Int>> } },
            [
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

        XCTAssertEqual(
            snapshots.map { $0.caches.mapValues { $0 as? AtomCache<TestAtom<Int>> } },
            [
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
        XCTAssertEqual(
            scopedSnapshots.map { $0.caches.mapValues { $0 as? AtomCache<TestAtom<Int>> } },
            [
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

        XCTAssertEqual(
            snapshots.map { $0.caches.mapValues { $0 as? AtomCache<TestAtom<Int>> } },
            [
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
        XCTAssertEqual(
            scopedSnapshots.map { $0.caches.mapValues { $0 as? AtomCache<TestAtom<Int>> } },
            [
                [

                    AtomKey(atom1): AtomCache(atom: atom1, value: 1),
                    AtomKey(atom2): AtomCache(atom: atom2, value: 2),
                ]
            ]
        )
    }

    @MainActor
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

        let expectedGraph = Graph(
            dependencies: [
                AtomKey(TestAtom()): [
                    AtomKey(TestDependency1Atom()),
                    AtomKey(TestDependency2Atom()),
                    AtomKey(TestDependency3Atom(), scopeKey: scopeToken.key),
                ]
            ],
            children: [
                AtomKey(TestDependency1Atom()): [AtomKey(TestAtom())],
                AtomKey(TestDependency2Atom()): [AtomKey(TestAtom())],
                AtomKey(TestDependency3Atom(), scopeKey: scopeToken.key): [AtomKey(TestAtom())],
            ]
        )

        // Initialize the atom state in the scoped context.
        _ = scopedContext.watch(atom, subscriber: subscriber, subscription: Subscription())

        // The scoped observer should recive the update event.
        XCTAssertEqual(snapshots.map(\.graph), [expectedGraph])

        context.set(20, for: TestDependency2Atom())

        // The scoped observer should recive the update event.
        XCTAssertEqual(snapshots.map(\.graph), [expectedGraph, expectedGraph])
    }

    @MainActor
    func testRestore() {
        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let context = StoreContext.root(store: store, scopeKey: rootScopeToken.key)
        let atom0 = TestAtom(value: 0)
        let atom1 = TestAtom(value: 1)
        let atom2 = TestAtom(value: 2)
        let location = SourceLocation()
        let subscriberToken = SubscriberKey.Token()

        store.graph = Graph(
            dependencies: [AtomKey(atom0): [AtomKey(atom1)]],
            children: [AtomKey(atom1): [AtomKey(atom0)]]
        )
        store.state.caches = [
            AtomKey(atom0): AtomCache(atom: atom0, value: 0),
            AtomKey(atom1): AtomCache(atom: atom1, value: 1),
        ]

        let snapshot = context.snapshot()

        store.graph = Graph()
        store.state = StoreState()
        store.state.caches = [
            AtomKey(atom2): AtomCache(atom: atom2, value: 2)
        ]

        var updated = Set<AtomKey>()
        let subscription0 = Subscription(location: location) { updated.insert(AtomKey(atom0)) }
        let subscription1 = Subscription(location: location) { updated.insert(AtomKey(atom1)) }
        let subscription2 = Subscription(location: location) { updated.insert(AtomKey(atom2)) }

        store.state.subscriptions = [
            AtomKey(atom0): [subscriberToken.key: subscription0],
            AtomKey(atom1): [subscriberToken.key: subscription1],
            AtomKey(atom2): [subscriberToken.key: subscription2],
        ]

        context.restore(snapshot)

        // Notifies updated only for the subscriptions of the atoms that are restored.
        XCTAssertEqual(updated, [AtomKey(atom0), AtomKey(atom1)])
        XCTAssertEqual(
            store.graph,
            Graph(
                dependencies: [AtomKey(atom0): [AtomKey(atom1)]],
                children: [AtomKey(atom1): [AtomKey(atom0)]]
            )
        )
        // Do not delete caches added after the snapshot was taken.
        XCTAssertEqual(
            store.state.caches.mapValues { $0 as? AtomCache<TestAtom<Int>> },
            [
                AtomKey(atom0): AtomCache(atom: atom0, value: 0),
                AtomKey(atom1): AtomCache(atom: atom1, value: 1),
                AtomKey(atom2): AtomCache(atom: atom2, value: 2),
            ]
        )

        // Restore with no subscriptions.
        store.state.subscriptions.removeAll()
        context.restore(snapshot)

        XCTAssertEqual(store.graph, Graph())

        // Caches added after the snapshot was taken are not forcibly released by restore,
        // but this is not a problem since the cache should originally be released
        // when the subscription is released.
        XCTAssertEqual(
            store.state.caches.mapValues { $0 as? AtomCache<TestAtom<Int>> },
            [
                AtomKey(atom2): AtomCache(atom: atom2, value: 2)
            ]
        )
    }

    @MainActor
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

        XCTAssertTrue((store.state.states[key]?.effect as? TestEffect) === effect)
        XCTAssertEqual(effect.initializedCount, 1)
        XCTAssertEqual(effect.updatedCount, 0)
        XCTAssertEqual(effect.releasedCount, 0)

        context.set(1, for: atom)

        XCTAssertTrue((store.state.states[key]?.effect as? TestEffect) === effect)
        XCTAssertEqual(effect.initializedCount, 1)
        XCTAssertEqual(effect.updatedCount, 1)
        XCTAssertEqual(effect.releasedCount, 0)

        context.set(2, for: atom)
        context.set(3, for: atom)
        context.set(4, for: atom)

        XCTAssertTrue((store.state.states[key]?.effect as? TestEffect) === effect)
        XCTAssertEqual(effect.initializedCount, 1)
        XCTAssertEqual(effect.updatedCount, 4)
        XCTAssertEqual(effect.releasedCount, 0)

        context.set("Updated", for: upstreamAtom)

        XCTAssertTrue((store.state.states[key]?.effect as? TestEffect) === effect)
        XCTAssertEqual(effect.initializedCount, 1)
        XCTAssertEqual(effect.updatedCount, 5)
        XCTAssertEqual(effect.releasedCount, 0)

        context.unwatch(atom, subscriber: subscriber)

        XCTAssertNil(store.state.states[key])
        XCTAssertEqual(effect.initializedCount, 1)
        XCTAssertEqual(effect.updatedCount, 5)
        XCTAssertEqual(effect.releasedCount, 1)

        context.set(5, for: atom)

        XCTAssertNil(store.state.states[key])
        XCTAssertEqual(effect.initializedCount, 1)
        XCTAssertEqual(effect.updatedCount, 5)
        XCTAssertEqual(effect.releasedCount, 1)
    }

    @MainActor
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

        XCTAssertEqual(value0, 0)
        XCTAssertEqual(updateCount, 0)

        context.set(1, for: TestAtom1())
        let value1 = context.read(TestAtom4())

        XCTAssertEqual(value1, 6)
        XCTAssertEqual(updateCount, 1)
    }

    @MainActor
    func testTransitiveUpdate() {
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

        XCTAssertEqual(value0, 0)
        XCTAssertEqual(updateCount, 0)

        context.set(1, for: TestAtom1())
        let value1 = context.read(TestAtom2())

        XCTAssertEqual(value1, 1)
        XCTAssertEqual(updateCount, 1)

        context.set(1, for: TestAtom1())
        let value2 = context.read(TestAtom2())

        XCTAssertEqual(value2, 1)
        XCTAssertEqual(updateCount, 1)
    }

    @MainActor
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

            XCTAssertEqual(value0, 0)
            XCTAssertEqual(value1, 0)
            XCTAssertEqual(value2, 0)
            XCTAssertEqual(updateCount, 0)

            context.set(1, for: TestAtom1())
            let value3 = context.read(TestAtom2().changes)
            let value4 = context.read(TestAtom3().changes)
            let value5 = context.read(TestAtom4())

            XCTAssertEqual(value3, 1)
            XCTAssertEqual(value4, 1)
            XCTAssertEqual(value5, 1)
            XCTAssertEqual(updateCount, 1)

            context.set(1, for: TestAtom1())
            let value6 = context.read(TestAtom2().changes)
            let value7 = context.read(TestAtom3().changes)
            let value8 = context.read(TestAtom4())

            XCTAssertEqual(value6, 1)
            XCTAssertEqual(value7, 1)
            XCTAssertEqual(value8, 1)
            XCTAssertEqual(updateCount, 2)
        }
    }

    @MainActor
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

            XCTAssertEqual(value0, 0)
            XCTAssertEqual(value1, 0)
            XCTAssertEqual(value2, 0)
            XCTAssertEqual(updateCount, 0)

            context.set(1, for: TestAtom1())
            let value3 = context.read(TestAtom2().changes)
            let value4 = context.read(TestAtom3().changes)
            let value5 = context.read(TestAtom4())

            XCTAssertEqual(value3, 1)
            XCTAssertEqual(value4, 1)
            XCTAssertEqual(value5, 2)
            XCTAssertEqual(updateCount, 1)

            context.set(1, for: TestAtom1())
            let value6 = context.read(TestAtom2().changes)
            let value7 = context.read(TestAtom3().changes)
            let value8 = context.read(TestAtom4())

            XCTAssertEqual(value6, 1)
            XCTAssertEqual(value7, 1)
            XCTAssertEqual(value8, 2)
            XCTAssertEqual(updateCount, 1)
        }
    }

    @MainActor
    func testUnsubscribeOnBackgroundThread() {
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

            let expectation = expectation(description: #function)
            expectation.expectedFulfillmentCount = 3

            // Release the subscriber state on the detached background thread.
            Task.detached {
                host.subscriberState = nil
                expectation.fulfill()
            }

            // Set a new value to the root atom.
            // This causes data race in the internal mechanism
            // if main actor isolation is not working correctly.
            Task {
                context.set(100, for: TestAtom1())
                expectation.fulfill()
            }

            // Waits until unsubscription is performed.
            Task.detached {
                for _ in 0... {
                    if await context.lookup(TestAtom1()) == nil {
                        expectation.fulfill()
                        break
                    }
                }
            }

            wait(for: [expectation], timeout: 0.5)
            XCTAssertNil(context.lookup(TestAtom1()))
            XCTAssertNil(context.lookup(TestAtom2()))
            XCTAssertTrue(store.state.subscriptions.isEmpty)
        }
    }

    @MainActor
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

            XCTAssertEqual(value, 0)
            XCTAssertNil(store.graph.children[AtomKey(d)])
            XCTAssertEqual(
                store.graph.dependencies[AtomKey(atom)],
                [AtomKey(phase), AtomKey(a), AtomKey(b), AtomKey(c)]
            )

            let state = store.state.states[AtomKey(atom)]

            // TestAtom's Task cancellation
            XCTAssertNotNil(state?.transactionState?.onTermination)
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

            XCTAssertEqual(before, 0)
            XCTAssertEqual(after, 1)
            XCTAssertNil(store.graph.children[AtomKey(c)])
            XCTAssertEqual(
                store.graph.dependencies[AtomKey(atom)],
                [AtomKey(phase), AtomKey(a), AtomKey(d), AtomKey(b)]
            )

            let state = store.state.states[AtomKey(atom)]

            // TestAtom's Task cancellation
            XCTAssertNotNil(state?.transactionState?.onTermination)
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

            XCTAssertEqual(before, 1)
            XCTAssertEqual(after, 3)
            XCTAssertNil(store.graph.children[AtomKey(a)])
            XCTAssertEqual(
                store.graph.dependencies[AtomKey(atom)],
                [AtomKey(phase), AtomKey(b), AtomKey(c), AtomKey(d)]
            )

            let state = store.state.states[AtomKey(atom)]

            // TestAtom's Task cancellation
            XCTAssertNotNil(state?.transactionState?.onTermination)
        }

        do {
            subscriberState = nil
            let key = AtomKey(atom)

            XCTAssertNil(store.state.caches[key])
            XCTAssertNil(store.state.states[key])
        }
    }
}

private extension AsyncSequence {
    func next() async -> Element? {
        var iterator = makeAsyncIterator()
        return try? await iterator.next()
    }
}
