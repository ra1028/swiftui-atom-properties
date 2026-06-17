import Testing

@testable import Atoms

struct UpdateEffectTests {
    @MainActor
    @Test
    func testEvent() {
        let context = AtomCurrentContext(store: .dummy)
        var performedCount = 0
        let effect = UpdateEffect {
            performedCount += 1
        }

        effect.initializing(context: context)
        #expect(performedCount == 0)

        effect.initialized(context: context)
        #expect(performedCount == 0)

        effect.updated(context: context)
        #expect(performedCount == 1)

        effect.released(context: context)
        #expect(performedCount == 1)
    }
}
