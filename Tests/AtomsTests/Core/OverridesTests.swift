import XCTest

@testable import Atoms

@MainActor
final class OverridesTests: XCTestCase {
    func testIndividualOverride() {
        var overrides = Overrides()
        let atom = TestValueAtom(value: 0)
        let key = AtomKey(atom)

        XCTAssertNil(overrides.value(atom, for: key))

        overrides.insert(atom) { _ in 100 }

        XCTAssertEqual(overrides.value(atom, for: key), 100)
    }

    func testTypeOverride() {
        var overrides = Overrides()
        let atom = TestValueAtom(value: 0)
        let key = AtomKey(atom)

        XCTAssertNil(overrides.value(atom, for: key))

        overrides.insert(type(of: atom)) { _ in 200 }

        XCTAssertEqual(overrides.value(atom, for: key), 200)

        overrides.insert(atom) { _ in 100 }

        // Individual override should take precedence.
        XCTAssertEqual(overrides.value(atom, for: key), 100)
    }
}
