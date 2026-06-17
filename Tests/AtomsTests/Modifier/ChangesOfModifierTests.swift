import Testing

@testable import Atoms

struct ChangesOfModifierTests {
    @MainActor
    @Test
    func testChangesOf() {
        let atom = TestStateAtom(defaultValue: "")
        let context = AtomTestContext()
        var updatedCount = 0

        context.onUpdate = {
            updatedCount += 1
        }

        #expect(updatedCount == 0)
        #expect(context.watch(atom.changes(of: \.count)) == 0)

        context[atom] = "modified"

        #expect(updatedCount == 1)
        #expect(context.watch(atom.changes(of: \.count)) == 8)
        context[atom] = "modified"

        // Should not be updated with an equivalent value.
        #expect(updatedCount == 1)
    }

    @Test
    func testKey() {
        let modifier0 = ChangesOfModifier<Int, Int>(keyPath: \.byteSwapped)
        let modifier1 = ChangesOfModifier<Int, Int>(keyPath: \.leadingZeroBitCount)

        #expect(modifier0.key == modifier0.key)
        #expect(modifier0.key.hashValue == modifier0.key.hashValue)
        #expect(modifier0.key != modifier1.key)
        #expect(modifier0.key.hashValue != modifier1.key.hashValue)
    }
}
