import Combine
import Testing

@testable import Atoms

struct AtomCurrentContextTests {
    @MainActor
    @Test
    func testRead() {
        let atom = TestValueAtom(value: 100)
        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let context = AtomCurrentContext(
            store: .root(store: store, scopeKey: rootScopeToken.key)
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
        let storeContext = StoreContext.root(store: store, scopeKey: rootScopeToken.key)
        let context = AtomCurrentContext(store: storeContext)

        #expect(storeContext.watch(dependency, in: transactionState) == 100)

        context.set(200, for: dependency)

        #expect(storeContext.watch(dependency, in: transactionState) == 200)
    }

    @MainActor
    @Test
    func testRefresh() async {
        let atom = TestPublisherAtom { Just(100) }
        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let context = AtomCurrentContext(
            store: .root(store: store, scopeKey: rootScopeToken.key)
        )
        let value = await context.refresh(atom).value

        #expect(value == 100)
    }

    @MainActor
    @Test
    func testReset() {
        let atom = TestValueAtom(value: 0)
        let dependency = TestStateAtom(defaultValue: 0)
        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let transactionState = TransactionState(key: AtomKey(atom))
        let storeContext = StoreContext.root(store: store, scopeKey: rootScopeToken.key)
        let context = AtomTransactionContext(store: storeContext, transactionState: transactionState)

        #expect(storeContext.watch(dependency, in: transactionState) == 0)

        context[dependency] = 100

        #expect(storeContext.watch(dependency, in: transactionState) == 100)

        context.reset(dependency)

        #expect(storeContext.read(dependency) == 0)
    }

}
