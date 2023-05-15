import Combine
import XCTest

@testable import Atoms

@MainActor
final class StoreContextTests: XCTestCase {
    func testStoreDeinit() {
        let atom = TestAtom(value: 0)
        let container = SubscriptionContainer()
        var store: AtomStore? = AtomStore()
        weak var storeRef = store
        let context = StoreContext(store!)

        XCTAssertEqual(context.watch(atom, container: container.wrapper) {}, 0)
        XCTAssertNotNil(storeRef)
        store = nil
        XCTAssertNil(storeRef)
    }

    func testRead() {
        let store = AtomStore()
        let context = StoreContext(store)
        let atom = TestValueAtom(value: 0)
        let key = AtomKey(atom)

        XCTAssertEqual(context.read(atom), 0)
        XCTAssertNil(store.state.caches[AtomKey(atom)])

        store.state.caches[key] = AtomCache(atom: atom, value: 1)
        XCTAssertEqual(context.read(atom), 1)
    }

    func testSet() {
        let store = AtomStore()
        let context = StoreContext(store)
        let token = SubscriptionKey.Token()
        let subscriptionKey = SubscriptionKey(token: token)
        var updateCount = 0
        let atom = TestStateAtom(defaultValue: 0)
        let key = AtomKey(atom)

        context.set(1, for: atom)

        XCTAssertEqual(updateCount, 0)
        XCTAssertNil(store.state.states[key])
        XCTAssertNil(store.state.caches[key])

        store.state.caches[key] = AtomCache(atom: atom, value: 0)
        store.state.states[key] = AtomState(coordinator: atom.makeCoordinator())
        store.state.subscriptions[key, default: [:]][subscriptionKey] = Subscription(
            location: SourceLocation(fileID: #file, line: #line),
            notifyUpdate: { updateCount += 1 },
            unsubscribe: {}
        )

        context.set(2, for: atom)

        XCTAssertEqual(updateCount, 1)
        XCTAssertNil(store.state.states[key]?.transaction)
        XCTAssertEqual((store.state.caches[key] as? AtomCache<TestStateAtom<Int>>)?.value, 2)

        context.set(3, for: atom)

        XCTAssertEqual(updateCount, 2)
        XCTAssertNotNil(store.state.states[key])
        XCTAssertNil(store.state.states[key]?.transaction)
        XCTAssertEqual((store.state.caches[key] as? AtomCache<TestStateAtom<Int>>)?.value, 3)
    }

    func testModify() {
        let store = AtomStore()
        let context = StoreContext(store)
        let token = SubscriptionKey.Token()
        let subscriptionKey = SubscriptionKey(token: token)
        var updateCount = 0
        let atom = TestStateAtom(defaultValue: 0)
        let key = AtomKey(atom)

        context.set(1, for: atom)
        context.modify(atom) { $0 = 1 }

        XCTAssertEqual(updateCount, 0)
        XCTAssertNil(store.state.states[key])
        XCTAssertNil(store.state.caches[key])

        store.state.caches[key] = AtomCache(atom: atom, value: 0)
        store.state.states[key] = AtomState(coordinator: atom.makeCoordinator())
        store.state.subscriptions[key, default: [:]][subscriptionKey] = Subscription(
            location: SourceLocation(fileID: #file, line: #line),
            notifyUpdate: { updateCount += 1 },
            unsubscribe: {}
        )

        context.modify(atom) { $0 = 2 }

        XCTAssertEqual(updateCount, 1)
        XCTAssertNil(store.state.states[key]?.transaction)
        XCTAssertEqual((store.state.caches[key] as? AtomCache<TestStateAtom<Int>>)?.value, 2)

        context.modify(atom) { $0 = 3 }

        XCTAssertEqual(updateCount, 2)
        XCTAssertNotNil(store.state.states[key])
        XCTAssertNil(store.state.states[key]?.transaction)
        XCTAssertEqual((store.state.caches[key] as? AtomCache<TestStateAtom<Int>>)?.value, 3)
    }

    func testWatch() {
        let store = AtomStore()
        let context = StoreContext(store)
        let atom = TestAtom(value: 0)
        let dependency0 = TestStateAtom(defaultValue: 0)
        let dependency1 = TestAtom(value: 1)
        let key = AtomKey(atom)
        let dependency0Key = AtomKey(dependency0)
        let dependency1Key = AtomKey(dependency1)
        let transaction = Transaction(key: key) {}

        XCTAssertEqual(context.watch(dependency0, in: transaction), 0)
        XCTAssertEqual(store.graph.dependencies, [key: [dependency0Key]])
        XCTAssertEqual(store.graph.children, [dependency0Key: [key]])
        XCTAssertEqual((store.state.caches[dependency0Key] as? AtomCache<TestStateAtom<Int>>)?.value, 0)
        XCTAssertNotNil(store.state.states[dependency0Key])

        transaction.terminate()

        XCTAssertEqual(context.watch(dependency1, in: transaction), 1)
        XCTAssertEqual(store.graph.dependencies, [key: [dependency0Key]])
        XCTAssertEqual(store.graph.children, [dependency0Key: [key]])
        XCTAssertNil(store.state.caches[dependency1Key])
        XCTAssertNil(store.state.states[dependency1Key])
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
        let context = StoreContext(store)
        let container = SubscriptionContainer()
        let atom = TestAtom()
        let dependency = DependencyAtom()
        let key = AtomKey(atom)
        let dependencyKey = AtomKey(dependency)
        var updateCount = 0
        let initialValue = context.watch(atom, container: container.wrapper) {
            updateCount += 1
        }

        XCTAssertEqual(initialValue, 0)
        XCTAssertNotNil(container.wrapper.subscriptions[key])
        XCTAssertNotNil(store.state.subscriptions[key]?[container.wrapper.key])
        XCTAssertEqual((store.state.caches[key] as? AtomCache<TestAtom>)?.value, 0)
        XCTAssertEqual((store.state.caches[dependencyKey] as? AtomCache<DependencyAtom>)?.value, 0)

        let subscription = store.state.subscriptions[key]?[container.wrapper.key]
        subscription?.notifyUpdate()
        subscription?.unsubscribe()

        XCTAssertEqual(updateCount, 1)
        XCTAssertNil(store.state.caches[key])
        XCTAssertNil(store.state.states[key])
        XCTAssertNil(store.state.caches[dependencyKey])
        XCTAssertNil(store.state.states[dependencyKey])
    }

    func testRefresh() async {
        let store = AtomStore()
        let context = StoreContext(store)
        let container = SubscriptionContainer()
        let atom = TestTaskAtom(value: 0)
        let key = AtomKey(atom)
        let value0 = await context.refresh(atom).value

        XCTAssertEqual(value0, 0)
        XCTAssertNil(store.state.caches[key])
        XCTAssertNil(store.state.states[key])

        var updateCount = 0

        _ = context.watch(atom, container: container.wrapper) {
            updateCount += 1
        }

        let value1 = await context.refresh(atom).value
        let cachedValue = await (store.state.caches[key] as? AtomCache<TestTaskAtom<Int>>)?.value.value

        XCTAssertEqual(value1, 0)
        XCTAssertNotNil(store.state.caches[key])
        XCTAssertNotNil(store.state.states[key])
        XCTAssertEqual(cachedValue, 0)
        XCTAssertEqual(updateCount, 1)
    }

    func testReset() {
        let store = AtomStore()
        let context = StoreContext(store)
        let container = SubscriptionContainer()
        let atom = TestStateAtom(defaultValue: 0)
        var updateCount = 0
        let initialValue = context.watch(atom, container: container.wrapper) {
            updateCount += 1
        }

        XCTAssertEqual(initialValue, 0)

        context.set(1, for: atom)

        XCTAssertEqual(updateCount, 1)
        XCTAssertEqual(context.read(atom), 1)

        context.reset(atom)

        XCTAssertEqual(updateCount, 2)
        XCTAssertEqual(context.read(atom), 0)
    }

    func testSnapshot() {
        let store = AtomStore()
        let token = SubscriptionKey.Token()
        let subscriptionKey = SubscriptionKey(token: token)
        let context = StoreContext(store)
        let atom0 = TestAtom(value: 0)
        let atom1 = TestAtom(value: 1)
        let atom2 = TestAtom(value: 2)
        let atom3 = TestAtom(value: 3)
        let key0 = AtomKey(atom0)
        let key1 = AtomKey(atom1)
        let key2 = AtomKey(atom2)
        let key3 = AtomKey(atom3)
        let graph = Graph(
            dependencies: [key0: [key1]],
            children: [key1: [key0]]
        )
        let caches = [
            key0: AtomCache(atom: atom0, value: 0),
            key1: AtomCache(atom: atom1, value: 1),
        ]
        let subscription = Subscription(location: SourceLocation(fileID: #file, line: #line), notifyUpdate: {}) {}

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

        // Modify graph and caches to a form that atom2 & atom3 should be released.
        store.graph = Graph(
            dependencies: [key0: [key1, key2], key2: [key3]],
            children: [key1: [key0], key2: [key0], key3: [key2]]
        )
        store.state.caches = [
            key0: AtomCache(atom: atom0, value: 0),
            key1: AtomCache(atom: atom1, value: 1),
            key2: AtomCache(atom: atom2, value: 2),
            key3: AtomCache(atom: atom3, value: 3),
        ]

        snapshot.restore()

        XCTAssertEqual(store.graph, snapshot.graph)
        XCTAssertEqual(
            store.state.caches.mapValues { $0 as? AtomCache<TestAtom<Int>> },
            snapshot.caches.mapValues { $0 as? AtomCache<TestAtom<Int>> }
        )

        // Remove all subscriptions so all atoms should be released.
        store.state.subscriptions = [:]

        snapshot.restore()

        XCTAssertEqual(store.graph, Graph())
        XCTAssertTrue(store.state.caches.isEmpty)
    }

    func testScoped() {
        let store = AtomStore()
        let container = SubscriptionContainer()
        let atom = TestValueAtom(value: 0)
        var snapshots0 = [Snapshot]()
        var snapshots1 = [Snapshot]()
        let observer0 = Observer { snapshots0.append($0) }
        let observer1 = Observer { snapshots1.append($0) }
        let context = StoreContext(store, observers: [observer0])
        let scopedContext = context.scoped(
            store: store,
            overrides: Overrides(),
            observers: [observer1]
        )

        _ = scopedContext.watch(atom, container: container.wrapper) {}

        XCTAssertFalse(snapshots0.isEmpty)
        XCTAssertFalse(snapshots1.isEmpty)
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
        let scoped1Store = AtomStore()
        let scoped2Store = AtomStore()

        var scoped1Overrides = Overrides()
        scoped1Overrides.insert(dependency1Atom) { _ in
            10
        }

        var scoped2Overrides = Overrides()
        scoped2Overrides.insert(dependency2Atom) { _ in
            100
        }

        let context = StoreContext(store)
        let scoped1Context = context.scoped(
            store: scoped1Store,
            overrides: scoped1Overrides,
            observers: []
        )
        let scoped2Context = scoped1Context.scoped(
            store: scoped2Store,
            overrides: scoped2Overrides,
            observers: []
        )

        XCTAssertEqual(context.watch(dependency1Atom, container: container.wrapper) {}, 0)

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

        container.wrapper.subscriptions[AtomKey(dependency1Atom)]?.unsubscribe()

        XCTAssertEqual(scoped2Context.watch(atom, container: container.wrapper) {}, 110)
        XCTAssertEqual(scoped2Context.watch(atom, in: transaction), 110)
        XCTAssertEqual(scoped2Context.watch(publisherAtom, container: container.wrapper) {}, .suspending)

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
                    AtomKey(transactionAtom): [AtomKey(atom)]
                ],
                children: [
                    AtomKey(atom): [AtomKey(transactionAtom)]
                ]
            )
        )
        XCTAssertEqual(
            scoped1Store.graph,
            Graph(
                dependencies: [
                    AtomKey(atom): [AtomKey(dependency1Atom)],
                    AtomKey(publisherAtom): [AtomKey(dependency1Atom)],
                ],
                children: [
                    AtomKey(dependency1Atom): [AtomKey(atom), AtomKey(publisherAtom)]
                ]
            )
        )
        XCTAssertEqual(
            scoped2Store.graph,
            Graph(
                dependencies: [
                    AtomKey(atom): [AtomKey(dependency2Atom)],
                    AtomKey(publisherAtom): [AtomKey(dependency2Atom)],
                ],
                children: [
                    AtomKey(dependency2Atom): [AtomKey(atom), AtomKey(publisherAtom)]
                ]
            )
        )
        XCTAssertEqual(
            store.state.caches.mapValues { $0 as? AtomCache<TestAtom> },
            [
                AtomKey(publisherAtom): nil,
                AtomKey(atom): AtomCache(atom: atom, value: 110),
            ]
        )
        XCTAssertEqual(
            store.state.caches.mapValues { $0 as? AtomCache<TestPublisherAtom> },
            [
                AtomKey(publisherAtom): AtomCache(atom: publisherAtom, value: .success(110)),
                AtomKey(atom): nil,
            ]
        )
        XCTAssertEqual(
            scoped1Store.state.caches.mapValues { $0 as? AtomCache<TestDependency1Atom> },
            [
                AtomKey(dependency1Atom): AtomCache(atom: dependency1Atom, value: 10)
            ]
        )
        XCTAssertEqual(
            scoped2Store.state.caches.mapValues { $0 as? AtomCache<TestDependency2Atom> },
            [
                AtomKey(dependency2Atom): AtomCache(atom: dependency2Atom, value: 100)
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

        _ = context.watch(atom, container: container.wrapper) {}

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
            let transaction = Transaction(key: key) {}

            _ = context.watch(atom, in: transaction)
            XCTAssertNotNil(store.state.caches[key])

            context.reset(atom)
            XCTAssertNil(store.state.caches[key])
        }

        XCTContext.runActivity(named: "KeepAlive atoms should not be released.") { _ in
            let atom = KeepAliveAtom(value: 0)
            let key = AtomKey(atom)
            let transaction = Transaction(key: key) {}

            _ = context.watch(atom, in: transaction)

            XCTAssertNotNil(store.state.caches[key])

            context.reset(atom)
            XCTAssertNotNil(store.state.caches[key])
        }
    }

    func testObservers() {
        let container = SubscriptionContainer()
        let atom0 = TestAtom(value: 0)
        let atom1 = TestAtom(value: 1)
        let atom2 = TestAtom(value: 2)
        let store = AtomStore()
        let scoped1Store = AtomStore()
        let scoped2Store = AtomStore()

        var scopedOverride = Overrides()
        scopedOverride.insert(atom1) { _ in
            100
        }

        var snapshots = [Snapshot]()
        var scopedSnapshots = [Snapshot]()
        let context = StoreContext(
            store,
            observers: [Observer { snapshots.append($0) }]
        )
        let scoped1Context = context.scoped(
            store: scoped1Store,
            overrides: Overrides(),
            observers: []
        )
        let scoped2Context = scoped1Context.scoped(
            store: scoped2Store,
            overrides: scopedOverride,
            observers: [Observer { scopedSnapshots.append($0) }]
        )

        // New value.

        _ = scoped2Context.watch(atom0, container: container.wrapper) {}
        _ = scoped2Context.watch(atom1, container: container.wrapper) {}
        _ = context.watch(atom2, container: container.wrapper) {}

        XCTAssertEqual(
            snapshots.map { $0.caches.mapValues { $0 as? AtomCache<TestAtom<Int>> } },
            [
                [AtomKey(atom0): AtomCache(atom: atom0, value: 0)],
                [AtomKey(atom1): AtomCache(atom: atom1, value: 100)],
                [
                    AtomKey(atom0): AtomCache(atom: atom0, value: 0),
                    AtomKey(atom2): AtomCache(atom: atom2, value: 2),
                ],
            ]
        )
        XCTAssertEqual(
            scopedSnapshots.map { $0.caches.mapValues { $0 as? AtomCache<TestAtom<Int>> } },
            [
                [AtomKey(atom0): AtomCache(atom: atom0, value: 0)],
                [AtomKey(atom1): AtomCache(atom: atom1, value: 100)],
            ]
        )

        // Update.

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
                    AtomKey(atom2): AtomCache(atom: atom2, value: 2),
                ],
                [
                    AtomKey(atom1): AtomCache(atom: atom1, value: 100)
                ],
                [
                    AtomKey(atom0): AtomCache(atom: atom0, value: 0),
                    AtomKey(atom2): AtomCache(atom: atom2, value: 2),
                ],
            ]
        )
        XCTAssertEqual(
            scopedSnapshots.map { $0.caches.mapValues { $0 as? AtomCache<TestAtom<Int>> } },
            [
                [
                    AtomKey(atom0): AtomCache(atom: atom0, value: 0),
                    AtomKey(atom2): AtomCache(atom: atom2, value: 2),
                ],
                [
                    AtomKey(atom1): AtomCache(atom: atom1, value: 100)
                ],
            ]
        )

