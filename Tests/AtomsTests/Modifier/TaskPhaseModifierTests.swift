import Combine
import Testing

@testable import Atoms

struct TaskPhaseModifierTests {
    @MainActor
    @Test
    func testPhase() async {
        let atom = TestTaskAtom { 0 }.phase
        let context = AtomTestContext()

        #expect(context.watch(atom) == .suspending)

        await context.wait(for: atom, until: \.isSuccess)

        #expect(context.watch(atom) == .success(0))
    }

    @MainActor
    @Test
    func testRefresh() async {
        let atom = TestTaskAtom { 0 }.phase
        let context = AtomTestContext()

        #expect(context.watch(atom) == .suspending)

        let phase = await context.refresh(atom)
        #expect(phase == .success(0))
        #expect(context.watch(atom) == .success(0))
    }

    @Test
    func testKey() {
        let modifier = TaskPhaseModifier<Int, Never>()

        #expect(modifier.key == modifier.key)
        #expect(modifier.key.hashValue == modifier.key.hashValue)
    }
}
