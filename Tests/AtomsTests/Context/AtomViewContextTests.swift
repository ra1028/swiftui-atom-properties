import Combine
import XCTest

@testable import Atoms

final class AtomViewContextTests: XCTestCase {
    @MainActor
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

    @MainActor
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

    @MainActor
    func testRefresh() async {
        let atom = TestPublisherAtom { Just(100) }
        let store = AtomStore()
        let container = SubscriptionContainer()
        let context = AtomViewContext(
            store: StoreContext(store),
            container: container.wrapper,
            notifyUpdate: {}
        )

        XCTAssertTrue(context.watch(atom).isSuspending)

        let value = await context.refresh(atom).value

        XCTAssertEqual(value, 100)
        XCTAssertEqual(context.watch(atom).value, 100)
    }

    @MainActor
    func testCustomRefresh() async {
        let atom = TestCustomRefreshableAtom {
            Just(100)
        } refresh: {
            .success(200)
        }
        let store = AtomStore()
        let container = SubscriptionContainer()
        let context = AtomViewContext(
            store: StoreContext(store),
            container: container.wrapper,
            notifyUpdate: {}
        )

        XCTAssertTrue(context.watch(atom).isSuspending)

        let value = await context.refresh(atom).value

        XCTAssertEqual(value, 200)
        XCTAssertEqual(context.watch(atom).value, 200)
    }

    @MainActor
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

    @MainActor
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

    @MainActor
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

    @MainActor
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