        // Unsubscribe and release.

        snapshots.removeAll()
        scopedSnapshots.removeAll()
        container.wrapper.subscriptions[AtomKey(atom0)]?.unsubscribe()
        container.wrapper.subscriptions[AtomKey(atom1)]?.unsubscribe()
        container.wrapper.subscriptions[AtomKey(atom2)]?.unsubscribe()

        XCTAssertEqual(
            snapshots.map { $0.caches.mapValues { $0 as? AtomCache<TestAtom<Int>> } },
            [
                [
                    AtomKey(atom0): AtomCache(atom: atom0, value: 0),
                    AtomKey(atom2): AtomCache(atom: atom2, value: 2),
                ],
                [
                    AtomKey(atom2): AtomCache(atom: atom2, value: 2)
                ],
                [
                    AtomKey(atom1): AtomCache(atom: atom1, value: 100)
                ],
                [:],
                [
                    AtomKey(atom2): AtomCache(atom: atom2, value: 2)
                ],
                [:],
            ]
        )
        XCTAssertEqual(
            scopedSnapshots.map { $0.caches.mapValues { $0 as? AtomCache<TestAtom<Int>> } },
            [
                [
                    AtomKey(atom0): AtomCache(atom: atom0, value: 0),
                    AtomKey(atom2): AtomCache(atom: atom2, value: 2),
                ],
                [
                    AtomKey(atom2): AtomCache(atom: atom2, value: 2)
                ],
                [
                    AtomKey(atom1): AtomCache(atom: atom1, value: 100)
                ],
                [:],
            ]
        )
    }

    func testRestore() {
        let store = AtomStore()
        let context = StoreContext(store)
        let atom0 = TestAtom(value: 0)
        let atom1 = TestAtom(value: 1)
        let atom2 = TestAtom(value: 2)
        let location = SourceLocation(fileID: #file, line: #line)
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
        let subscription0 = Subscription(location: location, notifyUpdate: { updated.insert(AtomKey(atom0)) }) {}
        let subscription1 = Subscription(location: location, notifyUpdate: { updated.insert(AtomKey(atom1)) }) {}
        let subscription2 = Subscription(location: location, notifyUpdate: { updated.insert(AtomKey(atom2)) }) {}

        store.state.subscriptions = [
            AtomKey(atom0): [subscriptionKey: subscription0],
            AtomKey(atom1): [subscriptionKey: subscription1],
            AtomKey(atom2): [subscriptionKey: subscription2],
        ]

        snapshot.restore()

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
        snapshot.restore()

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
        let container = SubscriptionContainer()
        let pipe = AsyncThrowingStreamPipe<Void>()
        let atom = TestAtom(pipe: pipe)
        let a = AAtom()
        let b = BAtom()
        let c = CAtom()
        let d = DAtom()
        let phase = PhaseAtom()

        func watch() async -> Int {
            await atomStore.watch(atom, container: container.wrapper, notifyUpdate: {}).value
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
            for subscription in container.wrapper.subscriptions.values {
                subscription.unsubscribe()
            }

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
