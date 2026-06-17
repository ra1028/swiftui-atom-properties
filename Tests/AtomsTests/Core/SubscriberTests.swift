import Testing

@testable import Atoms

struct SubscriberTests {
    @MainActor
    @Test
    func testKey() {
        let state0 = SubscriberState()
        let state1 = state0
        let state2 = SubscriberState()

        #expect(Subscriber(state0).key == Subscriber(state0).key)
        #expect(Subscriber(state0).key == Subscriber(state1).key)
        #expect(Subscriber(state0).key != Subscriber(state2).key)
    }

    @MainActor
    @Test
    func testUnsubscribe() {
        var state: SubscriberState? = SubscriberState()
        let subscriber = Subscriber(state!)
        var isUnsubscribed = false

        subscriber.unsubscribe = {
            isUnsubscribed = true
        }

        state?.unsubscribe?()

        #expect(isUnsubscribed)

        state = nil
        isUnsubscribed = false
        subscriber.unsubscribe?()

        #expect(!(isUnsubscribed))
    }
}
