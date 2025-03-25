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
    func testCustomRefresh() async {
        let atom = TestCustomRefreshableAtom { _ in
            100
        } refresh: { _ in
            200
        }
        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let context = AtomCurrentContext(
            store: .root(store: store, scopeKey: rootScopeToken.key)
        )

        let value = await context.refresh(atom)
        XCTAssertEqual(value, 200)
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

    @MainActor
    func testCustomReset() {
        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let storeContext = StoreContext.root(store: store, scopeKey: rootScopeToken.key)
        let context = AtomCurrentContext(store: storeContext)
        let transactionAtom = TestValueAtom(value: 0)
        let atom = TestStateAtom(defaultValue: 0)
        let transactionState = TransactionState(key: AtomKey(transactionAtom))

        let resettableAtom = TestCustomResettableAtom(
            defaultValue: { context in
                context.watch(atom)
            },
            reset: { context in
                context[atom] = 300
            }
        )

        XCTAssertEqual(storeContext.watch(atom, in: transactionState), 0)
        XCTAssertEqual(storeContext.watch(resettableAtom, in: transactionState), 0)

        context[atom] = 100

        XCTAssertEqual(storeContext.watch(atom, in: transactionState), 100)
        XCTAssertEqual(storeContext.watch(resettableAtom, in: transactionState), 100)

        context.reset(resettableAtom)

        XCTAssertEqual(storeContext.watch(atom, in: transactionState), 300)
        XCTAssertEqual(storeContext.watch(resettableAtom, in: transactionState), 300)
    }
}
