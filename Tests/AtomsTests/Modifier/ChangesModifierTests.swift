import XCTest

@testable import Atoms

final class ChangesModifierTests: XCTestCase {
    @MainActor
    func testChanges() {
        let atom = TestStateAtom(defaultValue: "")
        let context = AtomTestContext()
        var updatedCount = 0

        context.onUpdate = {
            updatedCount += 1
        }

        XCTAssertEqual(updatedCount, 0)
        XCTAssertEqual(context.watch(atom.changes), "")

        context[atom] = "modified"

        XCTAssertEqual(updatedCount, 1)
        XCTAssertEqual(context.watch(atom.changes), "modified")

        context[atom] = "modified"

        // Should not be updated with an equivalent value.
        XCTAssertEqual(updatedCount, 1)
    }

    @MainActor
    func testKey() {
        let modifier = ChangesModifier<Int>()

        XCTAssertEqual(modifier.key, modifier.key)
        XCTAssertEqual(modifier.key.hashValue, modifier.key.hashValue)
    }

    @MainActor
    func testShouldUpdateTransitively() {
        let modifier = ChangesModifier<Int>()

        XCTAssertFalse(modifier.shouldUpdateTransitively(newValue: 100, oldValue: 100))
        XCTAssertTrue(modifier.shouldUpdateTransitively(newValue: 100, oldValue: 200))
    }

    @MainActor
    func testModify() {
        let atom = TestValueAtom(value: 0)
        let modifier = ChangesModifier<Int>()
        let transaction = Transaction(key: AtomKey(atom))
        let context = AtomModifierContext<Int>(transaction: transaction) { _ in }
        let value = modifier.modify(value: 100, context: context)

        XCTAssertEqual(value, 100)
    }

    @MainActor
    func testManageOverridden() {
        let atom = TestValueAtom(value: 0)
        let modifier = ChangesModifier<Int>()
        let transaction = Transaction(key: AtomKey(atom))
        let context = AtomModifierContext<Int>(transaction: transaction) { _ in }
        let value = modifier.manageOverridden(value: 100, context: context)

        XCTAssertEqual(value, 100)
    }
}
