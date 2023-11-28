import Combine
import XCTest

@testable import Atoms

@MainActor
final class StoreContextTests: XCTestCase {
    func testScopedConstructor() {
        let store = AtomStore()
        let token = ScopeKey.Token()
        let scopeKey = ScopeKey(token: token)
        let atom = TestAtom(value: 0)
        let transaction = Transaction(key: AtomKey(atom)) {}
        let context = StoreContext.scoped(
            key: scopeKey,
            store: store,
            observers: [],
            overrides: [
                OverrideKey(atom): AtomOverride<TestAtom<Int>> { _ in
                    10
                }
            ]
        )

        XCTAssertEqual(context.watch(atom, in: transaction), 10)
        XCTAssertEqual(
            store.graph.children,
            [
                AtomKey(atom, overrideScopeKey: scopeKey): [AtomKey(atom)]
            ]
        )
        XCTAssertEqual(
            store.graph.dependencies,
            [
                AtomKey(atom): [AtomKey(atom, overrideScopeKey: scopeKey)]
            ]
        )
    }

    func testScoped() {
        let store = AtomStore()
        let container = SubscriptionContainer()
        let atom = TestValueAtom(value: 0)
        var snapshots0 = [Snapshot]()
        var snapshots1 = [Snapshot]()
        let observer0 = Observer { snapshots0.append($0) }
        let observer1 = Observer { snapshots1.append($0) }
        let context = StoreContext(
            store,
            observers: [observer0]
        )
        let scopedContext = context.scoped(
            key: ScopeKey(token: ScopeKey.Token()),
            observers: [observer1],
            overrides: [
                OverrideKey(atom): AtomOverride<TestValueAtom<Int>> { _ in
                    10
                }
            ]
        )

        XCTAssertEqual(scopedContext.watch(atom, container: container.wrapper, requiresObjectUpdate: false) {}, 10)
        XCTAssertFalse(snapshots0.isEmpty)
        XCTAssertFalse(snapshots1.isEmpty)
    }

    func testStoreDeinit() {
        let atom = TestAtom(value: 0)
        let container = SubscriptionContainer()
        var store: AtomStore? = AtomStore()
        weak var storeRef = store
        let context = StoreContext(store!)

        XCTAssertEqual(context.watch(atom, container: container.wrapper, requiresObjectUpdate: false) {}, 0)
        XCTAssertNotNil(storeRef)
        store = nil
        XCTAssertNil(storeRef)
    }

    func testRead() {
        let store = AtomStore()
        let atom = TestAtom(value: 0)
        let key = AtomKey(atom)
        var snapshots = [Snapshot]()
        let observer = Observer { snapshots.append($0) }
        let context = StoreContext(store, observers: [observer])

        XCTAssertEqual(context.read(atom), 0)
        XCTAssertNil(store.state.caches[key])
        XCTAssertEqual(
            snapshots.map { $0.caches.mapValues { $0.value as? Int } },
            [
                [key: 0],
                [:],
            ]
        )

        snapshots.removeAll()
        store.graph.children[key] = [AtomKey(TestAtom(value: 1))]
        XCTAssertEqual(context.read(atom), 0)
        XCTAssertEqual(
            snapshots.map { $0.caches.mapValues { $0.value as? Int } },
            [
                [key: 0]
            ]
        )

        snapshots.removeAll()
        store.state.caches[key] = AtomCache(atom: atom, value: 1)
        XCTAssertEqual(context.read(atom), 1)
        XCTAssertTrue(snapshots.isEmpty)
    }

