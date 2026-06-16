import Testing

@testable import Atoms

struct StateAtomTests {
    @MainActor
    @Test
    func testValue() {
        let atom = TestStateAtom(defaultValue: 0)
        let context = AtomTestContext()

        do {
            // Value
            #expect(context.watch(atom) == 0)
        }

        do {
            // Override
            context.unwatch(atom)
            context.override(atom) { _ in 200 }

            #expect(context.watch(atom) == 200)
        }
    }

    @MainActor
    @Test
    func testSet() {
        let atom = TestStateAtom(defaultValue: 0)
        let context = AtomTestContext()

        #expect(context.watch(atom) == 0)

        context[atom] = 100

        #expect(context.watch(atom) == 100)
    }

    @MainActor
    @Test
    func testSetOverride() {
        let atom = TestStateAtom(defaultValue: 0)
        let context = AtomTestContext()

        context.override(atom) { _ in 200 }

        #expect(context.watch(atom) == 200)

        context[atom] = 100

        #expect(context.watch(atom) == 100)
    }

    @MainActor
    @Test
    func testDependency() async {
        struct Dependency1Atom: StateAtom, Hashable {
            func defaultValue(context: Context) -> Int {
                0
            }
        }

        struct TestAtom: StateAtom, Hashable {
            func defaultValue(context: Context) -> Int {
                context.watch(Dependency1Atom())
            }
        }

        let context = AtomTestContext()

        let value0 = context.watch(TestAtom())
        #expect(value0 == 0)

        context[TestAtom()] = 1

        let value1 = context.watch(TestAtom())
        #expect(value1 == 1)

        // Updated by the depenency update.

        Task {
            context[Dependency1Atom()] = 0
        }

        await context.waitForUpdate()

        let value2 = context.watch(TestAtom())
        #expect(value2 == 0)
    }

    @MainActor
    @Test
    func testEffect() {
        let effect = TestEffect()
        let atom = TestStateAtom(defaultValue: 0, effect: effect)
        let context = AtomTestContext()

        context.watch(atom)

        #expect(effect.initializedCount == 1)
        #expect(effect.updatedCount == 0)
        #expect(effect.releasedCount == 0)

        context.set(1, for: atom)
        context.set(2, for: atom)
        context.set(3, for: atom)

        #expect(effect.initializedCount == 1)
        #expect(effect.updatedCount == 3)
        #expect(effect.releasedCount == 0)

        context.unwatch(atom)

        #expect(effect.initializedCount == 1)
        #expect(effect.updatedCount == 3)
        #expect(effect.releasedCount == 1)
    }
}
