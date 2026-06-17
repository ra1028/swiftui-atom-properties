import Testing

@testable import Atoms

struct ValueAtomTests {
    @MainActor
    @Test
    func testValue() {
        let atom = TestValueAtom(value: 0)
        let context = AtomTestContext()

        do {
            // Initial value
            let value = context.watch(atom)
            #expect(value == 0)
        }

        do {
            // Override
            context.unwatch(atom)
            context.override(atom) { _ in 1 }

            #expect(context.watch(atom) == 1)
        }
    }

    @MainActor
    @Test
    func testEffect() async {
        let effect = TestEffect()
        let atom = TestValueAtom(value: 0, effect: effect)
        let context = AtomTestContext()

        context.watch(atom)

        #expect(effect.initializedCount == 1)
        #expect(effect.updatedCount == 0)
        #expect(effect.releasedCount == 0)

        context.reset(atom)
        context.reset(atom)
        context.reset(atom)

        #expect(effect.initializedCount == 1)
        #expect(effect.updatedCount == 3)
        #expect(effect.releasedCount == 0)

        context.unwatch(atom)

        #expect(effect.initializedCount == 1)
        #expect(effect.updatedCount == 3)
        #expect(effect.releasedCount == 1)
    }
}
