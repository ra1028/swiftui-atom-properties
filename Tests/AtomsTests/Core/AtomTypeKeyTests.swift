import XCTest

@testable import Atoms

final class AtomTypeKeyTests: XCTestCase {
    func testKeyHashableForSameAtoms() {
        let key0 = AtomTypeKey(TestValueAtom<Int>.self)
        let key1 = AtomTypeKey(TestValueAtom<Int>.self)

        XCTAssertEqual(key0, key1)
        XCTAssertEqual(key0.hashValue, key1.hashValue)
    }

    func testKeyHashableForDifferentAtoms() {
        let key0 = AtomTypeKey(TestValueAtom<Int>.self)
        let key1 = AtomTypeKey(TestStateAtom<Int>.self)

        XCTAssertNotEqual(key0, key1)
        XCTAssertNotEqual(key0.hashValue, key1.hashValue)
    }

    func testDictionaryKey() {
        let key0 = AtomTypeKey(TestValueAtom<Int>.self)
        let key1 = AtomTypeKey(TestStateAtom<Int>.self)
        let key2 = AtomTypeKey(TestStateAtom<Int>.self)
        var dictionary = [AtomTypeKey: Int]()

        dictionary[key0] = 100
        dictionary[key1] = 200
        dictionary[key2] = 300

        XCTAssertEqual(dictionary[key0], 100)
        XCTAssertEqual(dictionary[key1], 300)
        XCTAssertEqual(dictionary[key2], 300)
    }
}
