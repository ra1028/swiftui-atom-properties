import XCTest

@testable import Atoms

@MainActor
final class SubscriptionContainerTests: XCTestCase {
    func testUnsubscribeOnDeinit() {
        var container: SubscriptionContainer? = SubscriptionContainer()
        var unsubscribedCount = 0
        let subscription = Subscription(
            location: SourceLocation(fileID: #file, line: #line),
            notifyUpdate: {}
        ) {
            unsubscribedCount += 1
        }
        let atom0 = TestValueAtom(value: 0)
        let atom1 = TestStateAtom(defaultValue: 0)

        container?.wrapper.subscriptions = [
            AtomKey(atom0): subscription,
            AtomKey(atom1): subscription,
        ]

        container = nil

        XCTAssertEqual(unsubscribedCount, 2)
    }

    func testWrapper() {
        let location = SourceLocation(fileID: #file, line: #line)
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