    func testSet() {
        let store = AtomStore()
        let token = SubscriptionKey.Token()
        let subscriptionKey = SubscriptionKey(token: token)
        let atom = TestStateAtom(defaultValue: 0)
        let key = AtomKey(atom)
        var updateCount = 0
        var snapshots = [Snapshot]()
        let observer = Observer { snapshots.append($0) }
        let context = StoreContext(store, observers: [observer])

        context.set(1, for: atom)
        XCTAssertEqual(updateCount, 0)
        XCTAssertNil(store.state.states[key])
        XCTAssertNil(store.state.caches[key])
        XCTAssertTrue(snapshots.isEmpty)

        snapshots.removeAll()
        store.state.caches[key] = AtomCache(atom: atom, value: 0)
        store.state.states[key] = AtomState(coordinator: atom.makeCoordinator())
        store.state.subscriptions[key, default: [:]][subscriptionKey] = Subscription(
            location: SourceLocation(),
            requiresObjectUpdate: false,
            notifyUpdate: { updateCount += 1 }
        )
        context.set(2, for: atom)
        XCTAssertEqual(
            snapshots.map { $0.caches.mapValues { $0.value as? Int } },
            [[key: 2]]
        )
        XCTAssertEqual(updateCount, 1)
        XCTAssertNil(store.state.states[key]?.transaction)
        XCTAssertEqual((store.state.caches[key] as? AtomCache<TestStateAtom<Int>>)?.value, 2)

        snapshots.removeAll()
        context.set(3, for: atom)
        XCTAssertEqual(updateCount, 2)
        XCTAssertNotNil(store.state.states[key])
        XCTAssertNil(store.state.states[key]?.transaction)
        XCTAssertEqual((store.state.caches[key] as? AtomCache<TestStateAtom<Int>>)?.value, 3)
        XCTAssertEqual(
            snapshots.map { $0.caches.mapValues { $0.value as? Int } },
            [[key: 3]]
        )
    }

    func testModify() {
        let store = AtomStore()
        let token = SubscriptionKey.Token()
        let subscriptionKey = SubscriptionKey(token: token)
        var updateCount = 0
        let atom = TestStateAtom(defaultValue: 0)
        let key = AtomKey(atom)
        var snapshots = [Snapshot]()
        let observer = Observer { snapshots.append($0) }
        let context = StoreContext(store, observers: [observer])

        context.modify(atom) { $0 = 1 }
        XCTAssertEqual(updateCount, 0)
        XCTAssertNil(store.state.states[key])
        XCTAssertNil(store.state.caches[key])
        XCTAssertTrue(snapshots.isEmpty)

        snapshots.removeAll()
        store.state.caches[key] = AtomCache(atom: atom, value: 0)
        store.state.states[key] = AtomState(coordinator: atom.makeCoordinator())
        store.state.subscriptions[key, default: [:]][subscriptionKey] = Subscription(
            location: SourceLocation(),
            requiresObjectUpdate: false,
            notifyUpdate: { updateCount += 1 }
        )
        context.modify(atom) { $0 = 2 }
        XCTAssertEqual(updateCount, 1)
        XCTAssertNil(store.state.states[key]?.transaction)
        XCTAssertEqual((store.state.caches[key] as? AtomCache<TestStateAtom<Int>>)?.value, 2)
        XCTAssertEqual(
            snapshots.map { $0.caches.mapValues { $0.value as? Int } },
            [[key: 2]]
        )

        snapshots.removeAll()
        context.modify(atom) { $0 = 3 }
        XCTAssertEqual(updateCount, 2)
        XCTAssertNotNil(store.state.states[key])
        XCTAssertNil(store.state.states[key]?.transaction)
        XCTAssertEqual((store.state.caches[key] as? AtomCache<TestStateAtom<Int>>)?.value, 3)
        XCTAssertEqual(
            snapshots.map { $0.caches.mapValues { $0.value as? Int } },
            [[key: 3]]
        )
    }

