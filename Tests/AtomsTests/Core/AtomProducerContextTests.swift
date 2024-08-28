import XCTest

@testable import Atoms

final class AtomProducerContextTests: XCTestCase {
    @MainActor
    func testUpdate() {
        let atom = TestValueAtom(value: 0)
        let transactionState = TransactionState(key: AtomKey(atom))
        var updatedValue: Int?

        let context = AtomProducerContext<Int>(store: StoreContext(), transactionState: transactionState) { value in
            updatedValue = value
        }

        context.update(with: 1)

        XCTAssertEqual(updatedValue, 1)
    }

    @MainActor
    func testOnTermination() {
        let atom = TestValueAtom(value: 0)
        let transactionState = TransactionState(key: AtomKey(atom))
        let context = AtomProducerContext<Int>(store: StoreContext(), transactionState: transactionState) { _ in }

        context.onTermination = {}
        XCTAssertNotNil(context.onTermination)

        transactionState.terminate()
        XCTAssertNil(context.onTermination)

        context.onTermination = {}
        XCTAssertNil(context.onTermination)
    }

    @MainActor
    func testTransaction() {
        let atom = TestValueAtom(value: 0)
        var didBegin = false
        var didCommit = false
        let transactionState = TransactionState(key: AtomKey(atom)) {
            didBegin = true
            return { didCommit = true }
        }
        let context = AtomProducerContext<Int>(store: StoreContext(), transactionState: transactionState) { _ in }

        context.transaction { _ in }

        XCTAssertTrue(didBegin)
        XCTAssertTrue(didCommit)
    }

    @MainActor
    func testAsyncTransaction() async {
        let atom = TestValueAtom(value: 0)
        var didBegin = false
        var didCommit = false
        let transactionState = TransactionState(key: AtomKey(atom)) {
            didBegin = true
            return { didCommit = true }
        }
        let context = AtomProducerContext<Int>(store: StoreContext(), transactionState: transactionState) { _ in }

        await context.transaction { _ in
            try? await Task.sleep(seconds: 0)
        }

        XCTAssertTrue(didBegin)
        XCTAssertTrue(didCommit)
    }
}
