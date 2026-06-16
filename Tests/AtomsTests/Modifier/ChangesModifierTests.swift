import Testing

@testable import Atoms

struct ChangesModifierTests {
    @MainActor
    @Test
    func testChanges() {
        let atom = TestStateAtom(defaultValue: "")
        let context = AtomTestContext()
        var updatedCount = 0

        context.onUpdate = {
            updatedCount += 1
        }

        #expect(updatedCount == 0)
        #expect(context.watch(atom.changes) == "")

        context[atom] = "modified"

        #expect(updatedCount == 1)
        #expect(context.watch(atom.changes) == "modified")

        context[atom] = "modified"

        // Should not be updated with an equivalent value.
        #expect(updatedCount == 1)
    }

    @MainActor
    @Test
    func testKey() {
        let modifier = ChangesModifier<Int>()

        #expect(modifier.key == modifier.key)
        #expect(modifier.key.hashValue == modifier.key.hashValue)
    }
}
