import XCTest

@testable import Atoms

final class SubscriberKeyTests: XCTestCase {
    @MainActor
    func testKeyHashableForSameToken() {
        let token = SubscriberKey.Token()
        let key0 = SubscriberKey(token: token)
        let key1 = SubscriberKey(token: token)

        XCTAssertEqual(key0, key1)
        XCTAssertEqual(key0.hashValue, key1.hashValue)
    }

    @MainActor
    func testKeyHashableForDifferentToken() {
        let token0 = SubscriberKey.Token()
        let token1 = SubscriberKey.Token()
        let key0 = SubscriberKey(token: token0)
        let key1 = SubscriberKey(token: token1)

        XCTAssertNotEqual(key0, key1)
        XCTAssertNotEqual(key0.hashValue, key1.hashValue)
    }
}
