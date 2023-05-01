import XCTest

@testable import Atoms

@MainActor
final class AtomCacheTests: XCTestCase {
    func testShouldKeepAlive() {
        struct KeepAliveAtom: ValueAtom, KeepAlive, Hashable {
            func value(context: Context) -> Int {
                0
            }
        }

        let cache0 = AtomCache(atom: TestValueAtom(value: 0), value: 0)
        let cache1 = AtomCache(atom: KeepAliveAtom(), value: 0)

        XCTAssertFalse(cache0.shouldKeepAlive)
        XCTAssertTrue(cache1.shouldKeepAlive)
    }

    func testDescription() {
        let atom = TestAtom(value: 0)
        let cache = AtomCache(atom: atom, value: 0)

        XCTAssertEqual(cache.description, "0")
    }
}
