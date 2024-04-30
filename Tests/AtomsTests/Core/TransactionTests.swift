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
    func testOnTermination() {
        let key = AtomKey(TestValueAtom(value: 0))
        let transaction = Transaction(key: key)

        XCTAssertNil(transaction.onTermination)

        transaction.onTermination = {}
        XCTAssertNotNil(transaction.onTermination)

        transaction.terminate()
        XCTAssertNil(transaction.onTermination)

        transaction.onTermination = {}
        XCTAssertNil(transaction.onTermination)
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

        transaction.onTermination = {
            didTerminate = true
        }

        XCTAssertFalse(didBegin)
        XCTAssertFalse(didCommit)
        XCTAssertFalse(didTerminate)
        XCTAssertFalse(transaction.isTerminated)
        XCTAssertNotNil(transaction.onTermination)

        transaction.begin()
        transaction.terminate()

        XCTAssertTrue(didBegin)
        XCTAssertTrue(didCommit)
        XCTAssertTrue(didTerminate)
        XCTAssertTrue(transaction.isTerminated)
        XCTAssertNil(transaction.onTermination)

        didTerminate = false
        transaction.onTermination = {
            didTerminate = true
        }

        XCTAssertTrue(didTerminate)
        XCTAssertNil(transaction.onTermination)
    }
}
