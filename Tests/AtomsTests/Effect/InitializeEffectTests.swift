import XCTest

@testable import Atoms

final class InitializeTests: XCTestCase {
    @MainActor
    func testEvent() {
        let context = AtomCurrentContext(store: .dummy)
        var performedCount = 0
        let effect = InitializeEffect {
            performedCount += 1
        }

        effect.initialized(context: context)
        XCTAssertEqual(performedCount, 1)

        effect.updated(context: context)
        XCTAssertEqual(performedCount, 1)

        effect.released(context: context)
        XCTAssertEqual(performedCount, 1)
    }
}
