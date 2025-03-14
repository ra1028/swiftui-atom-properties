import XCTest

@testable import Atoms

final class ScopeStateTests: XCTestCase {
    @MainActor
    func testUnregisterOnDeinit() {
        var scopeState: ScopeState? = ScopeState()
        var unregisterCount = 0

        scopeState!.unregister = {
            unregisterCount += 1
        }

        scopeState = nil

        XCTAssertEqual(unregisterCount, 1)
    }
}
