import XCTest

@testable import Atoms

final class SubscriberTests: XCTestCase {
    @MainActor
    func testKey() {
        let state0 = SubscriberState()
        let state1 = state0
        let state2 = SubscriberState()

        XCTAssertEqual(
            Subscriber(state0).key,
            Subscriber(state0).key
        )
        XCTAssertEqual(
            Subscriber(state0).key,
            Subscriber(state1).key
        )
        XCTAssertNotEqual(
            Subscriber(state0).key,
            Subscriber(state2).key
        )
    }

    @MainActor
    func testSubscribingKeys() {
        var state: SubscriberState? = SubscriberState()
        let subscriber = Subscriber(state!)
        let expected: Set = [
            AtomKey(TestAtom(value: 0)),
            AtomKey(TestAtom(value: 1)),
            AtomKey(TestAtom(value: 2)),
        ]

        subscriber.subscribingKeys = expected

        XCTAssertEqual(state?.subscribingKeys, expected)

        state = nil

        XCTAssertTrue(subscriber.subscribingKeys.isEmpty)
    }

    @MainActor
    func testUnsubscribe() {
        var state: SubscriberState? = SubscriberState()
        let subscriber = Subscriber(state!)
        var isUnsubscribed = false

        subscriber.unsubscribe = { _ in
            isUnsubscribed = true
        }

        state?.unsubscribe?([])

        XCTAssertTrue(isUnsubscribed)

        state = nil
        isUnsubscribed = false
        subscriber.unsubscribe?([])

        XCTAssertFalse(isUnsubscribed)
    }
}
