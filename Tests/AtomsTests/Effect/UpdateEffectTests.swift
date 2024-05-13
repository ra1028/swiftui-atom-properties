import XCTest

@testable import Atoms

final class UpdateEffectTests: XCTestCase {
    @MainActor
    func testEvent() {
        let store = StoreContext()
        let context = AtomEffectContext(store: store)
        var performedCount = 0
        let effect = UpdateEffect {
            performedCount += 1
        }

        effect.initialized(context: context)
        XCTAssertEqual(performedCount, 0)

        effect.updated(context: context)
        XCTAssertEqual(performedCount, 1)

        effect.released(context: context)
        XCTAssertEqual(performedCount, 1)
    }
}
