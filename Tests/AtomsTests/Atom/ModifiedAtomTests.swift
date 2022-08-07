import XCTest

@testable import Atoms

@MainActor
final class ModifiedAtomTests: XCTestCase {
    func testKey() {
        let atom = TestValueAtom(value: 0)
        let modifier = SelectModifier<Int, String>(keyPath: \.description)
        let modifiedAtom = ModifiedAtom(atom: atom, modifier: modifier)

        XCTAssertEqual(modifiedAtom.key, modifiedAtom.key)
        XCTAssertEqual(modifiedAtom.key.hashValue, modifiedAtom.key.hashValue)
        XCTAssertNotEqual(AnyHashable(modifiedAtom.key), AnyHashable(modifier.key))
        XCTAssertNotEqual(AnyHashable(modifiedAtom.key).hashValue, AnyHashable(modifier.key).hashValue)
        XCTAssertNotEqual(AnyHashable(modifiedAtom.key), AnyHashable(atom.key))
        XCTAssertNotEqual(AnyHashable(modifiedAtom.key).hashValue, AnyHashable(atom.key).hashValue)
    }

    func testShouldNotifyUpdate() {
        let atom = TestValueAtom(value: "test")
        let modifier = SelectModifier<String, Int>(keyPath: \.count)
        let modifiedAtom = ModifiedAtom(atom: atom, modifier: modifier)

        XCTAssertEqual(
            modifiedAtom.shouldNotifyUpdate(newValue: 100, oldValue: 200),
            modifier.shouldNotifyUpdate(newValue: 100, oldValue: 200)
        )
    }
}
