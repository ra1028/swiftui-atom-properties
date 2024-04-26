import XCTest

@testable import Atoms

final class TransactionTests: XCTestCase {
    @MainActor
    func testCommit() {
        let key = AtomKey(TestValueAtom(value: 0))
        var beginCount = 0
        var commitCount = 0
        let transaction = Transaction(key: key) {
            beginCount += 1
            return { commitCount += 1 }
        }

        XCTAssertEqual(beginCount, 0)
        XCTAssertEqual(commitCount, 0)

        transaction.commit()

        XCTAssertEqual(beginCount, 0)
        XCTAssertEqual(commitCount, 0)

        transaction.begin()

        XCTAssertEqual(beginCount, 1)
        XCTAssertEqual(commitCount, 0)

        transaction.commit()

        XCTAssertEqual(beginCount, 1)
        XCTAssertEqual(commitCount, 1)

        transaction.begin()
        transaction.commit()

        XCTAssertEqual(beginCount, 1)
        XCTAssertEqual(commitCount, 1)
    }

    @MainActor
    func testAddTermination() {
        let key = AtomKey(TestValueAtom(value: 0))
        let transaction = Transaction(key: key)

        XCTAssertTrue(transaction.terminations.isEmpty)
        transaction.addTermination {}
        XCTAssertEqual(transaction.terminations.count, 1)
        transaction.addTermination {}
        XCTAssertEqual(transaction.terminations.count, 2)
    }

    @MainActor
    func testTerminate() {
        let key = AtomKey(TestValueAtom(value: 0))
        var isBegan = false
        var isCommitted = false
        var isTerminationCalled = false
        let transaction = Transaction(key: key) {
            isBegan = true
            return { isCommitted = true }
        }

        transaction.addTermination {
            isTerminationCalled = true
        }

        XCTAssertFalse(isBegan)
        XCTAssertFalse(isCommitted)
        XCTAssertFalse(isTerminationCalled)
        XCTAssertFalse(transaction.isTerminated)
        XCTAssertFalse(transaction.terminations.isEmpty)

        transaction.begin()
        transaction.terminate()

        XCTAssertTrue(isBegan)
        XCTAssertTrue(isCommitted)
        XCTAssertTrue(isTerminationCalled)
        XCTAssertTrue(transaction.isTerminated)
        XCTAssertTrue(transaction.terminations.isEmpty)

        isTerminationCalled = false
        transaction.addTermination {
            isTerminationCalled = true
        }

        XCTAssertTrue(isTerminationCalled)
        XCTAssertTrue(transaction.terminations.isEmpty)
    }
}
