import XCTest

@testable import Atoms

@MainActor
final class TerminationTests: XCTestCase {
    func testCallAsFunction() {
        var isCalled = false
        let termination = Termination {
            isCalled = true
        }

        XCTAssertFalse(isCalled)
        termination()
        XCTAssertTrue(isCalled)
    }
}
