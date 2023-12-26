import Combine
import XCTest

@testable import Atoms

@MainActor
final class AtomCurrentContextTests: XCTestCase {
    func testRead() {
        let atom = TestValueAtom(value: 100)
        let store = AtomStore()
        let context = AtomCurrentContext(store: StoreContext(store), coordinator: ())

        XCTAssertEqual(context.read(atom), 100)
    }

    func testSet() {
        let atom = TestValueAtom(value: 0)
        let dependency = TestStateAtom(defaultValue: 100)
        let store = AtomStore()
        let transaction = Transaction(key: AtomKey(atom)) {}
        let storeContext = StoreContext(store)
        let context = AtomCurrentContext(store: storeContext, coordinator: ())

        XCTAssertEqual(storeContext.watch(dependency, in: transaction), 100)

        context.set(200, for: dependency)

        XCTAssertEqual(storeContext.watch(dependency, in: transaction), 200)
    }

    func testRefresh() async {
        let atom = TestPublisherAtom { Just(100) }
        let store = AtomStore()
        let context = AtomCurrentContext(store: StoreContext(store), coordinator: ())
        let value = await context.refresh(atom).value

        XCTAssertEqual(value, 100)
    }

    func testCustomRefresh() async {
        let atom = TestCustomRefreshableAtom {
            Just(100)
        } refresh: {
            .success(200)
        }
        let store = AtomStore()
        let context = AtomCurrentContext(store: StoreContext(store), coordinator: ())
        let value = await context.refresh(atom).value

        XCTAssertEqual(value, 200)
    }

    func testReset() {
        let atom = TestValueAtom(value: 0)
        let dependency = TestStateAtom(defaultValue: 0)
        let store = AtomStore()
        let transaction = Transaction(key: AtomKey(atom)) {}
        let storeContext = StoreContext(store)
        let context = AtomTransactionContext(store: StoreContext(store), transaction: transaction, coordinator: ())

        XCTAssertEqual(storeContext.watch(dependency, in: transaction), 0)

        context[dependency] = 100

        XCTAssertEqual(storeContext.watch(dependency, in: transaction), 100)

        context.reset(dependency)

        XCTAssertEqual(context.read(dependency), 0)
    }
}
