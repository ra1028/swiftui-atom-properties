import XCTest

@testable import Atoms

@MainActor
final class SnapshotTests: XCTestCase {
    func testRestore() {
        let atom = TestValueAtom(value: 0)
        var isRestoreCalled = false
        let snapshot = Snapshot(atom: atom, value: 100) {
            isRestoreCalled = true
        }

        snapshot.restore()

        XCTAssertTrue(isRestoreCalled)
    }
}
