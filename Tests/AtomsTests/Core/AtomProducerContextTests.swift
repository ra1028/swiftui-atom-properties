import Testing

@testable import Atoms

struct AtomProducerContextTests {
    @MainActor
    @Test
    func testUpdate() {
        let atom = TestValueAtom(value: 0)
        let transactionState = TransactionState(key: AtomKey(atom))
        var updatedValue: Int?

        let context = AtomProducerContext<Int>(store: .dummy, transactionState: transactionState) { value in
            updatedValue = value
        }

        context.update(with: 1)

        #expect(updatedValue == 1)
    }

    @MainActor
    @Test
    func testOnTermination() {
        let atom = TestValueAtom(value: 0)
        let transactionState = TransactionState(key: AtomKey(atom))
        let context = AtomProducerContext<Int>(store: .dummy, transactionState: transactionState) { _ in }

        context.onTermination = {}
        #expect(context.onTermination != nil)

        transactionState.terminate()
        #expect(context.onTermination == nil)

        context.onTermination = {}
        #expect(context.onTermination == nil)
    }

    @MainActor
    @Test
    func testTransaction() {
        let atom = TestValueAtom(value: 0)
        var didBegin = false
        var didCommit = false
        let transactionState = TransactionState(key: AtomKey(atom)) {
            didBegin = true
            return { didCommit = true }
        }
        let context = AtomProducerContext<Int>(store: .dummy, transactionState: transactionState) { _ in }

        context.transaction { _ in }

        #expect(didBegin)
        #expect(didCommit)
    }

    @MainActor
    @Test
    func testAsyncTransaction() async {
        let atom = TestValueAtom(value: 0)
        var didBegin = false
        var didCommit = false
        let transactionState = TransactionState(key: AtomKey(atom)) {
            didBegin = true
            return { didCommit = true }
        }
        let context = AtomProducerContext<Int>(store: .dummy, transactionState: transactionState) { _ in }

        await context.transaction { _ in
            try? await Task.sleep(seconds: 0)
        }

        #expect(didBegin)
        #expect(didCommit)
    }
}
