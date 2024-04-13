import XCTest

@testable import Atoms

final class AtomKeyTests: XCTestCase {
    func testKeyHashableForSameAtoms() {
        let atom = TestAtom(value: 0)
        let key0 = AtomKey(atom)
        let key1 = AtomKey(atom)

        XCTAssertEqual(key0, key1)
        XCTAssertEqual(key0.hashValue, key1.hashValue)
    }

    func testKeyHashableForDifferentAtoms() {
        let atom0 = TestAtom(value: 0)
        let atom1 = TestAtom(value: 1)
        let key0 = AtomKey(atom0)
        let key1 = AtomKey(atom1)

        XCTAssertNotEqual(key0, key1)
        XCTAssertNotEqual(key0.hashValue, key1.hashValue)
    }

    func testDictionaryKey() {
        let atom0 = TestAtom(value: 0)
        let atom1 = TestAtom(value: 1)
        let key0 = AtomKey(atom0)
        let key1 = AtomKey(atom1)
        let key2 = AtomKey(atom1)
        var dictionary = [AtomKey: Int]()

        dictionary[key0] = 100
        dictionary[key1] = 200
        dictionary[key2] = 300

        XCTAssertEqual(dictionary[key0], 100)
        XCTAssertEqual(dictionary[key1], 300)
        XCTAssertEqual(dictionary[key2], 300)
    }

    func testDescription() {
        let atom = TestAtom(value: 0)
        let token = ScopeKey.Token()
        let scopeKey = ScopeKey(token: token)
        let key0 = AtomKey(atom)
        let key1 = AtomKey(atom, overrideScopeKey: scopeKey)

        XCTAssertEqual(key0.debugLabel, "TestAtom<Int>")
        XCTAssertEqual(key1.debugLabel, "TestAtom<Int>-override:\(scopeKey.debugLabel)")
    }
}
