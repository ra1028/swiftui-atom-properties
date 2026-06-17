import Testing

@testable import Atoms

struct ModifiedAtomTests {
    @MainActor
    @Test
    func testKey() {
        let base = TestAtom(value: 0)
        let modifier = ChangesOfModifier<Int, String>(keyPath: \.description)
        let atom = ModifiedAtom(atom: base, modifier: modifier)

        #expect(atom.key == atom.key)
        #expect(atom.key.hashValue == atom.key.hashValue)
        #expect(AnyHashable(atom.key) != AnyHashable(modifier.key))
        #expect(AnyHashable(atom.key).hashValue != AnyHashable(modifier.key).hashValue)
        #expect(AnyHashable(atom.key) != AnyHashable(base.key))
        #expect(AnyHashable(atom.key).hashValue != AnyHashable(base.key).hashValue)
    }

    @MainActor
    @Test
    func testValue() async {
        let base = TestStateAtom(defaultValue: "test")
        let modifier = ChangesOfModifier<String, Int>(keyPath: \.count)
        let atom = ModifiedAtom(atom: base, modifier: modifier)
        let context = AtomTestContext()

        do {
            // Initial value
            #expect(context.watch(atom) == 4)
        }

        do {
            // Update
            Task {
                context[base] = "testtest"
            }

            await context.waitForUpdate()
            #expect(context.watch(atom) == 8)
        }

        do {
            // Override
            context.unwatch(atom)
            context.override(atom) { _ in
                100
            }

            #expect(context.watch(atom) == 100)
        }
    }
}
