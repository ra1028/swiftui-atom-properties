import XCTest

@testable import Atoms

@MainActor
final class RelationTests: XCTestCase {
    func testTermination() {
        var host: AtomHostBase? = AtomHostBase()
        weak var weakHost = host
        var isTerminated = false
        var relation: Relation? = Relation(retaining: host!) {
            isTerminated = true
        }

        host = nil

        XCTAssertNotNil(weakHost)
        XCTAssertFalse(isTerminated)

        relation = nil

        XCTAssertNil(relation)
        XCTAssertNil(weakHost)
        XCTAssertTrue(isTerminated)
    }
}
