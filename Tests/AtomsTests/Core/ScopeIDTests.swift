import XCTest

@testable import Atoms

final class ScopeIDTests: XCTestCase {
    func testHashable() {
        let id0 = ScopeID(0)
        let id1 = id0
        let id2 = ScopeID(1)

        XCTAssertEqual(id0, id1)
        XCTAssertNotEqual(id1, id2)
        XCTAssertEqual(id0.hashValue, id1.hashValue)
        XCTAssertNotEqual(id1.hashValue, id2.hashValue)
    }
}
