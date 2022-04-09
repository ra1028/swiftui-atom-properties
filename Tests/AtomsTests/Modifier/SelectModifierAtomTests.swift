import XCTest

@testable import Atoms

@MainActor
final class SelectModifierAtomTests: XCTestCase {
    func testKey() {
        let base = TestStateAtom(defaultValue: "")
        let atom = SelectModifierAtom(base: base, keyPath: \.count)

        XCTAssertNotEqual(ObjectIdentifier(type(of: base.key)), ObjectIdentifier(type(of: atom.key)))
        XCTAssertNotEqual(base.key.hashValue, atom.key.hashValue)
    }

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

    func testShouldNotifyUpdate() {
        let atom = TestStateAtom(defaultValue: "").select(\.count)
        let result0 = atom.shouldNotifyUpdate(newValue: 100, oldValue: 100)
        let result1 = atom.shouldNotifyUpdate(newValue: 100, oldValue: 200)

        XCTAssertFalse(result0)
        XCTAssertTrue(result1)
    }
}
