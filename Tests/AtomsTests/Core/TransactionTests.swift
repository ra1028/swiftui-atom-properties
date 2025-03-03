import XCTest

@testable import Atoms

final class TransactionTests: XCTestCase {
    @MainActor
    func testCommit() {
        let key = AtomKey(TestValueAtom(value: 0))
        var beginCount = 0
        var commitCount = 0
        let transactionState = TransactionState(key: key, scopeKey: nil) {
            beginCount += 1
            return { commitCount += 1 }
        }

        XCTAssertEqual(beginCount, 0)
        XCTAssertEqual(commitCount, 0)

        transactionState.commit()

        XCTAssertEqual(beginCount, 0)
        XCTAssertEqual(commitCount, 0)

        transactionState.begin()

        XCTAssertEqual(beginCount, 1)
        XCTAssertEqual(commitCount, 0)

        transactionState.commit()

        XCTAssertEqual(beginCount, 1)
        XCTAssertEqual(commitCount, 1)

        transactionState.begin()
        transactionState.commit()

        XCTAssertEqual(beginCount, 1)
        XCTAssertEqual(commitCount, 1)
    }

    @MainActor
    func testOnTermination() {
        let key = AtomKey(TestValueAtom(value: 0))
        let transactionState = TransactionState(key: key)

        XCTAssertNil(transactionState.onTermination)

        transactionState.onTermination = {}
        XCTAssertNotNil(transactionState.onTermination)

        transactionState.terminate()
        XCTAssertNil(transactionState.onTermination)

        transactionState.onTermination = {}
        XCTAssertNil(transactionState.onTermination)
    }

    @MainActor
    func testTerminate() {
        let key = AtomKey(TestValueAtom(value: 0))
        var didBegin = false
        var didCommit = false
        var didTerminate = false
        let transactionState = TransactionState(key: key, scopeKey: nil) {
            didBegin = true
            return { didCommit = true }
        }

        transactionState.onTermination = {
            didTerminate = true
        }

        XCTAssertFalse(didBegin)
        XCTAssertFalse(didCommit)
        XCTAssertFalse(didTerminate)
        XCTAssertFalse(transactionState.isTerminated)
        XCTAssertNotNil(transactionState.onTermination)

        transactionState.begin()
        transactionState.terminate()

        XCTAssertTrue(didBegin)
        XCTAssertTrue(didCommit)
        XCTAssertTrue(didTerminate)
        XCTAssertTrue(transactionState.isTerminated)
        XCTAssertNil(transactionState.onTermination)

        didTerminate = false
        transactionState.onTermination = {
            didTerminate = true
        }

        XCTAssertTrue(didTerminate)
        XCTAssertNil(transactionState.onTermination)
    }
}
