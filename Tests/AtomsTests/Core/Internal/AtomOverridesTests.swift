import XCTest

@testable import Atoms

@MainActor
final class AtomOverridesTests: XCTestCase {
    func testIndividualOverride() {
        var overrides = AtomOverrides()
        let atom = TestValueAtom(value: 0)

        XCTAssertNil(overrides[atom])

        overrides.insert(atom) { _ in 100 }

        XCTAssertEqual(overrides[atom], 100)
    }

    func testTypeOverride() {
        var overrides = AtomOverrides()
        let atom = TestValueAtom(value: 0)

        XCTAssertNil(overrides[atom])

        overrides.insert(type(of: atom)) { _ in 200 }

        XCTAssertEqual(overrides[atom], 200)

        overrides.insert(atom) { _ in 100 }

        // Individual override should take precedence.
        XCTAssertEqual(overrides[atom], 100)
    }
}
