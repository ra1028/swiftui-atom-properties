import Testing

@testable import Atoms

struct OverrideContainerTests {
    @MainActor
    @Test
    func testGetOverride() {
        let atom = TestAtom(value: 0)
        let otherAtom = TestAtom(value: 1)
        var overrideContainer = OverrideContainer()

        #expect(overrideContainer.getOverride(for: atom) == nil)
        #expect(overrideContainer.getOverride(for: otherAtom) == nil)

        overrideContainer.addOverride(for: TestAtom<Int>.self) { _ in
            0
        }

        #expect(overrideContainer.getOverride(for: atom)?.getValue(atom) == 0)
        #expect(overrideContainer.getOverride(for: otherAtom)?.getValue(atom) == 0)

        overrideContainer.addOverride(for: TestAtom<Int>.self) { _ in
            1
        }

        #expect(overrideContainer.getOverride(for: atom)?.getValue(atom) == 1)
        #expect(overrideContainer.getOverride(for: otherAtom)?.getValue(atom) == 1)

        overrideContainer.addOverride(for: atom) { _ in
            2
        }

        #expect(overrideContainer.getOverride(for: atom)?.getValue(atom) == 2)
        #expect(overrideContainer.getOverride(for: otherAtom)?.getValue(atom) == 1)

        overrideContainer.addOverride(for: atom) { _ in
            3
        }

        #expect(overrideContainer.getOverride(for: atom)?.getValue(atom) == 3)
        #expect(overrideContainer.getOverride(for: otherAtom)?.getValue(atom) == 1)

        overrideContainer.addOverride(for: otherAtom) { _ in
            4
        }

        #expect(overrideContainer.getOverride(for: atom)?.getValue(atom) == 3)
        #expect(overrideContainer.getOverride(for: otherAtom)?.getValue(atom) == 4)
    }
}
