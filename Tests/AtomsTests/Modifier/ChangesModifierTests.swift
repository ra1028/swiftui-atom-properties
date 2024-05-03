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
}
