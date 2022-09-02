import XCTest

@testable import Atoms

@MainActor
final class SubscriptionContainerTests: XCTestCase {
    func testUnsubscribeOnDeinit() {
        var container: SubscriptionContainer? = SubscriptionContainer()
        var unsubscribedCount = 0
        let subscription = Subscription(notifyUpdate: {}) {
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
}
