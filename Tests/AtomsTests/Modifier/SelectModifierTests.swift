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

    func testShouldUpdate() {
        let modifier = SelectModifier<String, Int>(keyPath: \.count)

        XCTAssertFalse(modifier.shouldUpdate(newValue: 100, oldValue: 100))
        XCTAssertTrue(modifier.shouldUpdate(newValue: 100, oldValue: 200))
    }

    func testModify() {
        let atom = TestValueAtom(value: 0)
        let modifier = SelectModifier<Int, String>(keyPath: \.description)
        let transaction = Transaction(key: AtomKey(atom)) {}
        let context = AtomModifierContext<String>(transaction: transaction) { _ in }
        let value = modifier.modify(value: 100, context: context)

        XCTAssertEqual(value, "100")
    }

    func testAssociateOverridden() {
        let atom = TestValueAtom(value: 0)
        let modifier = SelectModifier<Int, String>(keyPath: \.description)
        let transaction = Transaction(key: AtomKey(atom)) {}
        let context = AtomModifierContext<String>(transaction: transaction) { _ in }
        let value = modifier.associateOverridden(value: "100", context: context)

        XCTAssertEqual(value, "100")
    }
}
