import XCTest

@testable import Atoms

@MainActor
final class StoreContextTests: XCTestCase {
    func testRead() {
        let store = AtomStore()
        let context = StoreContext(store)
        let atom = TestValueAtom(value: 0)
        let key = AtomKey(atom)

        XCTAssertEqual(context.read(atom), 0)
        XCTAssertNil(store.state.caches[AtomKey(atom)])

        store.state.caches[key] = AtomCache(atom: atom, value: 1)

        XCTAssertEqual(context.read(atom), 1)
        XCTAssertNil(store.state.caches[key])
        XCTAssertNil(store.state.states[key])
    }

    func testSet() {
        let store = AtomStore()
        let context = StoreContext(store)
        let subscriptionKey = SubscriptionKey(SubscriptionContainer())
        var updateCount = 0
        let atom = TestStateAtom(defaultValue: 0)
        let key = AtomKey(atom)

        context.set(1, for: atom)

        XCTAssertEqual(updateCount, 0)
        XCTAssertNil(store.state.states[key])
        XCTAssertNil(store.state.caches[key])

        store.state.states[key] = AtomState(coordinator: atom.makeCoordinator())
        store.state.subscriptions[key, default: [:]][subscriptionKey] = Subscription(
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
        let subscriptionKey = SubscriptionKey(container)
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
        XCTAssertNotNil(store.state.subscriptions[key]?[subscriptionKey])
        XCTAssertEqual((store.state.caches[key] as? AtomCache<TestAtom>)?.value, 0)
        XCTAssertEqual((store.state.caches[dependencyKey] as? AtomCache<DependencyAtom>)?.value, 0)

        let subscription = store.state.subscriptions[key]?[subscriptionKey]
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
        let cachedValue = await (store.state.caches[key] as? AtomCache<TestTaskAtom<Int>>)?.value?.value

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
        let subscriptionKey = SubscriptionKey(SubscriptionContainer())
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

        store.graph = graph
        store.state.caches = caches
        store.state.subscriptions[key0, default: [:]][subscriptionKey] = Subscription(notifyUpdate: {}, unsubscribe: {})
        store.state.subscriptions[key1, default: [:]][subscriptionKey] = Subscription(notifyUpdate: {}, unsubscribe: {})

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
        let scopedContext = context.scoped(observers: [observer1])

        _ = scopedContext.watch(atom, container: container.wrapper) {}

        XCTAssertFalse(snapshots0.isEmpty)
        XCTAssertFalse(snapshots1.isEmpty)
    }

    func testCoordinator() {
        struct TestAtom: ValueAtom, Hashable {
            final class Coordinator {}

            func makeCoordinator() -> Coordinator {
                Coordinator()
            }

            func value(context: Context) -> Int {
                0
            }
        }

        let store = AtomStore()
        let container = SubscriptionContainer()
        let context = StoreContext(store)
        let atom = TestAtom()
        let key = AtomKey(atom)

        _ = context.watch(atom, container: container.wrapper) {}

        let state = store.state.states[key] as? AtomState<TestAtom.Coordinator>

        XCTAssertNotNil(state?.coordinator)

        context.reset(atom)

        let newState = store.state.states[key] as? AtomState<TestAtom.Coordinator>

        XCTAssertTrue(state?.coordinator === newState?.coordinator)
    }

    func testObservers() {
        let store = AtomStore()
        let container = SubscriptionContainer()
        var snapshots = [Snapshot]()
        let observer = Observer { snapshots.append($0) }
        let context = StoreContext(store, observers: [observer])
        let atom0 = TestAtom(value: 0)
        let key0 = AtomKey(atom0)

        // New value.

        _ = context.watch(atom0, container: container.wrapper) {}

        XCTAssertEqual(
            snapshots.map { $0.caches.mapValues { $0 as? AtomCache<TestAtom<Int>> } },
            [
                [key0: AtomCache(atom: atom0, value: 0)]
            ]
        )

        // Update.

        context.reset(atom0)

        XCTAssertEqual(
            snapshots.map { $0.caches.mapValues { $0 as? AtomCache<TestAtom<Int>> } },
            [
                [key0: AtomCache(atom: atom0, value: 0)],
                [key0: AtomCache(atom: atom0, value: 0)],
            ]
        )

        // Release.

        for subscription in container.wrapper.subscriptions.values {
            subscription.unsubscribe()
        }

        XCTAssertEqual(
            snapshots.map { $0.caches.mapValues { $0 as? AtomCache<TestAtom<Int>> } },
            [
                [key0: AtomCache(atom: atom0, value: 0)],
                [key0: AtomCache(atom: atom0, value: 0)],
                [:],
            ]
        )

        // Restore with no subscriptions.

        snapshots[1].restore()

        XCTAssertEqual(
            store.state.caches.mapValues { $0 as? AtomCache<TestAtom<Int>> },
            [:]
        )

        // Restore.
        // - state must be removed.
        // - update should notified only for the subscriptions of the restored atom.
        // - dependencies that weren't used in the snapshot must be released.

        let atom1 = TestAtom(value: 1)
        let atom2 = TestAtom(value: 2)
        let key1 = AtomKey(atom1)
        let key2 = AtomKey(atom2)
        var updatedSubscriptions = [AtomKey]()

        _ = context.watch(atom0, container: container.wrapper) { updatedSubscriptions.append(key0) }
        _ = context.watch(atom1, container: container.wrapper) { updatedSubscriptions.append(key1) }
        _ = context.watch(atom2, in: Transaction(key: key0) {})

        XCTAssertTrue(updatedSubscriptions.isEmpty)
        XCTAssertEqual(
            store.graph,
            Graph(
                dependencies: [key0: [key2]],
                children: [key2: [key0]]
            )
        )
        XCTAssertEqual(
            store.state.caches.mapValues { $0 as? AtomCache<TestAtom<Int>> },
            [
                key0: AtomCache(atom: atom0, value: 0),
                key1: AtomCache(atom: atom1, value: 1),
                key2: AtomCache(atom: atom2, value: 2),
            ]
        )

        snapshots[1].restore()

        XCTAssertEqual(updatedSubscriptions, [key0])
        XCTAssertEqual(store.graph, Graph())
        XCTAssertEqual(
            store.state.caches.mapValues { $0 as? AtomCache<TestAtom<Int>> },
            [
                key0: AtomCache(atom: atom0, value: 0),
                key1: AtomCache(atom: atom1, value: 1),
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
