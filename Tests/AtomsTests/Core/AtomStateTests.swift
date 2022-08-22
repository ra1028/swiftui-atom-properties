import XCTest

@testable import Atoms

@MainActor
final class AtomStateTests: XCTestCase {
    func testShouldKeepAlive() {
        struct KeepAliveAtom: ValueAtom, KeepAlive, Hashable {
            func value(context: Context) -> Int {
                0
            }
        }

        let state0 = ConcreteAtomState(atom: TestValueAtom(value: 0))
        let state1 = ConcreteAtomState(atom: KeepAliveAtom())

        XCTAssertFalse(state0.shouldKeepAlive)
        XCTAssertTrue(state1.shouldKeepAlive)
    }

    func testReset() {
        let store = Store()
        let context = StoreContext(store)
        let atom = TestStateAtom(defaultValue: 0)
        let transaction = Transaction(key: AtomKey(atom)) {}
        let state = ConcreteAtomState(atom: atom)

        XCTAssertEqual(context.watch(atom, in: transaction), 0)

        context.set(1, for: atom)
        XCTAssertEqual(context.watch(atom, in: transaction), 1)

        state.reset(with: context)

        XCTAssertEqual(context.watch(atom, in: transaction), 0)
    }

    func testNotifyUnassigned() {
        let atom = TestStateAtom(defaultValue: 0)
        let state = ConcreteAtomState(atom: atom)
        let observer = TestObserver()

        XCTAssertTrue(observer.assignedAtomKeys.isEmpty)
        XCTAssertTrue(observer.changedAtomKeys.isEmpty)
        XCTAssertTrue(observer.unassignedAtomKeys.isEmpty)

        state.notifyUnassigned(to: [observer])

        XCTAssertTrue(observer.assignedAtomKeys.isEmpty)
        XCTAssertTrue(observer.changedAtomKeys.isEmpty)
        XCTAssertEqual(observer.unassignedAtomKeys, [AtomKey(atom)])
    }
}
