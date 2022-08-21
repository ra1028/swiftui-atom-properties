import XCTest

@testable import Atoms

@MainActor
final class TransactionTests: XCTestCase {
    func testCommit() {
        let key = AtomKey(TestValueAtom(value: 0))
        var commitCount = 0
        let transaction = Transaction(key: key) {
            commitCount += 1
        }

        XCTAssertEqual(commitCount, 0)
        transaction.commit()
        XCTAssertEqual(commitCount, 1)
        transaction.commit()
        XCTAssertEqual(commitCount, 1)
    }

    func testAddTermination() {
        let key = AtomKey(TestValueAtom(value: 0))
        let transaction = Transaction(key: key) {}

        XCTAssertTrue(transaction.terminations.isEmpty)
        transaction.addTermination(Termination {})
        XCTAssertEqual(transaction.terminations.count, 1)
        transaction.addTermination(Termination {})
        XCTAssertEqual(transaction.terminations.count, 2)
    }

    func testTerminate() {
        let key = AtomKey(TestValueAtom(value: 0))
        var isCommitted = false
        var isTerminationCalled = false
        let transaction = Transaction(key: key) {
            isCommitted = true
        }
        let termination = Termination {
            isTerminationCalled = true
        }

        transaction.addTermination(termination)

        XCTAssertFalse(isCommitted)
        XCTAssertFalse(isTerminationCalled)
        XCTAssertFalse(transaction.isTerminated)
        XCTAssertFalse(transaction.terminations.isEmpty)

        transaction.terminate()

        XCTAssertTrue(isCommitted)
        XCTAssertTrue(isTerminationCalled)
        XCTAssertTrue(transaction.isTerminated)
        XCTAssertTrue(transaction.terminations.isEmpty)

        isTerminationCalled = false
        transaction.addTermination(termination)

        XCTAssertTrue(isTerminationCalled)
        XCTAssertTrue(transaction.terminations.isEmpty)
    }
}
