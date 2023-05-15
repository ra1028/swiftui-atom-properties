import XCTest

@testable import Atoms

@MainActor
final class SubscriptionKeyTests: XCTestCase {
    func testKeyHashableForSameToken() {
        let token = SubscriptionKey.Token()
        let key0 = SubscriptionKey(token: token)
        let key1 = SubscriptionKey(token: token)

        XCTAssertEqual(key0, key1)
        XCTAssertEqual(key0.hashValue, key1.hashValue)
    }

    func testKeyHashableForDifferentToken() {
        let token0 = SubscriptionKey.Token()
        let token1 = SubscriptionKey.Token()
        let key0 = SubscriptionKey(token: token0)
        let key1 = SubscriptionKey(token: token1)

        XCTAssertNotEqual(key0, key1)
        XCTAssertNotEqual(key0.hashValue, key1.hashValue)
    }
}
