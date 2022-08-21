import XCTest

@testable import Atoms

@MainActor
final class StoreContextTests: XCTestCase {
    func testRead() {
        let store = Store()
        let observer = TestObserver()
        let context = StoreContext(store, observers: [observer])
        let atom = TestValueAtom(value: 0)

        XCTAssertEqual(context.read(atom), 0)
        XCTAssertNil(store.state.atomStates[AtomKey(atom)])
        XCTAssertTrue(observer.assignedAtomKeys.isEmpty)
        XCTAssertEqual(observer.changedAtomKeys, [AtomKey(atom)])
        XCTAssertTrue(observer.unassignedAtomKeys.isEmpty)

        store.state.atomStates[AtomKey(atom)] = ConcreteAtomState(atom: atom, value: 1)

        XCTAssertEqual(context.read(atom), 1)
    }

    func testSet() {
        struct Values<T: Equatable>: Equatable {
            let old: T
            let new: T
        }

        let store = Store()
        let observer = TestObserver()
        let context = StoreContext(store, observers: [observer])
        let subscriptionKey = SubscriptionKey(SubscriptionContainer())
        var updateCount = 0
        var calledWillSet = [Values<Int>]()
        var calledDidSet = [Values<Int>]()
        let atom = TestStateAtom(
            defaultValue: 0,
            willSet: { calledWillSet.append(Values(old: $1, new: $0)) },
            didSet: { calledDidSet.append(Values(old: $1, new: $0)) }
        )
        let key = AtomKey(atom)

        store.state.subscriptions[key, default: [:]][subscriptionKey] = Subscription(
            notifyUpdate: { updateCount += 1 },
            unsubscribe: {}
        )
        context.set(1, for: atom)

        XCTAssertEqual(updateCount, 0)
        XCTAssertTrue(calledWillSet.isEmpty)
        XCTAssertTrue(calledDidSet.isEmpty)
        XCTAssertTrue(observer.assignedAtomKeys.isEmpty)
        XCTAssertTrue(observer.changedAtomKeys.isEmpty)
        XCTAssertTrue(observer.unassignedAtomKeys.isEmpty)
        XCTAssertNil(store.state.transactions[key])
        XCTAssertNil(store.state.atomStates[key])

        store.state.atomStates[key] = ConcreteAtomState(atom: atom, value: 1)
        context.set(2, for: atom)

        XCTAssertEqual(updateCount, 1)
        XCTAssertEqual(calledWillSet, [Values(old: 1, new: 2)])
        XCTAssertEqual(calledDidSet, [Values(old: 1, new: 2)])
        XCTAssertTrue(observer.assignedAtomKeys.isEmpty)
        XCTAssertEqual(observer.changedAtomKeys, [AtomKey(atom)])
        XCTAssertTrue(observer.unassignedAtomKeys.isEmpty)
        XCTAssertNil(store.state.transactions[key])
        XCTAssertEqual((store.state.atomStates[key] as? ConcreteAtomState<TestStateAtom<Int>>)?.value, 2)
    }

    func testWatch() {
        let store = Store()
        let observer = TestObserver()
        let context = StoreContext(store, observers: [observer])
        let atom = TestValueAtom(value: 0)
        let dependency0 = TestStateAtom(defaultValue: 0)
        let dependency1 = TestValueAtom(value: 1)
        let key = AtomKey(atom)
        let dependency0Key = AtomKey(dependency0)
        let dependency1Key = AtomKey(dependency1)
        let transaction = Transaction(key: key) {}

        XCTAssertEqual(context.watch(dependency0, in: transaction), 0)
        XCTAssertEqual(store.graph.dependencies, [key: [dependency0Key]])
        XCTAssertEqual(store.graph.children, [dependency0Key: [key]])
        XCTAssertEqual((store.state.atomStates[dependency0Key] as? ConcreteAtomState<TestStateAtom<Int>>)?.value, 0)
        XCTAssertEqual(observer.assignedAtomKeys, [dependency0Key])
        XCTAssertEqual(observer.changedAtomKeys, [dependency0Key])
        XCTAssertTrue(observer.unassignedAtomKeys.isEmpty)

        transaction.terminate()

        XCTAssertEqual(context.watch(dependency1, in: transaction), 1)
        XCTAssertEqual(store.graph.dependencies, [key: [dependency0Key]])
        XCTAssertEqual(store.graph.children, [dependency0Key: [key]])
        XCTAssertNil(store.state.atomStates[dependency1Key])
        XCTAssertEqual(observer.assignedAtomKeys, [dependency0Key])
        XCTAssertEqual(observer.changedAtomKeys, [dependency0Key])
        XCTAssertTrue(observer.unassignedAtomKeys.isEmpty)
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

        let store = Store()
        let observer = TestObserver()
        let context = StoreContext(store, observers: [observer])
        let container = SubscriptionContainer()
        let subscriptionKey = SubscriptionKey(container)
        let atom = TestAtom()
        let dependency = DependencyAtom()
        let key = AtomKey(atom)
        let dependencyKey = AtomKey(dependency)
        var updateCount = 0
        let initialValue = context.watch(atom, container: container) {
            updateCount += 1
        }

        XCTAssertEqual(initialValue, 0)
        XCTAssertNotNil(container.subscriptions[key])
        XCTAssertNotNil(store.state.subscriptions[key]?[subscriptionKey])
        XCTAssertEqual((store.state.atomStates[key] as? ConcreteAtomState<TestAtom>)?.value, 0)
        XCTAssertEqual((store.state.atomStates[dependencyKey] as? ConcreteAtomState<DependencyAtom>)?.value, 0)
        XCTAssertEqual(observer.assignedAtomKeys, [key, dependencyKey])
        XCTAssertEqual(observer.changedAtomKeys, [dependencyKey, key])
        XCTAssertTrue(observer.unassignedAtomKeys.isEmpty)

        let subscription = store.state.subscriptions[key]?[subscriptionKey]
        subscription?.notifyUpdate()
        subscription?.unsubscribe()

        XCTAssertEqual(updateCount, 1)
        XCTAssertNil(store.state.subscriptions[key]?[subscriptionKey])
        XCTAssertNil(store.state.atomStates[key])
        XCTAssertNil(store.state.atomStates[dependencyKey])
        XCTAssertEqual(observer.assignedAtomKeys, [key, dependencyKey])
        XCTAssertEqual(observer.changedAtomKeys, [dependencyKey, key])
        XCTAssertEqual(observer.unassignedAtomKeys, [key, dependencyKey])
    }

