import XCTest

@testable import Atoms

final class AtomCacheTests: XCTestCase {
    @MainActor
    func testDescription() {
        let atom = TestAtom(value: 0)
        let cache = AtomCache(atom: atom, value: 0)

        XCTAssertEqual(cache.description, "0")
    }
}
