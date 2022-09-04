import XCTest

@testable import Atoms

@MainActor
final class SnapshotTests: XCTestCase {
    func testRestore() {
        var isRestoreCalled = false
        let snapshot = Snapshot(graph: Graph(), caches: [:]) {
            isRestoreCalled = true
        }

        snapshot.restore()

        XCTAssertTrue(isRestoreCalled)
    }

    func testLookup() {
        let atom0 = TestAtom(value: 0)
        let atom1 = TestAtom(value: 1)
        let atomCache = [
            AtomKey(atom0): AtomCache(atom: atom0, value: 0)
        ]
        let snapshot = Snapshot(graph: Graph(), caches: atomCache) {}

        XCTAssertEqual(snapshot.lookup(atom0), 0)
        XCTAssertNil(snapshot.lookup(atom1))
    }
}
