import XCTest

@testable import Atoms

final class AtomCacheTests: XCTestCase {
    @MainActor
    func testUpdated() {
        let atom = TestAtom(value: 0)
        let scopeToken = ScopeKey.Token()
        let cache = AtomCache(atom: atom, value: 0, initScopeKey: scopeToken.key)
        let updated = cache.updated(value: 1)

        XCTAssertEqual(updated.atom, atom)
        XCTAssertEqual(updated.value, 1)
        XCTAssertEqual(updated.initScopeKey, scopeToken.key)
    }

    @MainActor
    func testDescription() {
        let atom = TestAtom(value: 0)
        let cache = AtomCache(atom: atom, value: 0)

        XCTAssertEqual(cache.description, "0")
    }
}
