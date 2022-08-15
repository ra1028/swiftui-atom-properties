import XCTest

@testable import Atoms

@MainActor
final class OverridesTests: XCTestCase {
    func testIndividualOverride() {
        var overrides = Overrides()
        let atom = TestValueAtom(value: 0)

        XCTAssertNil(overrides.value(for: atom))

        overrides.insert(atom) { _ in 100 }

        XCTAssertEqual(overrides.value(for: atom), 100)
    }

    func testTypeOverride() {
        var overrides = Overrides()
        let atom = TestValueAtom(value: 0)

        XCTAssertNil(overrides.value(for: atom))

        overrides.insert(type(of: atom)) { _ in 200 }

        XCTAssertEqual(overrides.value(for: atom), 200)

        overrides.insert(atom) { _ in 100 }

        // Individual override should take precedence.
        XCTAssertEqual(overrides.value(for: atom), 100)
    }
}
