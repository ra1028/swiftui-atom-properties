import XCTest

@testable import Atoms

final class SubscriptionContainerTests: XCTestCase {
    @MainActor
    func testUnsubscribeOnDeinit() {
        var container: SubscriptionContainer? = SubscriptionContainer()
        var unsubscribedCount = 0

        container?.wrapper.unsubscribe = { _ in
            unsubscribedCount += 1
        }

        container = nil

        XCTAssertEqual(unsubscribedCount, 1)
    }

    @MainActor
    func testWrapper() {
        let location = SourceLocation()
        let container0 = SubscriptionContainer()
        let container1 = container0
        let container2 = SubscriptionContainer()

        XCTAssertEqual(
            container0.wrapper(location: location).key,
            container0.wrapper(location: location).key
        )
        XCTAssertEqual(
            container0.wrapper(location: location).key,
            container1.wrapper(location: location).key
        )
        XCTAssertNotEqual(
            container0.wrapper(location: location).key,
            container2.wrapper(location: location).key
        )
        XCTAssertEqual(
            container0.wrapper(location: location).location,
            container0.wrapper(location: location).location
        )
        XCTAssertEqual(
            container0.wrapper(location: location).location,
            container1.wrapper(location: location).location
        )
        XCTAssertEqual(
            container0.wrapper(location: location).location,
            container2.wrapper(location: location).location
        )
    }
}
