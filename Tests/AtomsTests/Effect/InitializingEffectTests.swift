import XCTest

@testable import Atoms

final class InitializingEffectTests: XCTestCase {
    @MainActor
    func testEvent() {
        let context = AtomCurrentContext(store: .dummy)
        var performedCount = 0
        let effect = InitializingEffect {
            performedCount += 1
        }

        effect.initializing(context: context)
        XCTAssertEqual(performedCount, 1)

        effect.initialized(context: context)
        XCTAssertEqual(performedCount, 1)

        effect.updated(context: context)
        XCTAssertEqual(performedCount, 1)

        effect.released(context: context)
        XCTAssertEqual(performedCount, 1)
    }
}
