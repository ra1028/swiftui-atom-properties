import XCTest

@testable import Atoms

final class OverrideContainerTests: XCTestCase {
    @MainActor
    func testGetOverride() {
        let atom = TestAtom(value: 0)
        let otherAtom = TestAtom(value: 1)
        var overrideContainer = OverrideContainer()

        XCTAssertNil(overrideContainer.getOverride(for: atom))
        XCTAssertNil(overrideContainer.getOverride(for: otherAtom))

        overrideContainer.addOverride(for: TestAtom<Int>.self) { _ in
            0
        }

        XCTAssertEqual(overrideContainer.getOverride(for: atom)?.getValue(atom), 0)
        XCTAssertEqual(overrideContainer.getOverride(for: otherAtom)?.getValue(atom), 0)

        overrideContainer.addOverride(for: TestAtom<Int>.self) { _ in
            1
        }

        XCTAssertEqual(overrideContainer.getOverride(for: atom)?.getValue(atom), 1)
        XCTAssertEqual(overrideContainer.getOverride(for: otherAtom)?.getValue(atom), 1)

        overrideContainer.addOverride(for: atom) { _ in
            2
        }

        XCTAssertEqual(overrideContainer.getOverride(for: atom)?.getValue(atom), 2)
        XCTAssertEqual(overrideContainer.getOverride(for: otherAtom)?.getValue(atom), 1)

        overrideContainer.addOverride(for: atom) { _ in
            3
        }

        XCTAssertEqual(overrideContainer.getOverride(for: atom)?.getValue(atom), 3)
        XCTAssertEqual(overrideContainer.getOverride(for: otherAtom)?.getValue(atom), 1)

        overrideContainer.addOverride(for: otherAtom) { _ in
            4
        }

        XCTAssertEqual(overrideContainer.getOverride(for: atom)?.getValue(atom), 3)
        XCTAssertEqual(overrideContainer.getOverride(for: otherAtom)?.getValue(atom), 4)
    }
}
