import Testing

@testable import Atoms

struct TransactionTests {
    @MainActor
    @Test
    func testCommit() {
        let key = AtomKey(TestValueAtom(value: 0))
        var beginCount = 0
        var commitCount = 0
        let transactionState = TransactionState(key: key) {
            beginCount += 1
            return { commitCount += 1 }
        }

        #expect(beginCount == 0)
        #expect(commitCount == 0)

        transactionState.commit()

        #expect(beginCount == 0)
        #expect(commitCount == 0)

        transactionState.begin()

        #expect(beginCount == 1)
        #expect(commitCount == 0)

        transactionState.commit()

        #expect(beginCount == 1)
        #expect(commitCount == 1)

        transactionState.begin()
        transactionState.commit()

        #expect(beginCount == 1)
        #expect(commitCount == 1)
    }

    @MainActor
    @Test
    func testOnTermination() {
        let key = AtomKey(TestValueAtom(value: 0))
        let transactionState = TransactionState(key: key)

        #expect(transactionState.onTermination == nil)

        transactionState.onTermination = {}
        #expect(transactionState.onTermination != nil)

        transactionState.terminate()
        #expect(transactionState.onTermination == nil)

        transactionState.onTermination = {}
        #expect(transactionState.onTermination == nil)
    }

    @MainActor
    @Test
    func testTerminate() {
        let key = AtomKey(TestValueAtom(value: 0))
        var didBegin = false
        var didCommit = false
        var didTerminate = false
        let transactionState = TransactionState(key: key) {
            didBegin = true
            return { didCommit = true }
        }

        transactionState.onTermination = {
            didTerminate = true
        }

        #expect(!(didBegin))
        #expect(!(didCommit))
        #expect(!(didTerminate))
        #expect(!(transactionState.isTerminated))
        #expect(transactionState.onTermination != nil)

        transactionState.begin()
        transactionState.terminate()

        #expect(didBegin)
        #expect(didCommit)
        #expect(didTerminate)
        #expect(transactionState.isTerminated)
        #expect(transactionState.onTermination == nil)

        didTerminate = false
        transactionState.onTermination = {
            didTerminate = true
        }

        #expect(didTerminate)
        #expect(transactionState.onTermination == nil)
    }
}