    func testWatch() {
        let store = AtomStore()
        let atom = TestAtom(value: 0)
        let dependency0 = TestStateAtom(defaultValue: 0)
        let dependency1 = TestAtom(value: 1)
        let key = AtomKey(atom)
        let dependency0Key = AtomKey(dependency0)
        let dependency1Key = AtomKey(dependency1)
        let transaction = Transaction(key: key) {}
        var snapshots = [Snapshot]()
        let observer = Observer { snapshots.append($0) }
        let context = StoreContext(store, observers: [observer])

        XCTAssertEqual(context.watch(dependency0, in: transaction), 0)
        XCTAssertEqual(store.graph.dependencies, [key: [dependency0Key]])
        XCTAssertEqual(store.graph.children, [dependency0Key: [key]])
        XCTAssertEqual((store.state.caches[dependency0Key] as? AtomCache<TestStateAtom<Int>>)?.value, 0)
        XCTAssertNotNil(store.state.states[dependency0Key])
        XCTAssertEqual(
            snapshots.map { $0.caches.mapValues { $0.value as? Int } },
            [[dependency0Key: 0]]
        )

        snapshots.removeAll()
        transaction.terminate()
        XCTAssertEqual(context.watch(dependency1, in: transaction), 1)
        XCTAssertEqual(store.graph.dependencies, [key: [dependency0Key]])
        XCTAssertEqual(store.graph.children, [dependency0Key: [key]])
        XCTAssertNil(store.state.caches[dependency1Key])
        XCTAssertNil(store.state.states[dependency1Key])
        XCTAssertEqual(
            snapshots.map { $0.caches.mapValues { $0.value as? Int } },
            [
                [dependency0Key: 0, dependency1Key: 1],
                [dependency0Key: 0],
            ]
        )
    }

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
        var container: SubscriptionContainer? = SubscriptionContainer()
        let atom = TestAtom()
        let dependency = DependencyAtom()
        let key = AtomKey(atom)
        let dependencyKey = AtomKey(dependency)
        var snapshots = [Snapshot]()
        let observer = Observer { snapshots.append($0) }
        let context = StoreContext(store, observers: [observer])
        var updateCount = 0
        let initialValue = context.watch(atom, container: container!.wrapper, requiresObjectUpdate: false) {
            updateCount += 1
        }

        XCTAssertEqual(initialValue, 0)
        XCTAssertTrue(container!.wrapper.subscribingKeys.contains(key))
        XCTAssertNotNil(store.state.subscriptions[key]?[container!.wrapper.key])
        XCTAssertEqual((store.state.caches[key] as? AtomCache<TestAtom>)?.value, 0)
        XCTAssertEqual((store.state.caches[dependencyKey] as? AtomCache<DependencyAtom>)?.value, 0)
        XCTAssertEqual(
            snapshots.map { $0.caches.mapValues { $0.value as? Int } },
            [
                [dependencyKey: 0],
                [key: 0, dependencyKey: 0],
            ]
        )

        snapshots.removeAll()
        store.state.subscriptions[key]?[container!.wrapper.key]?.notifyUpdate()
        container = nil
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

    func testRefresh() async {
        let store = AtomStore()
        let container = SubscriptionContainer()
        let atom = TestPublisherAtom(makePublisher: { Just(0) })
        let key = AtomKey(atom)
        var snapshots = [Snapshot]()
        let observer = Observer { snapshots.append($0) }
        let context = StoreContext(store, observers: [observer])

        let value0 = await context.refresh(atom).value
        XCTAssertEqual(value0, 0)
        XCTAssertNil(store.state.caches[key])
        XCTAssertNil(store.state.states[key])
        XCTAssertTrue(snapshots.isEmpty)

        var updateCount = 0
        _ = context.watch(atom, container: container.wrapper, requiresObjectUpdate: false) {
            updateCount += 1
        }

        snapshots.removeAll()
        let value1 = await context.refresh(atom).value
        XCTAssertEqual(value1, 0)
        XCTAssertNotNil(store.state.caches[key])
        XCTAssertNotNil(store.state.states[key])
        XCTAssertEqual((store.state.caches[key] as? AtomCache<TestPublisherAtom<Just<Int>>>)?.value, .success(0))
        XCTAssertEqual(updateCount, 1)
        XCTAssertEqual(
            snapshots.map { $0.caches.mapValues { $0.value as? AsyncPhase<Int, Never> } },
            [[key: .success(0)]]
        )
    }

