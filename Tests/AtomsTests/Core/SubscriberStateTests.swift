import XCTest

@testable import Atoms

final class SubscriberStateTests: XCTestCase {
    @MainActor
    func testUnsubscribeOnDeinit() {
        var subscriberState: SubscriberState? = SubscriberState()
        var unsubscribedCount = 0

        subscriberState!.unsubscribe = {
            unsubscribedCount += 1
        }

        subscriberState = nil

        XCTAssertEqual(unsubscribedCount, 1)
    }
}
