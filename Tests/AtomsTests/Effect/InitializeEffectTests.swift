import Testing

@testable import Atoms

struct InitializeEffectTests {
    @MainActor
    @Test
    func testEvent() {
        let context = AtomCurrentContext(store: .dummy)
        var performedCount = 0
        let effect = InitializeEffect {
            performedCount += 1
        }

        effect.initializing(context: context)
        #expect(performedCount == 0)

        effect.initialized(context: context)
        #expect(performedCount == 1)

        effect.updated(context: context)
        #expect(performedCount == 1)

        effect.released(context: context)
        #expect(performedCount == 1)
    }
}
