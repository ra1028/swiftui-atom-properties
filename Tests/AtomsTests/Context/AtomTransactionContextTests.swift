import Combine
import XCTest

@testable import Atoms

@MainActor
final class AtomTransactionContextTests: XCTestCase {
    func testRead() {
        let atom = TestValueAtom(value: 100)
        let store = AtomStore()
        let transaction = Transaction(key: AtomKey(atom)) {}
        let context = AtomTransactionContext(store: StoreContext(store), transaction: transaction, coordinator: ())

        XCTAssertEqual(context.read(atom), 100)
    }

    func testSet() {
        let atom = TestValueAtom(value: 0)
        let dependency = TestStateAtom(defaultValue: 100)
        let store = AtomStore()
        let transaction = Transaction(key: AtomKey(atom)) {}
        let context = AtomTransactionContext(store: StoreContext(store), transaction: transaction, coordinator: ())

        XCTAssertEqual(context.watch(dependency), 100)

        context.set(200, for: dependency)

        XCTAssertEqual(context.watch(dependency), 200)
    }

    func testRefresh() async {
        let atom0 = TestValueAtom(value: 0)
        let atom1 = TestPublisherAtom { Just(100) }
        let store = AtomStore()
        let transaction = Transaction(key: AtomKey(atom0)) {}
        let context = AtomTransactionContext(store: StoreContext(store), transaction: transaction, coordinator: ())

        XCTAssertTrue(context.watch(atom1).isSuspending)

        let value = await context.refresh(atom1).value

        XCTAssertEqual(value, 100)
        XCTAssertEqual(context.watch(atom1).value, 100)
    }

    func testCustomRefresh() async {
        let atom0 = TestValueAtom(value: 0)
        let atom1 = TestCustomRefreshableAtom {
            Just(100)
        } refresh: {
            .success(200)
        }
        let store = AtomStore()
        let transaction = Transaction(key: AtomKey(atom0)) {}
        let context = AtomTransactionContext(store: StoreContext(store), transaction: transaction, coordinator: ())

        XCTAssertTrue(context.watch(atom1).isSuspending)

        let value = await context.refresh(atom1).value

        XCTAssertEqual(value, 200)
        XCTAssertEqual(context.watch(atom1).value, 200)
    }

    func testReset() {
        let atom = TestValueAtom(value: 0)
        let dependency = TestStateAtom(defaultValue: 0)
        let store = AtomStore()
        let transaction = Transaction(key: AtomKey(atom)) {}
        let context = AtomTransactionContext(store: StoreContext(store), transaction: transaction, coordinator: ())

        XCTAssertEqual(context.watch(dependency), 0)

        context[dependency] = 100

        XCTAssertEqual(context.watch(dependency), 100)

        context.reset(dependency)

        XCTAssertEqual(context.read(dependency), 0)
    }

    func testWatch() {
        let atom0 = TestValueAtom(value: 100)
        let atom1 = TestStateAtom(defaultValue: 200)
        let store = AtomStore()
        let transaction = Transaction(key: AtomKey(atom0)) {}
        let context = AtomTransactionContext(store: StoreContext(store), transaction: transaction, coordinator: ())

        let value = context.watch(atom1)

        XCTAssertEqual(value, 200)
        XCTAssertEqual(store.graph.children, [AtomKey(atom1): [AtomKey(atom0)]])
        XCTAssertEqual(store.graph.dependencies, [AtomKey(atom0): [AtomKey(atom1)]])
    }
}