    func testReset() {
        let store = AtomStore()
        let container = SubscriptionContainer()
        let atom = TestStateAtom(defaultValue: 0)
        let key = AtomKey(atom)
        var snapshots = [Snapshot]()
        let observer = Observer { snapshots.append($0) }
        let context = StoreContext(store, observers: [observer])
        var updateCount = 0

        _ = context.watch(atom, container: container.wrapper, requiresObjectUpdate: false) {
            updateCount += 1
        }
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

    func testUnwatch() {
        let store = AtomStore()
        let container = SubscriptionContainer()
        let atom = TestStateAtom(defaultValue: 0)
        var snapshots = [Snapshot]()
        let observer = Observer { snapshots.append($0) }
        let context = StoreContext(store, observers: [observer])

        _ = context.watch(atom, container: container.wrapper, requiresObjectUpdate: false) {}
        snapshots.removeAll()
        context.unwatch(atom, container: container.wrapper)
        XCTAssertEqual(
            snapshots.map { $0.caches.mapValues { $0.value as? Int } },
            [[:]]
        )
    }

    func testSnapshotAndRestore() {
        let store = AtomStore()
        let token = SubscriptionKey.Token()
        let subscriptionKey = SubscriptionKey(token: token)
        let context = StoreContext(store)
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
        let subscription = Subscription(location: SourceLocation(), requiresObjectUpdate: false) {}

        store.graph = graph
        store.state.caches = caches
        store.state.subscriptions[key0, default: [:]][subscriptionKey] = subscription
        store.state.subscriptions[key1, default: [:]][subscriptionKey] = subscription

        let snapshot = context.snapshot()

        XCTAssertEqual(snapshot.graph, graph)
        XCTAssertEqual(
            snapshot.caches.mapValues { $0 as? AtomCache<TestAtom<Int>> },
            caches
        )
    }

    func testScopedOverride() async {
        struct TestDependency1Atom: StateAtom, Hashable {
            func defaultValue(context: Context) -> Int {
                0
            }
        }

        struct TestDependency2Atom: StateAtom, Hashable {
            func defaultValue(context: Context) -> Int {
                0
            }
        }

        struct TestTransactionAtom: ValueAtom, Hashable {
            func value(context: Context) -> Int {
                0
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
        let container = SubscriptionContainer()
        let transaction = Transaction(key: AtomKey(transactionAtom)) {}
        let store = AtomStore()
        let scope1Token = ScopeKey.Token()
        let scope2Token = ScopeKey.Token()
        let scope1Key = ScopeKey(token: scope1Token)
        let scope2Key = ScopeKey(token: scope2Token)

        var scoped1Overrides = [OverrideKey: any AtomOverrideProtocol]()
        scoped1Overrides[OverrideKey(dependency1Atom)] = AtomOverride<TestDependency1Atom> { _ in
            10
        }

        var scoped2Overrides = [OverrideKey: any AtomOverrideProtocol]()
        scoped2Overrides[OverrideKey(dependency2Atom)] = AtomOverride<TestDependency2Atom> { _ in
            100
        }

        let context = StoreContext(store)
        let scoped1Context = context.scoped(
            key: scope1Key,
            observers: [],
            overrides: scoped1Overrides
        )
        let scoped2Context = scoped1Context.scoped(
            key: scope2Key,
            observers: [],
            overrides: scoped2Overrides
        )

        XCTAssertEqual(context.watch(dependency1Atom, container: container.wrapper, requiresObjectUpdate: false) {}, 0)

        // Shouldn't set value if the atom is overridden in the scope.
        scoped1Context.set(1, for: dependency1Atom)
        XCTAssertEqual(context.read(dependency1Atom), 0)

        // Shouldn't modify value if the atom is overridden in the scope.
        scoped1Context.modify(dependency1Atom) { $0 = 1 }
        XCTAssertEqual(context.read(dependency1Atom), 0)

        // Shouldn't reset value if the atom is overridden in the scope.
        context.set(1, for: dependency1Atom)
        scoped1Context.reset(dependency1Atom)
        XCTAssertEqual(context.read(dependency1Atom), 1)

        context.unwatch(dependency1Atom, container: container.wrapper)

        XCTAssertEqual(scoped2Context.watch(atom, container: container.wrapper, requiresObjectUpdate: false) {}, 110)
        XCTAssertEqual(scoped2Context.watch(atom, in: transaction), 110)
        XCTAssertEqual(scoped2Context.watch(publisherAtom, container: container.wrapper, requiresObjectUpdate: false) {}, .suspending)

        // Should return the default value because the atom is cached in the scoped store.
        XCTAssertEqual(context.read(dependency1Atom), 0)
        XCTAssertEqual(context.read(dependency2Atom), 0)

        // Should set the value and then propagate it to the dependent atoms..
        scoped2Context.set(20, for: dependency1Atom)

        // Shouldn't set the value here because the atom is cached in the scoped store.
        context.set(30, for: dependency1Atom)

        // Should return overridden values.
        XCTAssertEqual(scoped2Context.read(atom), 120)
        XCTAssertEqual(scoped2Context.read(dependency1Atom), 20)
        XCTAssertEqual(scoped2Context.read(dependency2Atom), 100)
        XCTAssertEqual(context.read(atom), 120)

        // Should modify the value and then propagate it to the dependent atoms..
        scoped2Context.modify(dependency1Atom) { $0 = 40 }

        // Shouldn't modify the value here because the atom is cached in the scoped store.
        context.modify(dependency1Atom) { $0 = 50 }

        // Should return overridden values.
        XCTAssertEqual(scoped2Context.read(atom), 140)
        XCTAssertEqual(scoped2Context.read(dependency1Atom), 40)
        XCTAssertEqual(scoped2Context.read(dependency2Atom), 100)
        XCTAssertEqual(context.read(atom), 140)

        do {
            let phase = await scoped2Context.refresh(publisherAtom)
            XCTAssertEqual(phase, .success(140))
        }

        // Should reset the value and then propagate it to the dependent atoms..
        scoped2Context.reset(dependency1Atom)

        // Should return overridden values.
        XCTAssertEqual(scoped2Context.read(atom), 110)
        XCTAssertEqual(scoped2Context.read(dependency1Atom), 10)
        XCTAssertEqual(scoped2Context.read(dependency2Atom), 100)
        XCTAssertEqual(context.read(atom), 110)

        do {
            let phase = await scoped2Context.refresh(publisherAtom)
            XCTAssertEqual(phase, .success(110))
        }

        XCTAssertEqual(
            store.graph,
            Graph(
                dependencies: [
                    AtomKey(transactionAtom): [
                        AtomKey(atom)
                    ],
                    AtomKey(atom): [
                        AtomKey(dependency1Atom, overrideScopeKey: scope1Key),
                        AtomKey(dependency2Atom, overrideScopeKey: scope2Key),
                    ],
                    AtomKey(publisherAtom): [
                        AtomKey(dependency1Atom, overrideScopeKey: scope1Key),
                        AtomKey(dependency2Atom, overrideScopeKey: scope2Key),
                    ],
                ],
                children: [
                    AtomKey(atom): [
                        AtomKey(transactionAtom)
                    ],
                    AtomKey(dependency1Atom, overrideScopeKey: scope1Key): [
                        AtomKey(atom),
                        AtomKey(publisherAtom),
                    ],
                    AtomKey(dependency2Atom, overrideScopeKey: scope2Key): [
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
                AtomKey(atom): AtomCache(atom: atom, value: 110),
                AtomKey(dependency1Atom, overrideScopeKey: scope1Key): nil,
                AtomKey(dependency2Atom, overrideScopeKey: scope2Key): nil,
            ]
        )
        XCTAssertEqual(
            store.state.caches.mapValues { $0 as? AtomCache<TestPublisherAtom> },
            [
                AtomKey(publisherAtom): AtomCache(atom: publisherAtom, value: .success(110)),
                AtomKey(atom): nil,
                AtomKey(dependency1Atom, overrideScopeKey: scope1Key): nil,
                AtomKey(dependency2Atom, overrideScopeKey: scope2Key): nil,
            ]
        )
        XCTAssertEqual(
            store.state.caches.mapValues { $0 as? AtomCache<TestDependency1Atom> },
            [
                AtomKey(publisherAtom): nil,
                AtomKey(atom): nil,
                AtomKey(dependency1Atom, overrideScopeKey: scope1Key): AtomCache(atom: dependency1Atom, value: 10),
                AtomKey(dependency2Atom, overrideScopeKey: scope2Key): nil,
            ]
        )
        XCTAssertEqual(
            store.state.caches.mapValues { $0 as? AtomCache<TestDependency2Atom> },
            [
                AtomKey(publisherAtom): nil,
                AtomKey(atom): nil,
                AtomKey(dependency1Atom, overrideScopeKey: scope1Key): nil,
                AtomKey(dependency2Atom, overrideScopeKey: scope2Key): AtomCache(atom: dependency2Atom, value: 100),
            ]
        )
    }

    func testCoordinator() {
        struct TestAtom: ValueAtom {
            final class Coordinator {}

            var onValue: (Coordinator) -> Void
            var onUpdated: (Coordinator) -> Void

            var key: UniqueKey {
                UniqueKey()
            }

            func makeCoordinator() -> Coordinator {
                Coordinator()
            }

            func value(context: Context) -> Int {
                onValue(context.coordinator)
                return 0
            }

            func updated(newValue: Int, oldValue: Int, context: UpdatedContext) {
                onUpdated(context.coordinator)
            }
        }

        let store = AtomStore()
        let container = SubscriptionContainer()
        let context = StoreContext(store)
        var valueCoordinator: TestAtom.Coordinator?
        var updatedCoordinator: TestAtom.Coordinator?
        let atom = TestAtom(
            onValue: { valueCoordinator = $0 },
            onUpdated: { updatedCoordinator = $0 }
        )
        let key = AtomKey(atom)

        _ = context.watch(atom, container: container.wrapper, requiresObjectUpdate: false) {}

        let state = store.state.states[key] as? AtomState<TestAtom.Coordinator>

        XCTAssertNotNil(state?.coordinator)
        XCTAssertIdentical(state?.coordinator, valueCoordinator)
        XCTAssertNil(updatedCoordinator)

        context.reset(atom)

        let newState = store.state.states[key] as? AtomState<TestAtom.Coordinator>

        XCTAssertIdentical(state?.coordinator, newState?.coordinator)
        XCTAssertIdentical(newState?.coordinator, valueCoordinator)
        XCTAssertIdentical(newState?.coordinator, updatedCoordinator)
    }

    func testRelease() {
        struct KeepAliveAtom<T: Hashable>: ValueAtom, KeepAlive, Hashable {
            var value: T

            func value(context: Context) -> T {
                value
            }
        }

        let store = AtomStore()
        let context = StoreContext(store)

        XCTContext.runActivity(named: "Normal atoms should be released.") { _ in
            let atom = TestAtom(value: 0)
            let key = AtomKey(atom)
            let container = SubscriptionContainer()

            _ = context.watch(atom, container: container.wrapper, requiresObjectUpdate: false) {}
            XCTAssertNotNil(store.state.caches[key])

            context.unwatch(atom, container: container.wrapper)
            XCTAssertNil(store.state.caches[key])
        }

        XCTContext.runActivity(named: "KeepAlive atoms should not be released.") { _ in
            let atom = KeepAliveAtom(value: 0)
            let key = AtomKey(atom)
            let container = SubscriptionContainer()

            _ = context.watch(atom, container: container.wrapper, requiresObjectUpdate: false) {}
            XCTAssertNotNil(store.state.caches[key])

            context.unwatch(atom, container: container.wrapper)
            XCTAssertNotNil(store.state.caches[key])
        }

        XCTContext.runActivity(named: "Overridden KeepAlive atoms should be released.") { _ in
            let atom = KeepAliveAtom(value: 0)
            let token = ScopeKey.Token()
            let scopeKey = ScopeKey(token: token)
            let key = AtomKey(atom, overrideScopeKey: scopeKey)
            let context = context.scoped(
                key: scopeKey,
                observers: [],
                overrides: [
                    OverrideKey(atom): AtomOverride<KeepAliveAtom<Int>> { _ in 10 }
                ]
            )
            let container = SubscriptionContainer()

            _ = context.watch(atom, container: container.wrapper, requiresObjectUpdate: false) {}
            XCTAssertNotNil(store.state.caches[key])

            context.unwatch(atom, container: container.wrapper)
            XCTAssertNil(store.state.caches[key])
        }
    }

    func testObservers() {
        let container = SubscriptionContainer()
        let atom0 = TestAtom(value: 0)
        let atom1 = TestAtom(value: 1)
        let atom2 = TestAtom(value: 2)
        let store = AtomStore()
        let scope1Token = ScopeKey.Token()
        let scope2Token = ScopeKey.Token()
        let scope1Key = ScopeKey(token: scope1Token)
        let scope2Key = ScopeKey(token: scope2Token)

        var scopedOverride = [OverrideKey: any AtomOverrideProtocol]()
        scopedOverride[OverrideKey(atom1)] = AtomOverride<TestAtom<Int>> { _ in
            100
        }

        var snapshots = [Snapshot]()
        var scopedSnapshots = [Snapshot]()
        let context = StoreContext(
            store,
            observers: [Observer { snapshots.append($0) }]
        )
        let scoped1Context = context.scoped(
            key: scope1Key,
            observers: [],
            overrides: [:]
        )
        let scoped2Context = scoped1Context.scoped(
            key: scope2Key,
            observers: [Observer { scopedSnapshots.append($0) }],
            overrides: scopedOverride
        )

        // New value

        _ = scoped2Context.watch(atom0, container: container.wrapper, requiresObjectUpdate: false) {}
        _ = scoped2Context.watch(atom1, container: container.wrapper, requiresObjectUpdate: false) {}
        _ = context.watch(atom0, container: container.wrapper, requiresObjectUpdate: false) {}
        _ = context.watch(atom1, container: container.wrapper, requiresObjectUpdate: false) {}
        _ = context.watch(atom2, container: container.wrapper, requiresObjectUpdate: false) {}

        XCTAssertEqual(
            snapshots.map { $0.caches.mapValues { $0 as? AtomCache<TestAtom<Int>> } },
            [
                [
                    AtomKey(atom0): AtomCache(atom: atom0, value: 0)
                ],
                [
                    AtomKey(atom0): AtomCache(atom: atom0, value: 0),
                    AtomKey(atom1, overrideScopeKey: scope2Key): AtomCache(atom: atom1, value: 100),
                ],
                [
                    AtomKey(atom0): AtomCache(atom: atom0, value: 0),
                    AtomKey(atom1, overrideScopeKey: scope2Key): AtomCache(atom: atom1, value: 100),
                    AtomKey(atom1): AtomCache(atom: atom1, value: 1),
                ],
                [
                    AtomKey(atom0): AtomCache(atom: atom0, value: 0),
                    AtomKey(atom1, overrideScopeKey: scope2Key): AtomCache(atom: atom1, value: 100),
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
                    AtomKey(atom1, overrideScopeKey: scope2Key): AtomCache(atom: atom1, value: 100),
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
                    AtomKey(atom1, overrideScopeKey: scope2Key): AtomCache(atom: atom1, value: 100),
                    AtomKey(atom1): AtomCache(atom: atom1, value: 1),
                    AtomKey(atom2): AtomCache(atom: atom2, value: 2),
                ],
                [
                    AtomKey(atom0): AtomCache(atom: atom0, value: 0),
                    AtomKey(atom1, overrideScopeKey: scope2Key): AtomCache(atom: atom1, value: 100),
                    AtomKey(atom1): AtomCache(atom: atom1, value: 1),
                    AtomKey(atom2): AtomCache(atom: atom2, value: 2),
                ],
                [
                    AtomKey(atom0): AtomCache(atom: atom0, value: 0),
                    AtomKey(atom1, overrideScopeKey: scope2Key): AtomCache(atom: atom1, value: 100),
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
                    AtomKey(atom1, overrideScopeKey: scope2Key): AtomCache(atom: atom1, value: 100),
                    AtomKey(atom1): AtomCache(atom: atom1, value: 1),
                    AtomKey(atom2): AtomCache(atom: atom2, value: 2),
                ],
                [
                    AtomKey(atom0): AtomCache(atom: atom0, value: 0),
                    AtomKey(atom1, overrideScopeKey: scope2Key): AtomCache(atom: atom1, value: 100),
                    AtomKey(atom1): AtomCache(atom: atom1, value: 1),
                    AtomKey(atom2): AtomCache(atom: atom2, value: 2),
                ],
            ]
        )

        // Release

        snapshots.removeAll()
        scopedSnapshots.removeAll()
        context.unwatch(atom0, container: container.wrapper)
        scoped2Context.unwatch(atom1, container: container.wrapper)
        context.unwatch(atom2, container: container.wrapper)

        XCTAssertEqual(
            snapshots.map { $0.caches.mapValues { $0 as? AtomCache<TestAtom<Int>> } },
            [
                [
                    AtomKey(atom1, overrideScopeKey: scope2Key): AtomCache(atom: atom1, value: 100),
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

    func testRestore() {
        let store = AtomStore()
        let context = StoreContext(store)
        let atom0 = TestAtom(value: 0)
        let atom1 = TestAtom(value: 1)
        let atom2 = TestAtom(value: 2)
        let location = SourceLocation()
        let token = SubscriptionKey.Token()
        let subscriptionKey = SubscriptionKey(token: token)

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
        let subscription0 = Subscription(location: location, requiresObjectUpdate: false) { updated.insert(AtomKey(atom0)) }
        let subscription1 = Subscription(location: location, requiresObjectUpdate: false) { updated.insert(AtomKey(atom1)) }
        let subscription2 = Subscription(location: location, requiresObjectUpdate: false) { updated.insert(AtomKey(atom2)) }

        store.state.subscriptions = [
            AtomKey(atom0): [subscriptionKey: subscription0],
            AtomKey(atom1): [subscriptionKey: subscription1],
            AtomKey(atom2): [subscriptionKey: subscription2],
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
        let atomStore = StoreContext(store)
        var container: SubscriptionContainer? = SubscriptionContainer()
        let pipe = AsyncThrowingStreamPipe<Void>()
        let atom = TestAtom(pipe: pipe)
        let a = AAtom()
        let b = BAtom()
        let c = CAtom()
        let d = DAtom()
        let phase = PhaseAtom()

        func watch() async -> Int {
            await atomStore.watch(atom, container: container!.wrapper, requiresObjectUpdate: false, notifyUpdate: {}).value
        }

        do {
            // first

            Task {
                await pipe.stream.next()
                pipe.continuation.yield()
            }

            let value = await watch()

            XCTAssertEqual(value, 0)
            XCTAssertNil(store.graph.children[AtomKey(d)])
            XCTAssertEqual(
                store.graph.dependencies[AtomKey(atom)],
                [AtomKey(phase), AtomKey(a), AtomKey(b), AtomKey(c)]
            )

            let state = store.state.states[AtomKey(atom)]

            // Should be 1 (TestAtom's Task cancellation)
            XCTAssertEqual(1, state?.transaction?.terminations.count)
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

            let before = await watch()
            let after = await watch()

            XCTAssertEqual(before, 0)
            XCTAssertEqual(after, 1)
            XCTAssertNil(store.graph.children[AtomKey(c)])
            XCTAssertEqual(
                store.graph.dependencies[AtomKey(atom)],
                [AtomKey(phase), AtomKey(a), AtomKey(d), AtomKey(b)]
            )

            let state = store.state.states[AtomKey(atom)]

            // Should be 1 (TestAtom's Task cancellation)
            XCTAssertEqual(1, state?.transaction?.terminations.count)
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
            let before = await watch()
            let after = await watch()

            XCTAssertEqual(before, 1)
            XCTAssertEqual(after, 3)
            XCTAssertNil(store.graph.children[AtomKey(a)])
            XCTAssertEqual(
                store.graph.dependencies[AtomKey(atom)],
                [AtomKey(phase), AtomKey(b), AtomKey(c), AtomKey(d)]
            )

            let state = store.state.states[AtomKey(atom)]

            // Should be 1 (TestAtom's Task cancellation)
            XCTAssertEqual(1, state?.transaction?.terminations.count)
        }

        do {
            container = nil
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
