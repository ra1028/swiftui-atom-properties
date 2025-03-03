import XCTest

@testable import Atoms

final class SubscriberKeyTests: XCTestCase {
    @MainActor
    func testKeyHashableForSameToken() {
        let token = SubscriberKey.Token()

        XCTAssertEqual(token.key, token.key)
        XCTAssertEqual(token.key.hashValue, token.key.hashValue)
    }

    @MainActor
    func testKeyHashableForDifferentToken() {
        let token0 = SubscriberKey.Token()
        let token1 = SubscriberKey.Token()

        XCTAssertNotEqual(token0.key, token1.key)
        XCTAssertNotEqual(token0.key.hashValue, token1.key.hashValue)
    }
}
