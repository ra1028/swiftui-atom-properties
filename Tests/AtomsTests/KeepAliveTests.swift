import XCTest

@testable import Atoms

@MainActor
final class KeepAliveTests: XCTestCase {
    struct TestNormalAtom: ValueAtom, Hashable {
        func value(context: Context) -> Int {
            0
        }
    }

    struct TestKeepAliveAtom: ValueAtom, Hashable, KeepAlive {
        func value(context: Context) -> Int {
            0
        }
    }

    func testShouldKeepAlive() {
        XCTAssertFalse(TestNormalAtom.shouldKeepAlive)
        XCTAssertTrue(TestKeepAliveAtom.shouldKeepAlive)
    }
}
