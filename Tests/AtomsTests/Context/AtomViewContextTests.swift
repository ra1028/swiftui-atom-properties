import XCTest

@testable import Atoms

@MainActor
final class AtomViewContextTests: XCTestCase {
    func testRead() {
        let atom = TestValueAtom(value: 100)
        let store = AtomStore()
        let container = SubscriptionContainer()
        let context = AtomViewContext(
            store: StoreContext(store),
            container: container.wrapper,
            notifyUpdate: {}
        )

        XCTAssertEqual(context.read(atom), 100)
    }

    func testSet() {
        let atom = TestStateAtom(defaultValue: 100)
        let store = AtomStore()
        let container = SubscriptionContainer()
        let context = AtomViewContext(
            store: StoreContext(store),
            container: container.wrapper,
            notifyUpdate: {}
        )

        XCTAssertEqual(context.watch(atom), 100)

        context.set(200, for: atom)

        XCTAssertEqual(context.watch(atom), 200)
    }

    func testRefresh() async {
        let atom = TestTaskAtom(value: 100)
        let store = AtomStore()
        let container = SubscriptionContainer()
        let context = AtomViewContext(
            store: StoreContext(store),
            container: container.wrapper,
            notifyUpdate: {}
        )

        context.watch(atom)

        let value = await context.refresh(atom).value

        XCTAssertEqual(value, 100)
    }

    func testReset() {
        let atom = TestStateAtom(defaultValue: 0)
        let store = AtomStore()
        let container = SubscriptionContainer()
        let context = AtomViewContext(
            store: StoreContext(store),
            container: container.wrapper,
            notifyUpdate: {}
        )

        XCTAssertEqual(context.watch(atom), 0)

        context[atom] = 100

        XCTAssertEqual(context.watch(atom), 100)

        context.reset(atom)

        XCTAssertEqual(context.read(atom), 0)
    }

    func testWatch() {
        let atom = TestStateAtom(defaultValue: 100)
        let store = AtomStore()
        let container = SubscriptionContainer()
        let context = AtomViewContext(
            store: StoreContext(store),
            container: container.wrapper,
            notifyUpdate: {}
        )

        XCTAssertEqual(context.watch(atom), 100)

        context[atom] = 200

        XCTAssertEqual(context.watch(atom), 200)
    }

    func testSnapshot() {
        let store = AtomStore()
        let container = SubscriptionContainer()
        let context = AtomViewContext(
            store: StoreContext(store),
            container: container.wrapper,
            notifyUpdate: {}
        )
        let atom0 = TestAtom(value: 0)
        let atom1 = TestAtom(value: 1)
        let atom2 = TestAtom(value: 2)
        let key0 = AtomKey(atom0)
        let key1 = AtomKey(atom1)
        let key2 = AtomKey(atom2)

        let graph = Graph(
            dependencies: [key0: [key1, key2]],
            children: [key1: [key0], key2: [key0]]
        )
        let caches = [
            key0: AtomCache(atom: atom0, value: 0),
            key1: AtomCache(atom: atom1, value: 1),
            key2: AtomCache(atom: atom2, value: 2),
        ]

        store.graph = graph
        store.state.caches = caches

        let snapshot = context.snapshot()

        XCTAssertEqual(snapshot.graph, graph)
        XCTAssertEqual(
            snapshot.caches.mapValues { $0 as? AtomCache<TestAtom<Int>> },
            caches
        )
    }

    func testUnsubscription() {
        let atom = TestValueAtom(value: 100)
        let key = AtomKey(atom)
        let store = AtomStore()
        var container: SubscriptionContainer? = SubscriptionContainer()
        let context = AtomViewContext(
            store: StoreContext(store),
            container: container!.wrapper,
            notifyUpdate: {}
        )

        context.watch(atom)
        XCTAssertNotNil(store.state.caches[key])

        container = nil
        XCTAssertNil(store.state.caches[key])
    }
}
