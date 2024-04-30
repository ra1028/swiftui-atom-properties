import Combine
import XCTest

@testable import Atoms

final class AtomCurrentContextTests: XCTestCase {
    @MainActor
    func testRead() {
        let atom = TestValueAtom(value: 100)
        let store = AtomStore()
        let context = AtomCurrentContext(store: StoreContext(store: store), coordinator: ())

        XCTAssertEqual(context.read(atom), 100)
    }

    @MainActor
    func testSet() {
        let atom = TestValueAtom(value: 0)
        let dependency = TestStateAtom(defaultValue: 100)
        let store = AtomStore()
        let transaction = Transaction(key: AtomKey(atom))
        let storeContext = StoreContext(store: store)
        let context = AtomCurrentContext(store: storeContext, coordinator: ())

        XCTAssertEqual(storeContext.watch(dependency, in: transaction), 100)

        context.set(200, for: dependency)

        XCTAssertEqual(storeContext.watch(dependency, in: transaction), 200)
    }

    @MainActor
    func testRefresh() async {
        let atom = TestPublisherAtom { Just(100) }
        let store = AtomStore()
        let context = AtomCurrentContext(store: StoreContext(store: store), coordinator: ())
        let value = await context.refresh(atom).value

        XCTAssertEqual(value, 100)
    }

    @MainActor
    func testCustomRefresh() async {
        let atom = TestCustomRefreshableAtom {
            Just(100)
        } refresh: {
            .success(200)
        }
        let store = AtomStore()
        let context = AtomCurrentContext(store: StoreContext(store: store), coordinator: ())
        let value = await context.refresh(atom).value

        XCTAssertEqual(value, 200)
    }

    @MainActor
    func testReset() {
        let atom = TestValueAtom(value: 0)
        let dependency = TestStateAtom(defaultValue: 0)
        let store = AtomStore()
        let transaction = Transaction(key: AtomKey(atom))
        let storeContext = StoreContext(store: store)
        let context = AtomTransactionContext(store: StoreContext(store: store), transaction: transaction, coordinator: ())

        XCTAssertEqual(storeContext.watch(dependency, in: transaction), 0)

        context[dependency] = 100

        XCTAssertEqual(storeContext.watch(dependency, in: transaction), 100)

        context.reset(dependency)

        XCTAssertEqual(context.read(dependency), 0)
    }

    @MainActor
    func testCustomReset() {
        let store = AtomStore()
        let context = AtomCurrentContext(store: StoreContext(store: store), coordinator: ())
        let storeContext = StoreContext(store: store)
        let transactionAtom = TestValueAtom(value: 0)
        let atom = TestStateAtom(defaultValue: 0)
        let transaction = Transaction(key: AtomKey(transactionAtom))

        let resettableAtom = TestCustomResettableAtom(
            defaultValue: { context in
                context.watch(atom)
            },
            reset: { context in
                context[atom] = 300
            }
        )

        XCTAssertEqual(storeContext.watch(atom, in: transaction), 0)
        XCTAssertEqual(storeContext.watch(resettableAtom, in: transaction), 0)

        context[atom] = 100

        XCTAssertEqual(storeContext.watch(atom, in: transaction), 100)
        XCTAssertEqual(storeContext.watch(resettableAtom, in: transaction), 100)

        context.reset(resettableAtom)

        XCTAssertEqual(storeContext.watch(atom, in: transaction), 300)
        XCTAssertEqual(storeContext.watch(resettableAtom, in: transaction), 300)
    }
}
