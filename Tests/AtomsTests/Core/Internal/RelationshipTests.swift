import XCTest

@testable import Atoms

@MainActor
final class RelationshipTests: XCTestCase {
    func testSubscript() {
        let container = RelationshipContainer()
        let relationship = Relationship(container: container)
        let atom = TestValueAtom(value: 0)
        var isTerminated = false

        relationship[atom] = Relation(retaining: AtomHostBase()) {
            isTerminated = true
        }

        XCTAssertNotNil(relationship[atom])

        relationship[atom] = nil

        XCTAssertNil(relationship[atom])
        XCTAssertTrue(isTerminated)
    }
}
