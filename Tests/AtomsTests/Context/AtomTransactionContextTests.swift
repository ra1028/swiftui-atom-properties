import Combine
import Testing

@testable import Atoms

struct AtomTransactionContextTests {
    @MainActor
    @Test
    func testRead() {
        let atom = TestValueAtom(value: 100)
        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let transactionState = TransactionState(key: AtomKey(atom))
        let context = AtomTransactionContext(
            store: .root(store: store, scopeKey: rootScopeToken.key),
            transactionState: transactionState
        )

        #expect(context.read(atom) == 100)
    }

    @MainActor
    @Test
    func testSet() {
        let atom = TestValueAtom(value: 0)
        let dependency = TestStateAtom(defaultValue: 100)
        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let transactionState = TransactionState(key: AtomKey(atom))
        let context = AtomTransactionContext(
            store: .root(store: store, scopeKey: rootScopeToken.key),
            transactionState: transactionState
        )

        #expect(context.watch(dependency) == 100)

        context.set(200, for: dependency)

        #expect(context.watch(dependency) == 200)
    }

    @MainActor
    @Test
    func testRefresh() async {
        let atom0 = TestValueAtom(value: 0)
        let atom1 = TestPublisherAtom { Just(100) }
        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let transactionState = TransactionState(key: AtomKey(atom0))
        let context = AtomTransactionContext(
            store: .root(store: store, scopeKey: rootScopeToken.key),
            transactionState: transactionState
        )

        #expect(context.watch(atom1).isSuspending)

        let value = await context.refresh(atom1).value

        #expect(value == 100)
        #expect(context.watch(atom1).value == 100)
    }

    @MainActor
    @Test
    func testReset() {
        let atom = TestValueAtom(value: 0)
        let dependency = TestStateAtom(defaultValue: 0)
        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let transactionState = TransactionState(key: AtomKey(atom))
        let context = AtomTransactionContext(
            store: .root(store: store, scopeKey: rootScopeToken.key),
            transactionState: transactionState
        )

        #expect(context.watch(dependency) == 0)

        context[dependency] = 100

        #expect(context.watch(dependency) == 100)

        context.reset(dependency)

        #expect(context.read(dependency) == 0)
    }

    @MainActor
    @Test
    func testWatch() {
        let atom0 = TestValueAtom(value: 100)
        let atom1 = TestStateAtom(defaultValue: 200)
        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let transactionState = TransactionState(key: AtomKey(atom0))
        let context = AtomTransactionContext(
            store: .root(store: store, scopeKey: rootScopeToken.key),
            transactionState: transactionState
        )

        let value = context.watch(atom1)

        #expect(value == 200)
        #expect(store.children == [AtomKey(atom1): [AtomKey(atom0)]])
        #expect(store.dependencies == [AtomKey(atom0): [AtomKey(atom1)]])
    }
}
