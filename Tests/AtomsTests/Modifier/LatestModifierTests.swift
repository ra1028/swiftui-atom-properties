import XCTest

@testable import Atoms

final class LatestModifierTests: XCTestCase {
    struct Item {
        let id: Int
        let isValid: Bool
    }

    @MainActor
    func testLatest() {
        let atom = TestStateAtom(defaultValue: Item(id: 1, isValid: false))
        let context = AtomTestContext()

        // Initially nil because isValid is false
        XCTAssertNil(context.watch(atom.latest(\.isValid)))

        // Update with valid item
        context[atom] = Item(id: 2, isValid: true)

        // Should return the valid item
        XCTAssertEqual(context.watch(atom.latest(\.isValid))?.id, 2)

        // Update with invalid item
        context[atom] = Item(id: 3, isValid: false)

        // Should still return the last valid item
        XCTAssertEqual(context.watch(atom.latest(\.isValid))?.id, 2)

        // Update with another valid item
        context[atom] = Item(id: 4, isValid: true)

        // Should return the new valid item
        XCTAssertEqual(context.watch(atom.latest(\.isValid))?.id, 4)

        // Update with invalid item again
        context[atom] = Item(id: 5, isValid: false)

        // Should still return the last valid item
        XCTAssertEqual(context.watch(atom.latest(\.isValid))?.id, 4)
    }

    @MainActor
    func testLatestWithMultipleWatchers() {
        let atom = TestStateAtom(defaultValue: Item(id: 1, isValid: false))
        let context = AtomTestContext()

        // Watch both current and latest
        XCTAssertEqual(context.watch(atom).id, 1)
        XCTAssertNil(context.watch(atom.latest(\.isValid)))

        // Update with valid item
        context[atom] = Item(id: 2, isValid: true)

        XCTAssertEqual(context.watch(atom).id, 2)
        XCTAssertEqual(context.watch(atom.latest(\.isValid))?.id, 2)

        // Update with invalid item
        context[atom] = Item(id: 3, isValid: false)

        XCTAssertEqual(context.watch(atom).id, 3)
        XCTAssertEqual(context.watch(atom.latest(\.isValid))?.id, 2)
    }

    @MainActor
    func testLatestUpdatesDownstream() {
        let atom = TestStateAtom(defaultValue: Item(id: 1, isValid: false))
        let context = AtomTestContext()
        var updatedCount = 0

        context.onUpdate = {
            updatedCount += 1
        }

        // Initial watch
        XCTAssertEqual(updatedCount, 0)
        XCTAssertNil(context.watch(atom.latest(\.isValid)))

        // Update with valid item - should trigger update
        context[atom] = Item(id: 2, isValid: true)
        XCTAssertEqual(updatedCount, 1)
        XCTAssertEqual(context.watch(atom.latest(\.isValid))?.id, 2)

        // Update with invalid item - should still trigger update
        context[atom] = Item(id: 3, isValid: false)
        XCTAssertEqual(updatedCount, 2)
        XCTAssertEqual(context.watch(atom.latest(\.isValid))?.id, 2)

        // Update with another valid item - should trigger update
        context[atom] = Item(id: 4, isValid: true)
        XCTAssertEqual(updatedCount, 3)
        XCTAssertEqual(context.watch(atom.latest(\.isValid))?.id, 4)
    }

    @MainActor
    func testKey() {
        let modifier1 = LatestModifier<Item>(keyPath: \.isValid)
        let modifier2 = LatestModifier<Item>(keyPath: \.isValid)

        XCTAssertEqual(modifier1.key, modifier2.key)
        XCTAssertEqual(modifier1.key.hashValue, modifier2.key.hashValue)
    }

    @MainActor
    func testLatestWithBoolValue() {
        let atom = TestStateAtom(defaultValue: true)
        let context = AtomTestContext()

        // Initially should return the value if it's true
        XCTAssertEqual(context.watch(atom.latest(\.self)), true)

        // Update to false
        context[atom] = false

        // Should still return the last true value
        XCTAssertEqual(context.watch(atom.latest(\.self)), true)

        // Update to true again
        context[atom] = true

        // Should return the new true value
        XCTAssertEqual(context.watch(atom.latest(\.self)), true)
    }

    @MainActor
    func testLatestWithInitialValidValue() {
        let atom = TestStateAtom(defaultValue: Item(id: 1, isValid: true))
        let context = AtomTestContext()

        // Should immediately return the initial valid value
        XCTAssertEqual(context.watch(atom.latest(\.isValid))?.id, 1)

        // Update with invalid item
        context[atom] = Item(id: 2, isValid: false)

        // Should still return the initial valid value
        XCTAssertEqual(context.watch(atom.latest(\.isValid))?.id, 1)
    }
}
