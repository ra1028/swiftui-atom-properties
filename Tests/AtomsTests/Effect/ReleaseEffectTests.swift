import Testing

@testable import Atoms

struct ReleaseEffectTests {
    @MainActor
    @Test
    func testEvent() {
        let context = AtomCurrentContext(store: .dummy)
        var performedCount = 0
        let effect = ReleaseEffect {
            performedCount += 1
        }

        effect.initializing(context: context)
        #expect(performedCount == 0)

        effect.initialized(context: context)
        #expect(performedCount == 0)

        effect.updated(context: context)
        #expect(performedCount == 0)

        effect.released(context: context)
        #expect(performedCount == 1)
    }
}
