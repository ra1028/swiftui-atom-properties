import XCTest

@testable import Atoms

final class AtomProducerContextTests: XCTestCase {
    @MainActor
    func testUpdate() {
        let atom = TestValueAtom(value: 0)
        let transaction = Transaction(key: AtomKey(atom))
        var updatedValue: Int?

        let context = AtomProducerContext<Int, Void>(
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
    func testOnTermination() {
        let atom = TestValueAtom(value: 0)
        let transaction = Transaction(key: AtomKey(atom))
        let context = AtomProducerContext<Int, Void>(
            store: StoreContext(),
            transaction: transaction,
            coordinator: ()
        ) { _ in }

        context.onTermination = {}
        XCTAssertNotNil(context.onTermination)

        transaction.terminate()
        XCTAssertNil(context.onTermination)

        context.onTermination = {}
        XCTAssertNil(context.onTermination)
    }

    @MainActor
    func testTransaction() {
        let atom = TestValueAtom(value: 0)
        var didBegin = false
        var didCommit = false
        let transaction = Transaction(key: AtomKey(atom)) {
            didBegin = true
            return { didCommit = true }
        }
        let context = AtomProducerContext<Int, Void>(
            store: StoreContext(),
            transaction: transaction,
            coordinator: ()
        ) { _ in }

        context.transaction { _ in }

        XCTAssertTrue(didBegin)
        XCTAssertTrue(didCommit)
    }

    @MainActor
    func testAsyncTransaction() async {
        let atom = TestValueAtom(value: 0)
        var didBegin = false
        var didCommit = false
        let transaction = Transaction(key: AtomKey(atom)) {
            didBegin = true
            return { didCommit = true }
        }
        let context = AtomProducerContext<Int, Void>(
            store: StoreContext(),
            transaction: transaction,
            coordinator: ()
        ) { _ in }

        await context.transaction { _ in
            try? await Task.sleep(seconds: 0)
        }

        XCTAssertTrue(didBegin)
        XCTAssertTrue(didCommit)
    }
}
