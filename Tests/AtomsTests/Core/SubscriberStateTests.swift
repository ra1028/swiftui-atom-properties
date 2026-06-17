import Testing

@testable import Atoms

struct SubscriberStateTests {
    @MainActor
    @Test
    func testUnsubscribeOnDeinit() {
        var subscriberState: SubscriberState? = SubscriberState()
        var unsubscribedCount = 0

        subscriberState!.unsubscribe = {
            unsubscribedCount += 1
        }

        subscriberState = nil

        #expect(unsubscribedCount == 1)
    }
}
