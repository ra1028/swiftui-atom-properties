import Combine
import XCTest

@testable import Atoms

final class AtomTransactionContextTests: XCTestCase {
    @MainActor
    func testRead() {
        let atom = TestValueAtom(value: 100)
        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let transactionState = TransactionState(key: AtomKey(atom))
        let context = AtomTransactionContext(
            store: .root(store: store, scopeKey: rootScopeToken.key),
            transactionState: transactionState
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
        let context = AtomTransactionContext(
            store: .root(store: store, scopeKey: rootScopeToken.key),
            transactionState: transactionState
        )

        XCTAssertEqual(context.watch(dependency), 100)

        context.set(200, for: dependency)

        XCTAssertEqual(context.watch(dependency), 200)
    }

    @MainActor
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

        XCTAssertTrue(context.watch(atom1).isSuspending)

        let value = await context.refresh(atom1).value

        XCTAssertEqual(value, 100)
        XCTAssertEqual(context.watch(atom1).value, 100)
    }

    @MainActor
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

        XCTAssertEqual(context.watch(dependency), 0)

        context[dependency] = 100

        XCTAssertEqual(context.watch(dependency), 100)

        context.reset(dependency)

        XCTAssertEqual(context.read(dependency), 0)
    }

    @MainActor
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

        XCTAssertEqual(value, 200)
        XCTAssertEqual(store.children, [AtomKey(atom1): [AtomKey(atom0)]])
        XCTAssertEqual(store.dependencies, [AtomKey(atom0): [AtomKey(atom1)]])
    }
}
