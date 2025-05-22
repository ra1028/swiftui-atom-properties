import XCTest

@testable import Atoms

final class InitializeEffectTests: XCTestCase {
    @MainActor
    func testEvent() {
        let context = AtomCurrentContext(store: .dummy)
        var performedCount = 0
        let effect = InitializeEffect {
            performedCount += 1
        }

        effect.initializing(context: context)
        XCTAssertEqual(performedCount, 0)

        effect.initialized(context: context)
        XCTAssertEqual(performedCount, 1)

        effect.updated(context: context)
        XCTAssertEqual(performedCount, 1)

        effect.released(context: context)
        XCTAssertEqual(performedCount, 1)
    }
}
