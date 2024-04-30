import XCTest

@testable import Atoms

final class ChangesOfModifierTests: XCTestCase {
    @MainActor
    func testChangesOf() {
        let atom = TestStateAtom(defaultValue: "")
        let context = AtomTestContext()
        var updatedCount = 0

        context.onUpdate = {
            updatedCount += 1
        }

        XCTAssertEqual(updatedCount, 0)
        XCTAssertEqual(context.watch(atom.changes(of: \.count)), 0)

        context[atom] = "modified"

        XCTAssertEqual(updatedCount, 1)
        XCTAssertEqual(context.watch(atom.changes(of: \.count)), 8)
        context[atom] = "modified"

        // Should not be updated with an equivalent value.
        XCTAssertEqual(updatedCount, 1)
    }

    func testKey() {
        let modifier0 = ChangesOfModifier<Int, Int>(keyPath: \.byteSwapped)
        let modifier1 = ChangesOfModifier<Int, Int>(keyPath: \.leadingZeroBitCount)

        XCTAssertEqual(modifier0.key, modifier0.key)
        XCTAssertEqual(modifier0.key.hashValue, modifier0.key.hashValue)
        XCTAssertNotEqual(modifier0.key, modifier1.key)
        XCTAssertNotEqual(modifier0.key.hashValue, modifier1.key.hashValue)
    }

    @MainActor
    func testShouldUpdateTransitively() {
        let modifier = ChangesOfModifier<String, Int>(keyPath: \.count)

        XCTAssertFalse(modifier.shouldUpdateTransitively(newValue: 100, oldValue: 100))
        XCTAssertTrue(modifier.shouldUpdateTransitively(newValue: 100, oldValue: 200))
    }

    @MainActor
    func testModify() {
        let atom = TestValueAtom(value: 0)
        let modifier = ChangesOfModifier<Int, String>(keyPath: \.description)
        let transaction = Transaction(key: AtomKey(atom)) {}
        let context = AtomModifierContext<String>(transaction: transaction) { _ in }
        let value = modifier.modify(value: 100, context: context)

        XCTAssertEqual(value, "100")
    }

    @MainActor
    func testManageOverridden() {
        let atom = TestValueAtom(value: 0)
        let modifier = ChangesOfModifier<Int, String>(keyPath: \.description)
        let transaction = Transaction(key: AtomKey(atom)) {}
        let context = AtomModifierContext<String>(transaction: transaction) { _ in }
        let value = modifier.manageOverridden(value: "100", context: context)

        XCTAssertEqual(value, "100")
    }
}
