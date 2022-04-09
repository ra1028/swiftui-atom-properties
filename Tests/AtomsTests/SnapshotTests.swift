import XCTest

@testable import Atoms

@MainActor
final class SnapshotTests: XCTestCase {
    func testRestore() {
        let container = StoreContainer()
        let relationshipContainer = RelationshipContainer()
        let relationship = Relationship(container: relationshipContainer)
        let store = Store(container: container)
        let atom = TestValueAtom(value: 0)
        let snapshot = Snapshot(atom: atom, value: 100, store: store)

        let value = store.watch(atom, relationship: relationship) {}

        XCTAssertEqual(value, 0)

        snapshot.restore()

        XCTAssertEqual(store.read(atom), 100)
    }
}
