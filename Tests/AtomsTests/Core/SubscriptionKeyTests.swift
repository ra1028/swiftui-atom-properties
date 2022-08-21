import XCTest

@testable import Atoms

@MainActor
final class SubscriptionKeyTests: XCTestCase {
    func testKeyHashableForSameContainer() {
        let container = SubscriptionContainer()
        let key0 = SubscriptionKey(container)
        let key1 = SubscriptionKey(container)

        XCTAssertEqual(key0, key1)
        XCTAssertEqual(key0.hashValue, key1.hashValue)
    }

    func testKeyHashableForDifferentContainer() {
        let contaienr0 = SubscriptionContainer()
        let contaienr1 = SubscriptionContainer()
        let key0 = SubscriptionKey(contaienr0)
        let key1 = SubscriptionKey(contaienr1)

        XCTAssertNotEqual(key0, key1)
        XCTAssertNotEqual(key0.hashValue, key1.hashValue)
    }
}
