import XCTest

@testable import Atoms

@MainActor
final class SelectModifierTests: XCTestCase {
    func testSelect() {
        let atom = TestStateAtom(defaultValue: "")
        let context = AtomTestContext()
        var updatedCount = 0

        context.onUpdate = {
            updatedCount += 1
        }

        XCTAssertEqual(updatedCount, 0)
        XCTAssertEqual(context.watch(atom.select(\.count)), 0)

        context[atom] = "modified"

        XCTAssertEqual(updatedCount, 1)
        XCTAssertEqual(context.watch(atom.select(\.count)), 8)
        context[atom] = "modified"

        // Should not be updated with an equivalent value.
        XCTAssertEqual(updatedCount, 1)
    }

    func testKey() {
        let modifier0 = SelectModifier<Int, Int>(keyPath: \.byteSwapped)
        let modifier1 = SelectModifier<Int, Int>(keyPath: \.leadingZeroBitCount)

        XCTAssertEqual(modifier0.key, modifier0.key)
        XCTAssertEqual(modifier0.key.hashValue, modifier0.key.hashValue)
        XCTAssertNotEqual(modifier0.key, modifier1.key)
        XCTAssertNotEqual(modifier0.key.hashValue, modifier1.key.hashValue)
    }

    func testShouldNotifyUpdate() {
        let modifier = SelectModifier<String, Int>(keyPath: \.count)

        XCTAssertFalse(modifier.shouldNotifyUpdate(newValue: 100, oldValue: 100))
        XCTAssertTrue(modifier.shouldNotifyUpdate(newValue: 100, oldValue: 200))
    }

    func testValue() {
        let atom = TestValueAtom(value: 0)
        let modifier = SelectModifier<Int, String>(keyPath: \.description)
        let store = AtomStore()
        let transaction = Transaction(key: AtomKey(atom)) {}
        let context = AtomLoaderContext<String, Void>(
            store: StoreContext(store),
            transaction: transaction,
            coordinator: (),
            update: { _, _ in }
        )
        let value = modifier.value(context: context, with: 100)

        XCTAssertEqual(value, "100")
    }

    func testHanlde() {
        let atom = TestValueAtom(value: 0)
        let modifier = SelectModifier<Int, String>(keyPath: \.description)
        let store = AtomStore()
        let transaction = Transaction(key: AtomKey(atom)) {}
        let context = AtomLoaderContext<String, Void>(
            store: StoreContext(store),
            transaction: transaction,
            coordinator: (),
            update: { _, _ in }
        )

        let value = modifier.handle(context: context, with: "100")
        XCTAssertEqual(value, "100")
    }
}
