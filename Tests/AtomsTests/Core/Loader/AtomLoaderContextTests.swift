import XCTest

@testable import Atoms

final class AtomLoaderContextTests: XCTestCase {
    @MainActor
    func testUpdate() {
        let atom = TestValueAtom(value: 0)
        let transaction = Transaction(key: AtomKey(atom)) {}
        var updatedValue: Int?

        let context = AtomLoaderContext<Int, Void>(
            store: StoreContext(),
            transaction: transaction,
            coordinator: ()
        ) { value in
            updatedValue = value
        }

        context.update(with: 1)

        XCTAssertEqual(updatedValue, 1)
    }

    @MainActor
    func testAddTermination() {
        let atom = TestValueAtom(value: 0)
        let transaction = Transaction(key: AtomKey(atom)) {}
        let context = AtomLoaderContext<Int, Void>(
            store: StoreContext(),
            transaction: transaction,
            coordinator: ()
        ) { _ in }

        context.addTermination {}
        context.addTermination {}

        XCTAssertEqual(transaction.terminations.count, 2)

        transaction.terminate()
        context.addTermination {}

        XCTAssertTrue(transaction.terminations.isEmpty)
    }

    @MainActor
    func testTransaction() {
        let atom = TestValueAtom(value: 0)
        var isCommitted = false
        let transaction = Transaction(key: AtomKey(atom)) {
            isCommitted = true
        }
        let context = AtomLoaderContext<Int, Void>(
            store: StoreContext(),
            transaction: transaction,
            coordinator: ()
        ) { _ in }

        context.transaction { _ in }

        XCTAssertTrue(isCommitted)
    }

    @MainActor
    func testAsyncTransaction() async {
        let atom = TestValueAtom(value: 0)
        var isCommitted = false
        let transaction = Transaction(key: AtomKey(atom)) {
            isCommitted = true
        }
        let context = AtomLoaderContext<Int, Void>(
            store: StoreContext(),
            transaction: transaction,
            coordinator: ()
        ) { _ in }

        await context.transaction { _ in
            try? await Task.sleep(seconds: 0)
        }

        XCTAssertTrue(isCommitted)
    }
}
