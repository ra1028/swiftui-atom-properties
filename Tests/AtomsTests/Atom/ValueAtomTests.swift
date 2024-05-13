import XCTest

@testable import Atoms

final class ValueAtomTests: XCTestCase {
    @MainActor
    func testValue() {
        let atom = TestValueAtom(value: 0)
        let context = AtomTestContext()

        do {
            // Initial value
            let value = context.watch(atom)
            XCTAssertEqual(value, 0)
        }

        do {
            // Override
            context.unwatch(atom)
            context.override(atom) { _ in 1 }

            XCTAssertEqual(context.watch(atom), 1)
        }
    }

    @MainActor
    func testEffect() async {
        let effect = TestEffect()
        let atom = TestValueAtom(value: 0, effect: effect)
        let context = AtomTestContext()

        context.watch(atom)

        XCTAssertEqual(effect.initializedCount, 1)
        XCTAssertEqual(effect.updatedCount, 0)
        XCTAssertEqual(effect.releasedCount, 0)

        context.reset(atom)
        context.reset(atom)
        context.reset(atom)

        XCTAssertEqual(effect.initializedCount, 1)
        XCTAssertEqual(effect.updatedCount, 3)
        XCTAssertEqual(effect.releasedCount, 0)

        context.unwatch(atom)

        XCTAssertEqual(effect.initializedCount, 1)
        XCTAssertEqual(effect.updatedCount, 3)
        XCTAssertEqual(effect.releasedCount, 1)
    }
}
