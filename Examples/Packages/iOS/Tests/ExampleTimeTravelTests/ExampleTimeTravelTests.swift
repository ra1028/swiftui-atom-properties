import Atoms
import Testing

@testable import ExampleTimeTravel

struct ExampleTimeTravelTests {
    @MainActor
    @Test
    func testTextAtom() {
        let context = AtomTestContext()
        let atom = InputStateAtom()

        #expect(context.watch(atom) == InputState())

        context[atom].text = "modified"
        context[atom].latestInput = 1

        #expect(context.watch(atom) == InputState(text: "modified", latestInput: 1))
    }
}
