import XCTest

@testable import Atoms

@MainActor
final class TaskPhaseModifierAtomTests: XCTestCase {
    struct TestAtom: TaskAtom, Hashable {
        func value(context: Context) async -> Int {
            0
        }
    }

    func testKey() {
        let base = TestAtom()
        let atom = TaskPhaseModifierAtom(base: base)

        XCTAssertEqual(base.key.hashValue, atom.key.hashValue)
        XCTAssertNotEqual(
            ObjectIdentifier(type(of: base.key)),
            ObjectIdentifier(type(of: atom.key))
        )
    }

    func testPhase() {
        let atom = TestAtom()
        let context = AtomTestContext()

        XCTAssertEqual(context.watch(atom.phase), .suspending)

        let expectation = expectation(description: "Update")
        context.onUpdate = expectation.fulfill

        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(context.watch(atom.phase), .success(0))
    }
}
