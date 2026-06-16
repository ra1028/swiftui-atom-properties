import Combine
import XCTest

@testable import Atoms

final class AtomCurrentContextTests: XCTestCase {
    @MainActor
    func testRead() {
        let atom = TestValueAtom(value: 100)
        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let context = AtomCurrentContext(
            store: .root(store: store, scopeKey: rootScopeToken.key)
        )

        XCTAssertEqual(context.read(atom), 100)
    }

    @MainActor
    func testSet() {
        let atom = TestValueAtom(value: 0)
        let dependency = TestStateAtom(defaultValue: 100)
        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let transactionState = TransactionState(key: AtomKey(atom))
        let storeContext = StoreContext.root(store: store, scopeKey: rootScopeToken.key)
        let context = AtomCurrentContext(store: storeContext)

        XCTAssertEqual(storeContext.watch(dependency, in: transactionState), 100)

        context.set(200, for: dependency)

        XCTAssertEqual(storeContext.watch(dependency, in: transactionState), 200)
    }

    @MainActor
    func testRefresh() async {
        let atom = TestPublisherAtom { Just(100) }
        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let context = AtomCurrentContext(
            store: .root(store: store, scopeKey: rootScopeToken.key)
        )
        let value = await context.refresh(atom).value

        XCTAssertEqual(value, 100)
    }

    @MainActor
    func testReset() {
        let atom = TestValueAtom(value: 0)
        let dependency = TestStateAtom(defaultValue: 0)
        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let transactionState = TransactionState(key: AtomKey(atom))
        let storeContext = StoreContext.root(store: store, scopeKey: rootScopeToken.key)
        let context = AtomTransactionContext(store: storeContext, transactionState: transactionState)

        XCTAssertEqual(storeContext.watch(dependency, in: transactionState), 0)

        context[dependency] = 100

        XCTAssertEqual(storeContext.watch(dependency, in: transactionState), 100)

        context.reset(dependency)

        XCTAssertEqual(storeContext.read(dependency), 0)
    }

}
