import XCTest

@testable import Atoms

final class PreviousModifierTests: XCTestCase {
    @MainActor
    func testPrevious() {
        let atom = TestStateAtom(defaultValue: "initial")
        let context = AtomTestContext()

        XCTAssertNil(context.watch(atom.previous))

        // Update the atom value
        context[atom] = "second"

        // Now previous should return the initial value
        XCTAssertEqual(context.watch(atom.previous), "initial")

        // Update again
        context[atom] = "third"

        // Previous should now return "second"
        XCTAssertEqual(context.watch(atom.previous), "second")

        // Another update
        context[atom] = "fourth"

        // Previous should now return "third"
        XCTAssertEqual(context.watch(atom.previous), "third")
    }

    @MainActor
    func testPreviousWithMultipleWatchers() {
        let atom = TestStateAtom(defaultValue: 100)
        let context = AtomTestContext()

        // Watch both current and previous
        XCTAssertEqual(context.watch(atom), 100)
        XCTAssertNil(context.watch(atom.previous))

        // Update the value
        context[atom] = 200

        // Check both watchers
        XCTAssertEqual(context.watch(atom), 200)
        XCTAssertEqual(context.watch(atom.previous), 100)

        // Update again
        context[atom] = 300

        XCTAssertEqual(context.watch(atom), 300)
        XCTAssertEqual(context.watch(atom.previous), 200)
    }

    @MainActor
    func testPreviousUpdatesDownstream() {
        let atom = TestStateAtom(defaultValue: 0)
        let context = AtomTestContext()
        var updatedCount = 0

        context.onUpdate = {
            updatedCount += 1
        }

        // Initial watch
        XCTAssertEqual(updatedCount, 0)
        XCTAssertNil(context.watch(atom.previous))

        // First update
        context[atom] = 1
        XCTAssertEqual(updatedCount, 1)
        XCTAssertEqual(context.watch(atom.previous), 0)

        // Second update
        context[atom] = 2
        XCTAssertEqual(updatedCount, 2)
        XCTAssertEqual(context.watch(atom.previous), 1)
    }

    @MainActor
    func testKey() {
        let modifier = PreviousModifier<Int>()

        XCTAssertEqual(modifier.key, modifier.key)
        XCTAssertEqual(modifier.key.hashValue, modifier.key.hashValue)
    }
}
