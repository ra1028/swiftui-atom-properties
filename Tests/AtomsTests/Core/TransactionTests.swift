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
        var didBegin = false
        var didCommit = false
        var didTerminate = false
        let transaction = Transaction(key: key) {
            didBegin = true
            return { didCommit = true }
        }

        transaction.addTermination {
            didTerminate = true
        }

        XCTAssertFalse(didBegin)
        XCTAssertFalse(didCommit)
        XCTAssertFalse(didTerminate)
        XCTAssertFalse(transaction.isTerminated)
        XCTAssertFalse(transaction.terminations.isEmpty)

        transaction.begin()
        transaction.terminate()

        XCTAssertTrue(didBegin)
        XCTAssertTrue(didCommit)
        XCTAssertTrue(didTerminate)
        XCTAssertTrue(transaction.isTerminated)
        XCTAssertTrue(transaction.terminations.isEmpty)

        didTerminate = false
        transaction.addTermination {
            didTerminate = true
        }

        XCTAssertTrue(didTerminate)
        XCTAssertTrue(transaction.terminations.isEmpty)
    }
}