    func testRefresh() async {
        let store = Store()
        let observer = TestObserver()
        let context = StoreContext(store, observers: [observer])
        let container = SubscriptionContainer()
        let atom = TestTaskAtom(value: 0)
        let key = AtomKey(atom)
        let value0 = await context.refresh(atom).value

        XCTAssertEqual(value0, 0)
        XCTAssertNil(store.state.atomStates[key])
        XCTAssertTrue(observer.assignedAtomKeys.isEmpty)
        XCTAssertEqual(observer.changedAtomKeys, [key])
        XCTAssertTrue(observer.unassignedAtomKeys.isEmpty)

        var updateCount = 0

        _ = context.watch(atom, container: container) {
            updateCount += 1
        }

        let value1 = await context.refresh(atom).value
        let cachedValue = await (store.state.atomStates[key] as? ConcreteAtomState<TestTaskAtom<Int>>)?.value?.value

        XCTAssertEqual(value1, 0)
        XCTAssertEqual(cachedValue, 0)
        XCTAssertEqual(updateCount, 1)
    }

    func testReset() {
        let store = Store()
        let observer = TestObserver()
        let context = StoreContext(store, observers: [observer])
        let container = SubscriptionContainer()
        let atom = TestStateAtom(defaultValue: 0)
        let key = AtomKey(atom)
        var updateCount = 0
        let initialValue = context.watch(atom, container: container) {
            updateCount += 1
        }

        XCTAssertEqual(initialValue, 0)

        context.set(1, for: atom)

        XCTAssertEqual(updateCount, 1)
        XCTAssertEqual(context.read(atom), 1)
        XCTAssertEqual(observer.assignedAtomKeys, [key])
        XCTAssertEqual(observer.changedAtomKeys, [key, key])
        XCTAssertTrue(observer.unassignedAtomKeys.isEmpty)

        context.reset(atom)

        XCTAssertEqual(updateCount, 2)
        XCTAssertEqual(context.read(atom), 0)
        XCTAssertEqual(observer.assignedAtomKeys, [key])
        XCTAssertEqual(observer.changedAtomKeys, [key, key, key])
        XCTAssertTrue(observer.unassignedAtomKeys.isEmpty)
    }

    func testRelay() {
        let store = Store()
        let container = SubscriptionContainer()
        let atom = TestValueAtom(value: 0)
        let observer0 = TestObserver()
        let observer1 = TestObserver()
        let context = StoreContext(store, observers: [observer0])
        let relayedContext = context.relay(observers: [observer1])

        _ = relayedContext.watch(atom, container: container) {}

        XCTAssertFalse(observer0.assignedAtomKeys.isEmpty)
        XCTAssertFalse(observer1.assignedAtomKeys.isEmpty)
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

                    context.addTermination {}

                    pipe.continuation.yield()
                    await pipe.stream.next()

                    return a + b + c

                case .second:
                    let a = context.watch(AAtom())
                    let d = context.watch(DAtom())

                    pipe.continuation.yield()
                    await pipe.stream.next()

                    context.addTermination {}

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

        let store = Store()
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
            await atomStore.watch(atom, container: container, notifyUpdate: {}).value
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

            // Should be 1 (TestAtom's Task cancellation + first phase)
            XCTAssertEqual(
                2,
                store.state.transactions[AtomKey(atom)]?.terminations.count
            )
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

            // Should be 1 (TestAtom's Task cancellation + second phase)
            XCTAssertEqual(
                2,
                store.state.transactions[AtomKey(atom)]?.terminations.count
            )
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

            // Should be 1 (TestAtom's Task cancellation)
            XCTAssertEqual(
                1,
                store.state.transactions[AtomKey(atom)]?.terminations.count
            )
        }
    }
}

private extension AsyncSequence {
    func next() async -> Element? {
        var iterator = makeAsyncIterator()
        return try? await iterator.next()
    }
}
