import XCTest

@testable import Atoms

@MainActor
final class AtomTransactionContextTests: XCTestCase {
    func testRead() {
        let atom = TestValueAtom(value: 100)
        let store = Store()
        let transaction = Transaction(key: AtomKey(atom)) {}
        let context = AtomTransactionContext(store: StoreContext(store), transaction: transaction)

        XCTAssertEqual(context.read(atom), 100)
    }

    func testSet() {
        let atom = TestStateAtom(defaultValue: 100)
        let store = Store()
        let transaction = Transaction(key: AtomKey(atom)) {}
        let context = AtomTransactionContext(store: StoreContext(store), transaction: transaction)

        XCTAssertEqual(context.watch(atom), 100)

        context.set(200, for: atom)

        XCTAssertEqual(context.watch(atom), 200)
    }

    func testRefresh() async {
        let atom = TestTaskAtom(value: 100)
        let store = Store()
        let transaction = Transaction(key: AtomKey(atom)) {}
        let context = AtomTransactionContext(store: StoreContext(store), transaction: transaction)

        let value = await context.refresh(atom).value

        XCTAssertEqual(value, 100)
    }

    func testReset() {
        let atom = TestStateAtom(defaultValue: 0)
        let store = Store()
        let transaction = Transaction(key: AtomKey(atom)) {}
        let context = AtomTransactionContext(store: StoreContext(store), transaction: transaction)

        XCTAssertEqual(context.watch(atom), 0)

        context[atom] = 100

        XCTAssertEqual(context.watch(atom), 100)

        context.reset(atom)

        XCTAssertEqual(context.read(atom), 0)
    }

    func testWatch() {
        let atom0 = TestValueAtom(value: 100)
        let atom1 = TestStateAtom(defaultValue: 200)
        let store = Store()
        let transaction = Transaction(key: AtomKey(atom0)) {}
        let context = AtomTransactionContext(store: StoreContext(store), transaction: transaction)

        let value = context.watch(atom1)

        XCTAssertEqual(value, 200)
        XCTAssertEqual(store.graph.children, [AtomKey(atom1): [AtomKey(atom0)]])
        XCTAssertEqual(store.graph.dependencies, [AtomKey(atom0): [AtomKey(atom1)]])
    }

    func testAddTermination() {
        let atom = TestValueAtom(value: 100)
        let store = Store()
        let transaction = Transaction(key: AtomKey(atom)) {}
        let context = AtomTransactionContext(store: StoreContext(store), transaction: transaction)

        context.addTermination {}

        XCTAssertEqual(transaction.terminations.count, 1)

        transaction.terminate()
        context.addTermination {}

        XCTAssertEqual(transaction.terminations.count, 0)
    }

    func testKeepUntilTermination() {
        let atom = TestValueAtom(value: 100)
        let store = Store()
        let transaction = Transaction(key: AtomKey(atom)) {}
        let context = AtomTransactionContext(store: StoreContext(store), transaction: transaction)
        var object: Object? = Object()
        weak var objectRef = object

        context.keepUntilTermination(object!)

        XCTAssertNotNil(objectRef)

        object = nil
        XCTAssertNotNil(objectRef)

        transaction.terminate()
        XCTAssertNil(objectRef)
    }
}
