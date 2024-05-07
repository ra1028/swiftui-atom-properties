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
        var state = EffectState()
        let effect = TestEffect(
            onInitialize: { state.initialized += 1 },
            onUpdate: { state.updated += 1 },
            onRelease: { state.released += 1 }
        )
        let atom = TestValueAtom(value: 0, effect: effect)
        let context = AtomTestContext()

        context.watch(atom)

        XCTAssertEqual(
            state,
            EffectState(
                initialized: 1,
                updated: 0,
                released: 0
            )
        )

        context.reset(atom)
        context.reset(atom)
        context.reset(atom)

        XCTAssertEqual(
            state,
            EffectState(
                initialized: 1,
                updated: 3,
                released: 0
            )
        )

        context.unwatch(atom)

        XCTAssertEqual(
            state,
            EffectState(
                initialized: 1,
                updated: 3,
                released: 1
            )
        )
    }
}
