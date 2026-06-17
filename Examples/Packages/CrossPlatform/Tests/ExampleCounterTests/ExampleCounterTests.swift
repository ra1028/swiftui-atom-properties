import Atoms
import Testing

@testable import ExampleCounter

struct ExampleCounterTests {
    @MainActor
    @Test
    func testCounterAtom() {
        let context = AtomTestContext()
        let atom = CounterAtom()

        #expect(context.watch(atom) == 0)

        context[atom] = 1

        #expect(context.watch(atom) == 1)
    }
}
