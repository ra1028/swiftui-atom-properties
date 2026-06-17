import Testing

@testable import Atoms

struct AtomContextTests {
    @MainActor
    @Test
    func testSubscript() {
        let atom = TestStateAtom(defaultValue: 0)
        let context: any AtomWatchableContext = AtomTestContext()

        #expect(context.watch(atom) == 0)

        context[atom] = 100

        #expect(context[atom] == 100)
    }
}
