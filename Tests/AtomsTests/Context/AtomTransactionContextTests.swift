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

    @available(*, deprecated)
    @MainActor
    func testCustomRefresh() async {
        let atom0 = TestValueAtom(value: 0)
        let atom1 = TestCustomRefreshableAtom { _ in
            100
        } refresh: { _ in
            200
        }
        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let transactionState = TransactionState(key: AtomKey(atom0))
        let context = AtomTransactionContext(
            store: .root(store: store, scopeKey: rootScopeToken.key),
            transactionState: transactionState
        )

        XCTAssertEqual(context.watch(atom1), 100)

        let value = await context.refresh(atom1)
        XCTAssertEqual(value, 200)
        XCTAssertEqual(context.watch(atom1), 200)
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

    @available(*, deprecated)
    @MainActor
    func testCustomReset() {
        let transactionAtom = TestValueAtom(value: 0)
        let atom = TestStateAtom(defaultValue: 0)
        let resettableAtom = TestCustomResettableAtom(
            defaultValue: { context in
                context.watch(atom)
            },
            reset: { context in
                context[atom] = 300
            }
        )

        let store = AtomStore()
        let rootScopeToken = ScopeKey.Token()
        let transactionState = TransactionState(key: AtomKey(transactionAtom))
        let context = AtomTransactionContext(
            store: .root(store: store, scopeKey: rootScopeToken.key),
            transactionState: transactionState
        )

        XCTAssertEqual(context.watch(atom), 0)
        XCTAssertEqual(context.watch(resettableAtom), 0)

        context[atom] = 100

        XCTAssertEqual(context.watch(atom), 100)
        XCTAssertEqual(context.watch(resettableAtom), 100)

        context.reset(resettableAtom)

        XCTAssertEqual(context.watch(atom), 300)
        XCTAssertEqual(context.watch(resettableAtom), 300)
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
