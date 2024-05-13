import XCTest

@testable import Atoms

final class ReleaseEffectTests: XCTestCase {
    @MainActor
    func testEvent() {
        let store = StoreContext()
        let context = AtomEffectContext(store: store)
        var performedCount = 0
        let effect = ReleaseEffect {
            performedCount += 1
        }

        effect.initialized(context: context)
        XCTAssertEqual(performedCount, 0)

        effect.updated(context: context)
        XCTAssertEqual(performedCount, 0)

        effect.released(context: context)
        XCTAssertEqual(performedCount, 1)
    }
}
