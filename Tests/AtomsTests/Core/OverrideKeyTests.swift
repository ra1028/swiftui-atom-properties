import XCTest

@testable import Atoms

final class OverrideKeyTests: XCTestCase {
    func testKeyHashableForSameAtoms() {
        let atom = TestAtom(value: 0)
        let key0 = OverrideKey(atom)
        let key1 = OverrideKey(atom)

        XCTAssertEqual(key0, key1)
        XCTAssertEqual(key0.hashValue, key1.hashValue)
    }

    func testKeyHashableForDifferentAtoms() {
        let atom0 = TestAtom(value: 0)
        let atom1 = TestAtom(value: 1)
        let key0 = OverrideKey(atom0)
        let key1 = OverrideKey(atom1)

        XCTAssertNotEqual(key0, key1)
        XCTAssertNotEqual(key0.hashValue, key1.hashValue)
    }

    func testKeyHashableForSameAtomTypes() {
        let key0 = OverrideKey(TestAtom<Int>.self)
        let key1 = OverrideKey(TestAtom<Int>.self)

        XCTAssertEqual(key0, key1)
        XCTAssertEqual(key0.hashValue, key1.hashValue)
    }

    func testKeyHashableForDifferentAtomTypes() {
        let key0 = OverrideKey(TestAtom<Int>.self)
        let key1 = OverrideKey(TestAtom<String>.self)

        XCTAssertNotEqual(key0, key1)
        XCTAssertNotEqual(key0.hashValue, key1.hashValue)
    }

    func testDictionaryKey() {
        let atom0 = TestAtom(value: 0)
        let atom1 = TestAtom(value: 1)
        let key0 = OverrideKey(atom0)
        let key1 = OverrideKey(atom1)
        let key2 = OverrideKey(atom1)
        let key3 = OverrideKey(TestAtom<Int>.self)
        var dictionary = [OverrideKey: Int]()

        dictionary[key0] = 100
        dictionary[key1] = 200
        dictionary[key2] = 300
        dictionary[key3] = 400

        XCTAssertEqual(dictionary[key0], 100)
        XCTAssertEqual(dictionary[key1], 300)
        XCTAssertEqual(dictionary[key2], 300)
        XCTAssertEqual(dictionary[key3], 400)
    }
}
